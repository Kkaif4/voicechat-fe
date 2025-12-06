import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<User> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final token = response.data['token'];
      final userJson = response.data['user'];

      await _storage.write(key: AppConstants.tokenKey, value: token);
      return User.fromJson(userJson);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  Future<User> register(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {'username': username, 'password': password},
      );
      // Assuming register autologins or returns user id, adapting to BRD which says it returns Message + UserId.
      // So we might need to login after register or if the API returns token on register usually.
      // BRD says: Response: { "message": "User registered", "userId": "..." }
      // So let's just return a placeholder User or throw success.
      return User(id: response.data['userId'], username: username);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
