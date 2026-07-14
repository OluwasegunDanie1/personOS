import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_ready_screen.dart';
import 'package:relvio/features/organizations/organization_setup_screen.dart';

typedef _CreateHandler = Future<void> Function(String name);

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController({required this.createHandler});

  final _CreateHandler createHandler;
  int createCallCount = 0;
  String? receivedName;

  @override
  OrganizationContextState build() => const OrganizationContextEmpty();

  @override
  Future<void> createOrganization(String name) {
    createCallCount++;
    receivedName = name;
    return createHandler(name);
  }
}

class _Harness {
  _Harness(this.router, this.controller);
  final GoRouter router;
  final _FakeOrganizationContextController controller;
}

Future<_Harness> _pumpOrganizationSetupScreen(WidgetTester tester, {required _CreateHandler createHandler}) async {
  final controller = _FakeOrganizationContextController(createHandler: createHandler);

  final router = GoRouter(
    initialLocation: '/organization-setup',
    routes: [
      GoRoute(path: '/organization-setup', builder: (context, state) => const OrganizationSetupScreen()),
      GoRoute(path: '/organization-ready', builder: (context, state) => const OrganizationReadyScreen()),
      GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('Home Screen'))),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [organizationContextControllerProvider.overrideWith(() => controller)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(router, controller);
}

void main() {
  testWidgets('a successful organization creation navigates to the Ready screen, not straight to the dashboard', (
    tester,
  ) async {
    final harness = await _pumpOrganizationSetupScreen(tester, createHandler: (name) async {});

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(harness.controller.createCallCount, 1);
    expect(harness.controller.receivedName, 'Hope Community Church');
    expect(harness.router.state.uri.toString(), '/organization-ready');
    expect(find.text('Your organization is ready!'), findsOneWidget);
    // No premature dashboard redirect: the Home stub is never shown at this point.
    expect(find.text('Home Screen'), findsNothing);
  });

  testWidgets('the Ready screen shows the real Ready.png illustration and only a "Go to Dashboard" action', (
    tester,
  ) async {
    await _pumpOrganizationSetupScreen(tester, createHandler: (name) async {});

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/brand/Ready.png');
    expect(find.text('Go to Dashboard'), findsOneWidget);
    // No approved Invite-Members endpoint exists — the frozen panel's second
    // action is truthfully omitted.
    expect(find.text('Invite More Members'), findsNothing);
  });

  testWidgets('"Go to Dashboard" on the Ready screen continues to Home', (tester) async {
    final harness = await _pumpOrganizationSetupScreen(tester, createHandler: (name) async {});

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to Dashboard'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/home');
    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('blocks a duplicate organization submission while the request is in flight', (tester) async {
    final gate = Completer<void>();
    final harness = await _pumpOrganizationSetupScreen(tester, createHandler: (name) => gate.future);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(harness.controller.createCallCount, 1);

    gate.complete();
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/organization-ready');
  });

  testWidgets('a creation failure shows a truthful error and stays on the setup form', (tester) async {
    final harness = await _pumpOrganizationSetupScreen(
      tester,
      createHandler: (name) async => throw Exception('network error'),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Could not create the organization. Please try again.'), findsOneWidget);
    expect(harness.router.state.uri.toString(), '/organization-setup');
  });
}
