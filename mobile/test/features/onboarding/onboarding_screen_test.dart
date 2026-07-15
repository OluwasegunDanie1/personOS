import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/features/onboarding/onboarding_screen.dart';

Future<GoRouter> _pumpOnboardingScreen(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/create-account', builder: (context, state) => const Scaffold(body: Text('Create Account Screen'))),
      GoRoute(path: '/sign-in', builder: (context, state) => const Scaffold(body: Text('Sign In Screen'))),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();

  return router;
}

AssetImage _currentPanelAsset(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image)).image as AssetImage);

Future<void> _tapContinue(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the carousel has exactly 4 panels', (tester) async {
    await _pumpOnboardingScreen(tester);

    final delegate = tester.widget<PageView>(find.byType(PageView)).childrenDelegate;
    expect((delegate as SliverChildBuilderDelegate).childCount, 4);
  });

  testWidgets('renders panel 1 with the frozen copy, illustration, and Skip/Continue', (tester) async {
    await _pumpOnboardingScreen(tester);

    expect(find.text('Organize everything in one place.'), findsOneWidget);
    expect(
      find.text(
        'Manage people, events, attendance, communication, and follow-ups from one beautifully organized platform.',
      ),
      findsOneWidget,
    );
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    expect(_currentPanelAsset(tester).assetName, 'assets/brand/Onboarding1.png');
  });

  testWidgets('Continue advances through panels 2 and 3 with the frozen copy, assets, and page dots', (
    tester,
  ) async {
    await _pumpOnboardingScreen(tester);

    await _tapContinue(tester);

    expect(find.text('Build stronger relationships.'), findsOneWidget);
    expect(
      find.text('Track every interaction, follow-up, and journey so no person is ever forgotten.'),
      findsOneWidget,
    );
    expect(_currentPanelAsset(tester).assetName, 'assets/brand/onboading2.png');

    await _tapContinue(tester);

    expect(find.text('Built for every organization.'), findsOneWidget);
    expect(_currentPanelAsset(tester).assetName, 'assets/brand/Onboarding3.png');
    // Panel 3's action is "Get Started", not "Continue".
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('swiping back from panel 2 returns to panel 1', (tester) async {
    await _pumpOnboardingScreen(tester);

    await _tapContinue(tester);
    expect(find.text('Build stronger relationships.'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Organize everything in one place.'), findsOneWidget);
  });

  testWidgets('"Get Started" on panel 3 advances to the frozen panel 4, in the same carousel', (tester) async {
    await _pumpOnboardingScreen(tester);

    await _tapContinue(tester);
    await _tapContinue(tester);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text("Let's get started."), findsOneWidget);
  });

  testWidgets('Skip on any informational panel jumps directly to panel 4', (tester) async {
    await _pumpOnboardingScreen(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text("Let's get started."), findsOneWidget);
  });

  testWidgets('panel 4 renders the frozen relvio_mark.png, copy, and composition — no Skip or page dots', (
    tester,
  ) async {
    await _pumpOnboardingScreen(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text("Let's get started."), findsOneWidget);
    expect(find.text("Choose how you'd like to begin using Relvio."), findsOneWidget);
    expect(_currentPanelAsset(tester).assetName, 'assets/brand/relvio_mark.png');
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Get Started'), findsNothing);

    expect(find.text('Create an Organization'), findsOneWidget);
    expect(find.text('Already a member? Sign In'), findsOneWidget);
    // No approved Invitation/join-workflow backend authority exists.
    expect(find.text('Join Your Organization'), findsNothing);
  });

  testWidgets('panel 4\'s "Create an Organization" routes to the real Create Account screen', (tester) async {
    final router = await _pumpOnboardingScreen(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an Organization'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/create-account');
  });

  testWidgets('panel 4\'s "Already a member? Sign In" routes to the real Sign In screen', (tester) async {
    final router = await _pumpOnboardingScreen(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Already a member? Sign In'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/sign-in');
  });

  testWidgets(
    'each informational panel centers its illustration/copy as one block, not top-aligned (Product Task 090)',
    (tester) async {
      await _pumpOnboardingScreen(tester);

      expect(find.byKey(const Key('onboardingPageCenteredContent')), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Organize everything in one place.'),
          matching: find.byKey(const Key('onboardingPageCenteredContent')),
        ),
        findsOneWidget,
      );

      await _tapContinue(tester);
      expect(
        find.ancestor(
          of: find.text('Build stronger relationships.'),
          matching: find.byKey(const Key('onboardingPageCenteredContent')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('panel 4 centers the logo/heading/copy/actions as one coherent hero block (Product Task 090)', (
    tester,
  ) async {
    await _pumpOnboardingScreen(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    final centeredContent = find.byKey(const Key('getStartedPageCenteredContent'));
    expect(centeredContent, findsOneWidget);
    expect(find.descendant(of: centeredContent, matching: find.text("Let's get started.")), findsOneWidget);
    expect(find.descendant(of: centeredContent, matching: find.text('Create an Organization')), findsOneWidget);
    expect(
      find.descendant(of: centeredContent, matching: find.text('Already a member? Sign In')),
      findsOneWidget,
    );
  });
}
