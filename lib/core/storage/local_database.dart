import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/cart_item.dart';
import '../../models/sync_queue_entry.dart';

/// Creates the persistent store for the current platform.
///
/// sqflite has no web or desktop implementation, so anything other than
/// Android/iOS falls back to an in-memory store rather than crashing at
/// startup. On those targets the cart and offline queue are session-scoped —
/// acceptable for previews, never for a real offline workflow.
LocalDatabase createPlatformLocalDatabase() {
  const mobile = {TargetPlatform.android, TargetPlatform.iOS};
  if (!kIsWeb && mobile.contains(defaultTargetPlatform)) {
    return SqfliteLocalDatabase();
  }
  if (kDebugMode) {
    debugPrint(
      '[storage] sqflite is unavailable on this target — using an in-memory '
      'store. Offline queue and cart will not persist across restarts.',
    );
  }
  return MemoryLocalDatabase();
}

/// A cached payload plus the time it was stored, so the UI can flag staleness.
@immutable
class CachedPayload {
  const CachedPayload({required this.payload, required this.updatedAt});

  final String payload;
  final DateTime updatedAt;

  Map<String, dynamic>? decodeObject() {
    final decoded = jsonDecode(payload);
    return decoded is Map ? decoded.cast<String, dynamic>() : null;
  }

  static List<Map<String, dynamic>> decodeList(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}

/// Persistent local store: read caches, the cart and the offline action queue.
///
/// Implementations must guarantee that queued actions survive a force-close.
abstract class LocalDatabase {
  static const String cartBucket = 'cart';
  static const String cartKey = 'items';

  static const String fixturesBucket = 'fixtures';
  static const String standingsBucket = 'standings';
  static const String clubsBucket = 'clubs';
  static const String productsBucket = 'products';

  Future<void> open();
  Future<void> close();

  // --- generic cache ---------------------------------------------------------
  Future<void> putCache(
    String bucket,
    String key,
    String payload, {
    DateTime? updatedAt,
  });

  Future<CachedPayload?> getCache(String bucket, String key);

  Future<void> deleteCache(String bucket, String key);

  // --- cart ------------------------------------------------------------------
  Future<void> saveCart(List<CartItem> items) => putCache(
    cartBucket,
    cartKey,
    jsonEncode(items.map((item) => item.toJson()).toList()),
  );

  Future<List<CartItem>> loadCart() async {
    final cached = await getCache(cartBucket, cartKey);
    if (cached == null) return const [];
    return CachedPayload.decodeList(
      cached.payload,
    ).map(CartItem.fromJson).toList();
  }

  // --- offline queue ---------------------------------------------------------
  Future<void> enqueue(SyncQueueEntry entry);

  Future<void> updateQueueEntry(SyncQueueEntry entry);

  Future<void> deleteQueueEntry(String id);

  Future<SyncQueueEntry?> findQueueEntry(String id);

  /// Oldest-first, so actions are replayed in the order they were created.
  Future<List<SyncQueueEntry>> queueEntries();

  Future<int> queueCountByState();

  // --- lifecycle -------------------------------------------------------------
  Future<void> clearAll();
}

/// Non-persistent implementation used by tests and previews.
///
/// It holds state for the lifetime of the instance, which lets a test simulate
/// a process restart by rebuilding repositories over the same instance.
class MemoryLocalDatabase extends LocalDatabase {
  final Map<String, CachedPayload> _cache = {};
  final Map<String, SyncQueueEntry> _queue = {};
  bool _open = false;

  @override
  Future<void> open() async => _open = true;

  @override
  Future<void> close() async => _open = false;

  bool get isOpen => _open;

