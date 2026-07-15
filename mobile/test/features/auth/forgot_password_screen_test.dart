import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/app/widgets/relvio_back_button.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/auth/auth_api.dart';
import 'package:relvio/features/auth/auth_models.dart';
import 'package:relvio/features/auth/forgot_password_screen.dart';
import 'package:relvio/features/auth/reset_password_screen.dart';
import 'package:relvio/features/auth/sign_in_screen.dart';

const _nonDisclosingMessage = 'If an account exists for this email, password reset instructions will be sent.';

typedef _ForgotPasswordHandler = Future<ForgotPasswordResult> Function({required String email});

class _ScriptedAuthApi extends AuthApi {
  _ScriptedAuthApi({required this.forgotPasswordHandler}) : super(Dio());

  _ForgotPasswordHandler forgotPasswordHandler;
  int forgotPasswordCallCount = 0;
  List<String> receivedEmails = [];

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) {
    forgotPasswordCallCount++;
    receivedEmails.add(email);
    return forgotPasswordHandler(email: email);
  }
}

class _Harness {
  _Harness(this.router, this.api);
  final GoRouter router;
  final _ScriptedAuthApi api;
}

Future<_Harness> _pumpForgotPasswordScreen(
  WidgetTester tester, {
  required _ForgotPasswordHandler forgotPasswordHandler,
}) async {
  final api = _ScriptedAuthApi(forgotPasswordHandler: forgotPasswordHandler);

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/forgot-password',
    routes: [
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(prefilledToken: state.extra as String?),
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

void main() {
  testWidgets('submits the real forgot-password request with the entered email', (tester) async {
    final harness = await _pumpForgotPasswordScreen(
      tester,
      forgotPasswordHandler: ({required email}) async =>
          const ForgotPasswordResult(message: _nonDisclosingMessage, developmentResetToken: null),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'known@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(harness.api.forgotPasswordCallCount, 1);
    expect(harness.api.receivedEmails, ['known@example.com']);
  });

  testWidgets('shows the identical non-disclosing success message for a known email', (tester) async {
    await _pumpForgotPasswordScreen(
      tester,
      forgotPasswordHandler: ({required email}) async =>
          const ForgotPasswordResult(message: _nonDisclosingMessage, developmentResetToken: 'dev-token-abc'),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'known@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text(_nonDisclosingMessage), findsOneWidget);
  });

  testWidgets('shows the exact same success message for an unknown email — never distinguishing outcomes', (
    tester,
  ) async {
    await _pumpForgotPasswordScreen(
      tester,
      forgotPasswordHandler: ({required email}) async =>
          const ForgotPasswordResult(message: _nonDisclosingMessage, developmentResetToken: null),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'unknown@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text(_nonDisclosingMessage), findsOneWidget);
    expect(find.text('Send Reset Link'), findsNothing);
  });

  testWidgets('shows a DEVELOPMENT ONLY block with a real path into Reset Password when a dev token is returned', (
    tester,
  ) async {
    final harness = await _pumpForgotPasswordScreen(
      tester,
      forgotPasswordHandler: ({required email}) async =>
          const ForgotPasswordResult(message: _nonDisclosingMessage, developmentResetToken: 'dev-token-abc'),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'known@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('developmentResetTokenBlock')), findsOneWidget);
    expect(find.text('DEVELOPMENT ONLY'), findsOneWidget);

    await tester.tap(find.text('Continue to Reset Password (dev)'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/reset-password');
    expect(find.widgetWithText(TextFormField, 'Paste your reset token'), findsOneWidget);
    final tokenField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Paste your reset token'));
    expect(tokenField.controller!.text, 'dev-token-abc');
  });

  testWidgets('omits the DEVELOPMENT ONLY block for a production-shaped response with no token', (tester) async {
    await _pumpForgotPasswordScreen(
      tester,
      forgotPasswordHandler: ({required email}) async =>
          const ForgotPasswordResult(message: _nonDisclosingMessage, developmentResetToken: null),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'known@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('developmentResetTokenBlock')), findsNothing);
    expect(find.text('DEVELOPMENT ONLY'), findsNothing);
  });

  testWidgets('blocks a duplicate submission while the request is in flight', (tester) async {
    final gate = Completer<ForgotPasswordResult>();
    final harness = await _pumpForgotPasswordScreen(tester, forgotPasswordHandler: ({required email}) => gate.future);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'known@example.com');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(harness.api.forgotPasswordCallCount, 1);

    gate.complete(const ForgotPasswordResult(message: _nonDisclosingMessage, developmentResetToken: null));
    await tester.pumpAndSettle();
  });

  testWidgets('shows a real failure message on a genuine transport/server error', (tester) async {
    await _pumpForgotPasswordScreen(
      tester,
      forgotPasswordHandler: ({required email}) async => throw Exception('network down'),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'known@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Could not process your request. Please try again.'), findsOneWidget);
  });

  testWidgets('the "Back to Sign In" link routes to Sign In', (tester) async {
    final harness = await _pumpForgotPasswordScreen(
      tester,
      forgotPasswordHandler: ({required email}) async =>
          const ForgotPasswordResult(message: _nonDisclosingMessage, developmentResetToken: null),
    );

    await tester.tap(find.text('← Back to Sign In'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/sign-in');
  });

  testWidgets('renders no boxed back button at all — the frozen panel shows none (Product Task 090A)', (
    tester,
  ) async {
    await _pumpForgotPasswordScreen(
      tester,
      forgotPasswordHandler: ({required email}) async =>
          const ForgotPasswordResult(message: _nonDisclosingMessage, developmentResetToken: null),
    );

    expect(find.byType(RelvioBackButton), findsNothing);
  });
}
