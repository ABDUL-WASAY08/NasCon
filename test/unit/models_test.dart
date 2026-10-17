import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/core/errors/app_exception.dart';
import 'package:nescom/core/errors/error_mapper.dart';
import 'package:nescom/models/fixture.dart';
import 'package:nescom/models/product.dart';
import 'package:nescom/models/standings_row.dart';
import 'package:nescom/models/sync_queue_entry.dart';

void main() {
  group('Fixture parsing', () {
    test('parses a complete payload', () {
      final fixture = Fixture.fromJson({
        'id': 'fx_1',
        'home_team': {'id': 'c1', 'name': 'Karachi Falcons', 'short_name': 'KAR'},
        'away_team': {'id': 'c2', 'name': 'Lahore Lions'},
        'kickoff': '2026-03-01T15:00:00Z',
        'status': 'live',
        'home_score': 2,
        'away_score': 1,
      });
      expect(fixture.id, 'fx_1');
      expect(fixture.homeTeam.displayName, 'KAR');
      expect(fixture.status, MatchStatus.live);
      expect(fixture.isLive, isTrue);
      expect(fixture.hasScore, isTrue);
    });

    test('tolerates missing optional fields', () {
      final fixture = Fixture.fromJson(const {});
      expect(fixture.id, '');
      expect(fixture.status, MatchStatus.unknown);
      expect(fixture.hasScore, isFalse);
      expect(fixture.venue, isNull);
    });

    test('never invents a status for an unknown wire value', () {
      final fixture = Fixture.fromJson({
        'id': 'fx',
        'status': 'abandoned_by_aliens',
      });
      expect(fixture.status, MatchStatus.unknown);
    });
  });

  group('StandingsRow parsing', () {
    test('keeps qualification null when absent', () {
      final row = StandingsRow.fromJson({
        'team_id': 't1',
        'team_name': 'Falcons',
        'position': 1,
      });
      expect(row.qualification, isNull);
    });

    test('maps a known qualification', () {
      final row = StandingsRow.fromJson({
        'team_id': 't1',
        'team_name': 'Falcons',
        'position': 1,
        'qualification': 'eliminated',
      });
      expect(row.qualification, QualificationStatus.eliminated);
    });
  });

  group('Product parsing', () {
    test('reads variants and reports stock', () {
      final product = Product.fromJson({
        'id': 'p1',
        'name': 'Home Jersey',
        'price': 4500,
        'variants': [
          {'id': 'v1', 'name': 'Medium', 'stock_quantity': 0},
          {'id': 'v2', 'name': 'Large', 'stock_quantity': 3},
        ],
      });
      expect(product.hasVariants, isTrue);
      expect(product.isInStock, isTrue);
      expect(product.availableQuantity, 3);
    });

    test('a variant-less product with zero stock is out of stock', () {
      final product = Product.fromJson({
        'id': 'p2',
        'name': 'Gloves',
        'price': 2800,
        'stock_quantity': 0,
      });
      expect(product.isInStock, isFalse);
    });
  });

  group('SyncQueueEntry round-trip', () {
    test('survives a row encode/decode with payload intact', () {
      final entry = SyncQueueEntry(
        id: 'a1',
        actionType: SyncActionTypes.scoringEvent,
        entityId: 'fx_03',
        payload: {'type': 'goal', 'points': 1, 'nested': {'a': true}},
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          1700000000000,
          isUtc: true,
        ),
      );

      final restored = SyncQueueEntry.fromRow(entry.toRow());
      expect(restored.id, 'a1');
      expect(restored.state, SyncState.pending);
      expect(restored.payload['points'], 1);
      expect(restored.payload['nested'], {'a': true});
      expect(restored.description, 'Scoring event');
    });

    test('an unknown state falls back to pending, never synced', () {
      final row = SyncQueueEntry(
        id: 'a2',
        actionType: 'x',
        entityId: 'y',
        payload: const {},
        createdAt: DateTime.now(),
      ).toRow();
      row['state'] = 'something_new';
      expect(SyncQueueEntry.fromRow(row).state, SyncState.pending);
    });
  });

  group('ErrorMapper', () {
    test('maps network and timeout errors as retryable', () {
      const network = AppException('x', kind: AppErrorKind.network);
      const timeout = AppException('x', kind: AppErrorKind.timeout);
      expect(ErrorMapper.isRetryable(network), isTrue);
      expect(ErrorMapper.isRetryable(timeout), isTrue);
      expect(ErrorMapper.messageFor(network), ErrorMapper.offlineMessage);
    });

    test('does not retry validation or forbidden errors', () {
      expect(
        ErrorMapper.isRetryable(
          const AppException('x', kind: AppErrorKind.validation),
        ),
        isFalse,
      );
      expect(
        ErrorMapper.isRetryable(
          const AppException('x', kind: AppErrorKind.forbidden),
        ),
        isFalse,
      );
    });

    test('flags an expired session', () {
      expect(
        ErrorMapper.isSessionExpired(
          const AppException('x', kind: AppErrorKind.unauthorized),
        ),
        isTrue,
      );
    });

    test('never leaks a raw exception message', () {
      expect(
        ErrorMapper.messageFor(StateError('internal detail')),
        ErrorMapper.unexpectedMessage,
      );
    });

    test('reports a missing backend contract explicitly', () {
      final error = AppException.pendingContract('sync batch');
      expect(ErrorMapper.kindOf(error), AppErrorKind.pendingContract);
      expect(ErrorMapper.messageFor(error), contains('sync batch'));
    });
  });
}
