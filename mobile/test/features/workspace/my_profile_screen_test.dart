import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/features/auth/auth_models.dart';
import 'package:relvio/features/auth/auth_session_controller.dart';
import 'package:relvio/features/workspace/my_profile_screen.dart';

class _FakeAuthSessionController extends AuthSessionController {
  _FakeAuthSessionController(this._user);
  final PublicUser _user;

  @override
  AuthSessionState build() => AuthSessionState.authenticated(_user);
}

PublicUser _user({
  String phone = '',
  DateTime? lastLogin,
  String status = 'ACTIVE',
}) => PublicUser(
  id: 'user-1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: 'ada@example.com',
  phone: phone.isEmpty ? null : phone,
  status: status,
  lastLogin: lastLogin,
  createdAt: DateTime.utc(2024, 1, 12),
  updatedAt: DateTime.utc(2024, 1, 12),
);

Future<GoRouter> _pumpMyProfileScreen(WidgetTester tester, {required PublicUser user}) async {
  final router = GoRouter(
    initialLocation: '/workspace',
    routes: [
      GoRoute(path: '/workspace', builder: (context, state) => const Scaffold(body: Text('Workspace Screen'))),
      GoRoute(path: '/workspace/profile', builder: (context, state) => const MyProfileScreen()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authSessionControllerProvider.overrideWith(() => _FakeAuthSessionController(user))],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  router.push('/workspace/profile');
  await tester.pumpAndSettle();

  return router;
}

void main() {
  testWidgets('renders the real name, email, status, and member-since date', (tester) async {
    await _pumpMyProfileScreen(tester, user: _user());

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('Jan 12, 2024'), findsOneWidget);
  });

  testWidgets('renders phone when present', (tester) async {
    await _pumpMyProfileScreen(tester, user: _user(phone: '+1 234 567 8901'));

    expect(find.text('+1 234 567 8901'), findsOneWidget);
  });

  testWidgets('omits the phone row entirely when phone is absent — never fabricated', (tester) async {
    await _pumpMyProfileScreen(tester, user: _user());

    expect(find.text('Phone'), findsNothing);
  });

  testWidgets('renders Last Login when present and omits it when absent', (tester) async {
    await _pumpMyProfileScreen(tester, user: _user(lastLogin: DateTime.utc(2026, 7, 1)));
    expect(find.text('Last Login'), findsOneWidget);
    expect(find.text('Jul 1, 2026'), findsOneWidget);
  });

  testWidgets('omits Last Login entirely when absent — never fabricated', (tester) async {
    await _pumpMyProfileScreen(tester, user: _user());

    expect(find.text('Last Login'), findsNothing);
  });

  testWidgets('never renders Edit Profile, Change Password, 2FA, Sessions, or notification preferences', (
    tester,
  ) async {
    await _pumpMyProfileScreen(tester, user: _user());

    expect(find.text('Edit Profile'), findsNothing);
    expect(find.text('Change Password'), findsNothing);
    expect(find.textContaining('2FA'), findsNothing);
    expect(find.textContaining('Session'), findsNothing);
    expect(find.textContaining('Notification Preferences'), findsNothing);
    expect(find.textContaining('Recent Activity'), findsNothing);
    expect(find.textContaining('IP Address'), findsNothing);
  });

  testWidgets('the back button returns to Workspace', (tester) async {
    final router = await _pumpMyProfileScreen(tester, user: _user());

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/workspace');
    expect(find.text('Workspace Screen'), findsOneWidget);
  });
}
