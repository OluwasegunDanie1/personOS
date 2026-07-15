import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/app/widgets/relvio_back_button.dart';
import 'package:relvio/core/api/api_exceptions.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/auth/auth_api.dart';
import 'package:relvio/features/auth/auth_models.dart';
import 'package:relvio/features/auth/auth_session_controller.dart';
import 'package:relvio/features/auth/create_account_screen.dart';
import 'package:relvio/features/auth/sign_in_screen.dart';

typedef _RegisterHandler =
    Future<PublicUser> Function({
      required String firstName,
      required String lastName,
      required String email,
      required String password,
    });

class _ScriptedAuthApi extends AuthApi {
  _ScriptedAuthApi({required this.registerHandler}) : super(Dio());

  _RegisterHandler registerHandler;
  int registerCallCount = 0;
  List<String> receivedEmails = [];

  @override
  Future<PublicUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    registerCallCount++;
    receivedEmails.add(email);
    return registerHandler(firstName: firstName, lastName: lastName, email: email, password: password);
  }
}

class _FakeAuthSessionController extends AuthSessionController {
  int loginCallCount = 0;

  @override
  AuthSessionState build() => const AuthSessionState.unauthenticated();

  @override
  Future<void> login({required String email, required String password}) async {
    loginCallCount++;
  }
}

PublicUser _fixtureUser({String email = 'ada@example.com'}) => PublicUser(
  id: 'user-1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: email,
  phone: null,
  status: 'ACTIVE',
  lastLogin: null,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

class _Harness {
  _Harness(this.router, this.api, this.authController);
  final GoRouter router;
  final _ScriptedAuthApi api;
  final _FakeAuthSessionController authController;
}

Future<_Harness> _pumpCreateAccountScreen(WidgetTester tester, {required _RegisterHandler registerHandler}) async {
  final api = _ScriptedAuthApi(registerHandler: registerHandler);
  final authController = _FakeAuthSessionController();

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/create-account',
    routes: [
      GoRoute(path: '/create-account', builder: (context, state) => const CreateAccountScreen()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => SignInScreen(successMessage: state.extra as String?),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authApiProvider.overrideWithValue(api),
        authSessionControllerProvider.overrideWith(() => authController),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(router, api, authController);
}

Future<void> _fillValidForm(WidgetTester tester, {String password = 'password123', String? confirmPassword}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
  await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
  await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'ada@example.com');
  await tester.enterText(find.widgetWithText(TextFormField, 'Create a password'), password);
  await tester.enterText(find.widgetWithText(TextFormField, 'Confirm your password'), confirmPassword ?? password);
}

void main() {
  testWidgets('submits the real register request and navigates to Sign In with a truthful success message', (
    tester,
  ) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => _fixtureUser(email: email),
    );

    await _fillValidForm(tester);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(harness.api.registerCallCount, 1);
    expect(harness.api.receivedEmails, ['ada@example.com']);
    expect(harness.router.state.uri.toString(), '/sign-in');
    expect(find.text('Account created. Please sign in.'), findsOneWidget);
  });

  testWidgets('never fabricates a session or auto-login after Register succeeds', (tester) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => _fixtureUser(email: email),
    );

    await _fillValidForm(tester);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // AuthSessionController.login is the only component that ever writes
    // tokens/cached-user/authenticated state — proving it was never called
    // proves Register did not fabricate a session or an organization.
    expect(harness.authController.loginCallCount, 0);
  });

  testWidgets('shows a duplicate-email error and stays on the form without navigating', (tester) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => throw const ApiException(code: 'EMAIL_ALREADY_REGISTERED', message: 'conflict', statusCode: 409),
    );

    await _fillValidForm(tester);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('An account with this email already exists.'), findsOneWidget);
    expect(harness.router.state.uri.toString(), '/create-account');
  });

  testWidgets('shows a truthful rate-limit message for TOO_MANY_REQUESTS, never a generic or fabricated-success message', (
    tester,
  ) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => throw const ApiException(code: 'TOO_MANY_REQUESTS', message: 'throttled', statusCode: 429),
    );

    await _fillValidForm(tester);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Too many attempts. Please wait a few minutes and try again.'), findsOneWidget);
    expect(find.text('Could not create your account. Please try again.'), findsNothing);
    expect(harness.router.state.uri.toString(), '/create-account');
  });

  testWidgets('shows a generic error for any other registration failure', (tester) async {
    await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => throw const ApiException(code: 'VALIDATION_ERROR', message: 'bad request', statusCode: 400),
    );

    await _fillValidForm(tester);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Could not create your account. Please try again.'), findsOneWidget);
  });

  testWidgets('blocks a duplicate submission while the request is in flight', (tester) async {
    final gate = Completer<PublicUser>();
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) => gate.future,
    );

    await _fillValidForm(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    // The button becomes disabled and shows a loading spinner while
    // submitting, so a second tap cannot fire a second submit through the UI.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(harness.api.registerCallCount, 1);

    gate.complete(_fixtureUser());
    await tester.pumpAndSettle();
  });

  testWidgets('surfaces field validation errors instead of submitting', (tester) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => _fixtureUser(email: email),
    );

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(harness.api.registerCallCount, 0);
    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('requires Confirm Password and blocks submission when empty', (tester) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => _fixtureUser(email: email),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'ada@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Create a password'), 'password123');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please confirm your password'), findsOneWidget);
    expect(harness.api.registerCallCount, 0);
  });

  testWidgets('blocks submission and reports a mismatch when Confirm Password differs from Password', (
    tester,
  ) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => _fixtureUser(email: email),
    );

    await _fillValidForm(tester, password: 'password123', confirmPassword: 'different456');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(harness.api.registerCallCount, 0);
  });

  testWidgets('never sends Confirm Password to the API — only firstName/lastName/email/password reach register()', (
    tester,
  ) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => _fixtureUser(email: email),
    );

    // AuthApi.register() has no confirmPassword parameter at all — the fake
    // above only accepts firstName/lastName/email/password, so a successful
    // call through this exact signature is itself proof Confirm Password is
    // never transmitted (Product Task 090).
    await _fillValidForm(tester, password: 'password123', confirmPassword: 'password123');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(harness.api.registerCallCount, 1);
    expect(harness.router.state.uri.toString(), '/sign-in');
  });

  testWidgets('renders no boxed back button at all — the frozen panel shows none (Product Task 090A)', (
    tester,
  ) async {
    await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => _fixtureUser(email: email),
    );

    expect(find.byType(RelvioBackButton), findsNothing);
  });

  testWidgets('the "Already have an account? Sign In" link routes to Sign In', (tester) async {
    final harness = await _pumpCreateAccountScreen(
      tester,
      registerHandler: ({
        required firstName,
        required lastName,
        required email,
        required password,
      }) async => _fixtureUser(email: email),
    );

    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/sign-in');
    // Navigating via the footer link (not a successful registration) must
    // not show a fabricated success banner.
    expect(find.text('Account created. Please sign in.'), findsNothing);
  });
}
