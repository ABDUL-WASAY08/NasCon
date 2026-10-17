import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/fixture.dart';
import '../../models/product.dart';
import '../../models/session.dart';
import '../../models/standings_row.dart';
import '../../models/user.dart';
import '../network/api_client.dart';

/// Typed facade for the Express starter API.
///
/// Pass the app's configured [ApiClient] so base URL, secure bearer token
/// injection, timeout handling, and redacted logging remain centralized.
class ApiService {
  const ApiService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<Session> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    return Session.fromJson(response);
  }

  Future<Session> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return Session.fromJson(response);
  }

  Future<Session> loginWithGoogle({required String idToken}) async {
    final response = await _client.post(
      '/auth/google',
      body: {'id_token': idToken},
    );
    return Session.fromJson(response);
  }

  Future<User> profile() async {
    final response = await _client.getObject('/user/profile');
    return User.fromJson(_userMap(response));
  }

  Future<User> uploadAvatar({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    final response = await _client.postMultipart(
      '/user/upload-avatar',
      formData: FormData.fromMap({
        'avatar': MultipartFile.fromBytes(imageBytes, filename: filename),
      }),
    );
    return User.fromJson(_userMap(response));
  }

  Future<List<Fixture>> fixtures({String? leagueId, String? status}) async {
    final rows = await _client.getList(
      '/fixtures',
      query: {'league_id': ?leagueId, 'status': ?status},
    );
    return rows.map(Fixture.fromJson).toList(growable: false);
  }

  Future<List<StandingsRow>> standings() async {
    final rows = await _client.getList('/standings');
    return rows.map(StandingsRow.fromJson).toList(growable: false);
  }

  Future<List<Product>> products({String? category, String? query}) async {
    final rows = await _client.getList(
      '/store/products',
      query: {'category': ?category, 'q': ?query},
    );
    return rows.map(Product.fromJson).toList(growable: false);
  }

  Map<String, dynamic> _userMap(Map<String, dynamic> response) {
    final user = response['user'];
    if (user is Map) return user.cast<String, dynamic>();
    return response;
  }
}
