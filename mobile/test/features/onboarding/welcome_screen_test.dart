import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/features/onboarding/welcome_screen.dart';

Future<GoRouter> _pumpWelcomeScreen(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/create-account', builder: (context, state) => const Scaffold(body: Text('Create Account Screen'))),
      GoRoute(path: '/sign-in', builder: (context, state) => const Scaffold(body: Text('Sign In Screen'))),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();

  return router;
}

void main() {
  testWidgets('renders the frozen Welcome to Relvio composition', (tester) async {
    await _pumpWelcomeScreen(tester);

    // The heading is a RichText composed of two spans ("Welcome to " +
    // "Relvio"); find.text flattens RichText's plain text for matching.
    expect(find.text('Welcome to Relvio'), findsOneWidget);
    expect(find.text('Build stronger relationships.'), findsOneWidget);
    expect(
      find.text('Manage people, events, attendance, and communication from one intelligent platform.'),
      findsOneWidget,
    );
    expect(find.text('Create an Organization'), findsOneWidget);
    expect(find.text('Already a member? Sign In'), findsOneWidget);
  });

  testWidgets('never renders a Join Your Organization action — no approved invitation authority exists', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    expect(find.text('Join Your Organization'), findsNothing);
  });

  testWidgets('"Create an Organization" routes to the real Create Account screen', (tester) async {
    final router = await _pumpWelcomeScreen(tester);

    await tester.tap(find.text('Create an Organization'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/create-account');
  });

  testWidgets('"Already a member? Sign In" routes to the real Sign In screen', (tester) async {
    final router = await _pumpWelcomeScreen(tester);

    await tester.tap(find.text('Already a member? Sign In'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/sign-in');
  });
}
