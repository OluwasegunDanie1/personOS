import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import '../../core/api/auth_interceptor.dart';
import 'auth_models.dart';

/// Integrates the actual implemented boundary only: POST /auth/login,
/// POST /auth/refresh (used internally by AuthInterceptor), POST
/// /auth/logout. Does not call GET /auth/me or GET /users/me (unresolved).
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<LoginResult> login({required String email, required String password}) async {
    final response = await _dio.post<dynamic>(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: Options(extra: {skipAuthExtraKey: true}),
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;

    return LoginResult(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: PublicUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> logout(String refreshToken) async {
    final response = await _dio.post<dynamic>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {skipAuthExtraKey: true}),
    );

    unwrapEnvelope(response);
  }
}
