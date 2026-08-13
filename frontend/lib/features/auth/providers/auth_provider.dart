import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final String? userId;
  final String? role;

  AuthState({this.isLoading = false, this.error, this.userId, this.role});

  AuthState copyWith({bool? isLoading, String? error, String? userId, String? role}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient = ApiClient();

  AuthNotifier() : super(AuthState()) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null) {
        final userId = await SecureStorage.getUserId();
        final role = await SecureStorage.getRole();
        state = AuthState(userId: userId, role: role);
      }
    } catch (_) {
      // Gracefully handle missing plugins in test environments
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true, userId: state.userId, role: state.role);
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      await SecureStorage.saveTokens(
        token: data['token'],
        refreshToken: data['refreshToken'],
        userId: data['id'],
        role: data['role'],
      );

      state = AuthState(isLoading: false, userId: data['id'], role: data['role']);
      return true;
    } catch (e) {
      String errorMessage = 'Invalid username or password';
      if (e is DioException) {
        final errStr = e.error?.toString() ?? '';
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            errStr.contains('Connection refused') ||
            errStr.contains('XMLHttpRequest') ||
            errStr.contains('Network is unreachable') ||
            e.response == null) {
          errorMessage = 'Cannot connect to server. Please check if the backend server is running.';
        } else if (e.response != null) {
          final data = e.response?.data;
          if (data is Map && data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (e.response?.statusCode == 401) {
            errorMessage = 'Invalid username or password';
          } else {
            errorMessage = 'Server error (${e.response?.statusCode}). Please try again later.';
          }
        }
      } else {
        errorMessage = 'An error occurred: ${e.toString()}';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.dio.post('/auth/register', data: data);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed. Email might be in use.');
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.dio.post(
        '/auth/verify-email',
        queryParameters: {'email': email, 'code': code},
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String msg = 'Verification failed. Please check the code and try again.';
      if (e is DioException && e.response?.data is Map && (e.response?.data as Map).containsKey('message')) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> resendCode(String email) async {
    try {
      await _apiClient.dio.post(
        '/auth/resend-code',
        queryParameters: {'email': email},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendForgotPasswordCode(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.dio.post(
        '/auth/forgot-password',
        queryParameters: {'email': email},
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String msg = 'Failed to send password reset code. User may not exist.';
      if (e is DioException && e.response?.data is Map && (e.response?.data as Map).containsKey('message')) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> resetPasswordWithCode(String email, String code, String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.dio.post(
        '/auth/reset-password',
        queryParameters: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String msg = 'Failed to reset password. Please check the code and try again.';
      if (e is DioException && e.response?.data is Map && (e.response?.data as Map).containsKey('message')) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
