import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/features/auth/auth_session_controller.dart';
import 'package:relvio/features/auth/create_account_screen.dart';
import 'package:relvio/features/auth/forgot_password_screen.dart';
import 'package:relvio/features/auth/sign_in_screen.dart';

class _FakeAuthSessionController extends AuthSessionController {
  @override
  AuthSessionState build() => const AuthSessionState.unauthenticated();
}

Future<GoRouter> _pumpSignInScreen(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/sign-in',
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => SignInScreen(successMessage: state.extra as String?),
      ),
      GoRoute(path: '/create-account', builder: (context, state) => const CreateAccountScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authSessionControllerProvider.overrideWith(_FakeAuthSessionController.new)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return router;
}

void main() {
  testWidgets('shows no success banner when reached with no successMessage', (tester) async {
    await _pumpSignInScreen(tester);

    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });

  testWidgets('the "Forgot Password?" link routes to the real Forgot Password screen', (tester) async {
    final router = await _pumpSignInScreen(tester);

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/forgot-password');
    expect(find.text('Forgot your password?'), findsOneWidget);
  });

  testWidgets('the "Don\'t have an account? Create Account" link routes to the real Create Account screen', (
    tester,
  ) async {
    final router = await _pumpSignInScreen(tester);

    await tester.tap(find.text("Don't have an account? Create Account"));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/create-account');
    expect(find.text('Create your account.'), findsOneWidget);
  });

  testWidgets('shows a truthful success banner after a real Register success is routed in via extra', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/sign-in',
      routes: [
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => SignInScreen(successMessage: state.extra as String?),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionControllerProvider.overrideWith(_FakeAuthSessionController.new)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/sign-in', extra: 'Account created. Please sign in.');
    await tester.pumpAndSettle();

    expect(find.text('Account created. Please sign in.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('shows a truthful success banner after a real Reset Password success is routed in via extra', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/sign-in',
      routes: [
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => SignInScreen(successMessage: state.extra as String?),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionControllerProvider.overrideWith(_FakeAuthSessionController.new)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/sign-in', extra: 'Password reset successful. Please sign in.');
    await tester.pumpAndSettle();

    expect(find.text('Password reset successful. Please sign in.'), findsOneWidget);
  });
}
