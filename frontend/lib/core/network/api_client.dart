import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';

  static Future<void> saveTokens({
    required String? token,
    required String? refreshToken,
    required String? userId,
    required String? role,
  }) async {
    try {
      final t = token ?? '';
      final rt = refreshToken ?? '';
      final uid = userId ?? '';
      final r = role ?? '';

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, t);
        await prefs.setString(_refreshKey, rt);
        await prefs.setString(_userIdKey, uid);
        await prefs.setString(_userRoleKey, r);
      } else {
        await _storage.write(key: _tokenKey, value: t);
        await _storage.write(key: _refreshKey, value: rt);
        await _storage.write(key: _userIdKey, value: uid);
        await _storage.write(key: _userRoleKey, value: r);
      }
    } catch (e) {
      debugPrint('SecureStorage.saveTokens error: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        return (token != null && token.isNotEmpty) ? token : null;
      }
      final token = await _storage.read(key: _tokenKey);
      return (token != null && token.isNotEmpty) ? token : null;
    } catch (e) {
      debugPrint('SecureStorage.getToken error: $e');
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_refreshKey);
        return (token != null && token.isNotEmpty) ? token : null;
      }
      final token = await _storage.read(key: _refreshKey);
      return (token != null && token.isNotEmpty) ? token : null;
    } catch (e) {
      debugPrint('SecureStorage.getRefreshToken error: $e');
      return null;
    }
  }

  static Future<String?> getUserId() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_userIdKey);
      }
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('SecureStorage.getUserId error: $e');
      return null;
    }
  }

  static Future<String?> getRole() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_userRoleKey);
      }
      return await _storage.read(key: _userRoleKey);
    } catch (e) {
      debugPrint('SecureStorage.getRole error: $e');
      return null;
    }
  }

  static Future<void> clearAll() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        await prefs.remove(_refreshKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_userRoleKey);
      } else {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _refreshKey);
        await _storage.delete(key: _userIdKey);
        await _storage.delete(key: _userRoleKey);
      }
    } catch (e) {
      debugPrint('SecureStorage.clearAll error: $e');
    }
  }
}

class ApiClient {
  late final Dio dio;
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    return 'http://10.0.2.2:8080/api';
  }

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final path = e.requestOptions.path;
        final isAuthEndpoint = path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/refresh');

        if (e.response?.statusCode == 401 && !isAuthEndpoint) {
          final refreshToken = await SecureStorage.getRefreshToken();
          if (refreshToken != null) {
            try {
              // Attempt refreshing token
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final response = await refreshDio.post('/auth/refresh', data: {
                'refreshToken': refreshToken,
              });

              final newAccessToken = response.data['accessToken'];
              final newRefreshToken = response.data['refreshToken'];
              final userId = await SecureStorage.getUserId() ?? '';
              final role = await SecureStorage.getRole() ?? '';

              await SecureStorage.saveTokens(
                token: newAccessToken,
                refreshToken: newRefreshToken,
                userId: userId,
                role: role,
              );

              // Retry failed request
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (err) {
              await SecureStorage.clearAll();
            }
          }
        }
        return handler.next(e);
      },
    ));
  }
}