  @override
  Future<void> putCache(
    String bucket,
    String key,
    String payload, {
    DateTime? updatedAt,
  }) async {
    _cache['$bucket::$key'] = CachedPayload(
      payload: payload,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  Future<CachedPayload?> getCache(String bucket, String key) async =>
      _cache['$bucket::$key'];

  @override
  Future<void> deleteCache(String bucket, String key) async {
    _cache.remove('$bucket::$key');
  }

  @override
  Future<void> enqueue(SyncQueueEntry entry) async => _queue[entry.id] = entry;

  @override
  Future<void> updateQueueEntry(SyncQueueEntry entry) async =>
      _queue[entry.id] = entry;

  @override
  Future<void> deleteQueueEntry(String id) async => _queue.remove(id);

  @override
  Future<SyncQueueEntry?> findQueueEntry(String id) async => _queue[id];

  @override
  Future<List<SyncQueueEntry>> queueEntries() async {
    final entries = _queue.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  @override
  Future<int> queueCountByState() async => _queue.length;

  @override
  Future<void> clearAll() async {
    _cache.clear();
    _queue.clear();
  }
}

/// SQLite-backed implementation for production use.
class SqfliteLocalDatabase extends LocalDatabase {
  SqfliteLocalDatabase({String? path, DatabaseFactory? factory})
    : _path = path,
      _factory = factory ?? databaseFactory;

  static const int _schemaVersion = 1;
  static const String _fileName = 'nascon.db';

  final String? _path;
  final DatabaseFactory _factory;
  Database? _db;

  @override
  Future<void> open() async {
    if (_db != null) return;
    final path = _path ?? p.join(await _factory.getDatabasesPath(), _fileName);
    _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cache (
              bucket TEXT NOT NULL,
              key TEXT NOT NULL,
              payload TEXT NOT NULL,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (bucket, key)
            )
          ''');
          await db.execute('''
            CREATE TABLE sync_queue (
              id TEXT PRIMARY KEY,
              action_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              state TEXT NOT NULL,
              attempts INTEGER NOT NULL DEFAULT 0,
              last_error TEXT,
              base_version TEXT,
              updated_at INTEGER,
              server_result TEXT
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_sync_state ON sync_queue(state, created_at)',
          );
        },
      ),
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('LocalDatabase.open() must be awaited before use');
    }
    return db;
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<void> putCache(
    String bucket,
    String key,
    String payload, {
    DateTime? updatedAt,
  }) async {
    await _database.insert('cache', {
      'bucket': bucket,
      'key': key,
      'payload': payload,
      'updated_at': (updatedAt ?? DateTime.now()).toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<CachedPayload?> getCache(String bucket, String key) async {
    final rows = await _database.query(
      'cache',
      where: 'bucket = ? AND key = ?',
      whereArgs: [bucket, key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return CachedPayload(
      payload: row['payload'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as int?) ?? 0,
        isUtc: true,
      ).toLocal(),
    );
  }

  @override
  Future<void> deleteCache(String bucket, String key) async {
    await _database.delete(
      'cache',
      where: 'bucket = ? AND key = ?',
      whereArgs: [bucket, key],
    );
  }

  @override
  Future<void> enqueue(SyncQueueEntry entry) async {
    await _database.insert(
      'sync_queue',
      entry.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateQueueEntry(SyncQueueEntry entry) async {
    await _database.update(
      'sync_queue',
      entry.toRow(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<void> deleteQueueEntry(String id) async {
    await _database.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<SyncQueueEntry?> findQueueEntry(String id) async {
    final rows = await _database.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SyncQueueEntry.fromRow(rows.first);
  }

  @override
  Future<List<SyncQueueEntry>> queueEntries() async {
    final rows = await _database.query('sync_queue', orderBy: 'created_at ASC');
    return rows.map(SyncQueueEntry.fromRow).toList();
  }

  @override
  Future<int> queueCountByState() async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) AS c FROM sync_queue',
    );
    return (result.first['c'] as int?) ?? 0;
  }

  @override
  Future<void> clearAll() async {
    await _database.delete('cache');
    await _database.delete('sync_queue');
  }
}
