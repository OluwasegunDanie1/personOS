import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import '../../core/api/auth_interceptor.dart';
import 'auth_models.dart';

/// Integrates the real, implemented auth boundary (Product Task 072/074):
/// POST /auth/login, POST /auth/refresh (used internally by
/// AuthInterceptor), POST /auth/logout, POST /auth/register, POST
/// /auth/forgot-password, POST /auth/reset-password. Does not call GET
/// /auth/me — no screen in this app currently needs it (session identity
/// is sourced entirely from Login's own response, per
/// AuthSessionController's established convention).
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

  /// Creates exactly one ACTIVE User. Never returns tokens (Register does
  /// not auto-login) and never touches organization state — the caller
  /// must navigate to Sign In afterward.
  Future<PublicUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<dynamic>(
      '/auth/register',
      data: {'firstName': firstName, 'lastName': lastName, 'email': email, 'password': password},
      options: Options(extra: {skipAuthExtraKey: true}),
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return PublicUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Always returns the same non-disclosing message regardless of whether
  /// the email resolves to a real account. developmentResetToken is only
  /// ever present outside production — this method never assumes it exists.
  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    final response = await _dio.post<dynamic>(
      '/auth/forgot-password',
      data: {'email': email},
      options: Options(extra: {skipAuthExtraKey: true}),
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return ForgotPasswordResult(
      message: data['message'] as String,
      developmentResetToken: data['developmentResetToken'] as String?,
    );
  }

  /// Never returns tokens (Reset Password does not auto-login) — the
  /// caller must navigate to Sign In afterward, mirroring Register.
  Future<void> resetPassword({required String token, required String newPassword}) async {
    final response = await _dio.post<dynamic>(
      '/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
      options: Options(extra: {skipAuthExtraKey: true}),
    );

    unwrapEnvelope(response);
  }
}
