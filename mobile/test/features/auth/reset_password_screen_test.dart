import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/api/api_exceptions.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/auth/auth_api.dart';
import 'package:relvio/features/auth/reset_password_screen.dart';
import 'package:relvio/features/auth/sign_in_screen.dart';

typedef _ResetPasswordHandler = Future<void> Function({required String token, required String newPassword});

class _ScriptedAuthApi extends AuthApi {
  _ScriptedAuthApi({required this.resetPasswordHandler}) : super(Dio());

  _ResetPasswordHandler resetPasswordHandler;
  int resetPasswordCallCount = 0;
  String? receivedToken;
  String? receivedPassword;

  @override
  Future<void> resetPassword({required String token, required String newPassword}) {
    resetPasswordCallCount++;
    receivedToken = token;
    receivedPassword = newPassword;
    return resetPasswordHandler(token: token, newPassword: newPassword);
  }
}

class _Harness {
  _Harness(this.router, this.api);
  final GoRouter router;
  final _ScriptedAuthApi api;
}

Future<_Harness> _pumpResetPasswordScreen(
  WidgetTester tester, {
  required _ResetPasswordHandler resetPasswordHandler,
  String? prefilledToken,
}) async {
  final api = _ScriptedAuthApi(resetPasswordHandler: resetPasswordHandler);

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/reset-password',
    routes: [
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(prefilledToken: state.extra as String? ?? prefilledToken),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => SignInScreen(successMessage: state.extra as String?),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authApiProvider.overrideWithValue(api)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(router, api);
}

Future<void> _fillValidForm(WidgetTester tester, {String token = 'reset-token-1', String password = 'newpass123'}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Paste your reset token'), token);
  await tester.enterText(find.widgetWithText(TextFormField, 'Enter a new password'), password);
  await tester.enterText(find.widgetWithText(TextFormField, 'Re-enter your new password'), password);
}

void main() {
  testWidgets('submits the real reset-password request and navigates to Sign In with a truthful success message', (
    tester,
  ) async {
    final harness = await _pumpResetPasswordScreen(tester, resetPasswordHandler: ({required token, required newPassword}) async {});

    await _fillValidForm(tester, token: 'reset-token-1', password: 'newpass123');
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(harness.api.resetPasswordCallCount, 1);
    expect(harness.api.receivedToken, 'reset-token-1');
    expect(harness.api.receivedPassword, 'newpass123');
    expect(harness.router.state.uri.toString(), '/sign-in');
    expect(find.text('Password reset successful. Please sign in.'), findsOneWidget);
  });

  testWidgets('blocks submission and shows a validation error when the passwords do not match', (tester) async {
    final harness = await _pumpResetPasswordScreen(tester, resetPasswordHandler: ({required token, required newPassword}) async {});

    await tester.enterText(find.widgetWithText(TextFormField, 'Paste your reset token'), 'reset-token-1');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter a new password'), 'newpass123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Re-enter your new password'), 'different123');
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(harness.api.resetPasswordCallCount, 0);
  });

  testWidgets('shows one generic message for an invalid, expired, or already-used token — never distinguishing', (
    tester,
  ) async {
    await _pumpResetPasswordScreen(
      tester,
      resetPasswordHandler: ({required token, required newPassword}) async =>
          throw const ApiException(code: 'INVALID_RESET_TOKEN', message: 'invalid', statusCode: 401),
    );

    await _fillValidForm(tester);
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('This reset link is invalid or has expired. Please request a new one.'), findsOneWidget);
  });

  testWidgets('shows a generic failure message for any other error code', (tester) async {
    await _pumpResetPasswordScreen(
      tester,
      resetPasswordHandler: ({required token, required newPassword}) async =>
          throw const ApiException(code: 'VALIDATION_ERROR', message: 'bad request', statusCode: 400),
    );

    await _fillValidForm(tester);
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('Could not reset your password. Please try again.'), findsOneWidget);
  });

  testWidgets('blocks a duplicate submission while the request is in flight', (tester) async {
    final gate = Completer<void>();
    final harness = await _pumpResetPasswordScreen(
      tester,
      resetPasswordHandler: ({required token, required newPassword}) => gate.future,
    );

    await _fillValidForm(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(harness.api.resetPasswordCallCount, 1);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('pre-fills the reset token when reached from the Forgot Password development path', (tester) async {
    await _pumpResetPasswordScreen(
      tester,
      resetPasswordHandler: ({required token, required newPassword}) async {},
      prefilledToken: 'dev-token-abc',
    );

    final tokenField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Paste your reset token'));
    expect(tokenField.controller!.text, 'dev-token-abc');
  });

  testWidgets('the "Back to Sign In" link routes to Sign In without a success message', (tester) async {
    final harness = await _pumpResetPasswordScreen(tester, resetPasswordHandler: ({required token, required newPassword}) async {});

    await tester.tap(find.text('← Back to Sign In'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/sign-in');
    expect(find.text('Password reset successful. Please sign in.'), findsNothing);
  });
}
