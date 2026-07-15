import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_ready_screen.dart';
import 'package:relvio/features/organizations/organization_setup_screen.dart';

typedef _CreateHandler = Future<void> Function(String name, {String? industry, String? country, String? timezone});

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController({required this.createHandler});

  final _CreateHandler createHandler;
  int createCallCount = 0;
  String? receivedName;
  String? receivedIndustry;
  String? receivedCountry;
  String? receivedTimezone;

  @override
  OrganizationContextState build() => const OrganizationContextEmpty();

  @override
  Future<void> createOrganization(String name, {String? industry, String? country, String? timezone}) {
    createCallCount++;
    receivedName = name;
    receivedIndustry = industry;
    receivedCountry = country;
    receivedTimezone = timezone;
    return createHandler(name, industry: industry, country: country, timezone: timezone);
  }
}

class _Harness {
  _Harness(this.router, this.controller);
  final GoRouter router;
  final _FakeOrganizationContextController controller;
}

Future<_Harness> _pumpOrganizationSetupScreen(WidgetTester tester, {required _CreateHandler createHandler}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
    final harness = await _pumpOrganizationSetupScreen(
      tester,
      createHandler: (name, {industry, country, timezone}) async {},
    );

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

  testWidgets('renders the frozen composition: Logo area, Name, Type, Country, and Time Zone', (tester) async {
    await _pumpOrganizationSetupScreen(tester, createHandler: (name, {industry, country, timezone}) async {});

    expect(find.text('Organization Logo'), findsOneWidget);
    expect(find.text('Logo upload coming soon'), findsOneWidget);
    expect(find.text('Organization Name'), findsOneWidget);
    expect(find.text('Organization Type'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Time Zone'), findsOneWidget);
  });

  testWidgets('Organization Type and Country are plain text fields, not dropdowns or pickers', (tester) async {
    await _pumpOrganizationSetupScreen(tester, createHandler: (name, {industry, country, timezone}) async {});

    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.widgetWithText(TextFormField, 'e.g. Church, School, Business, NGO'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Enter your country'), findsOneWidget);
  });

  testWidgets('Time Zone is pre-filled with the real device UTC offset and remains editable', (tester) async {
    await _pumpOrganizationSetupScreen(tester, createHandler: (name, {industry, country, timezone}) async {});

    final field = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'UTC offset'));
    expect(field.controller!.text, autoDetectedUtcOffset());
    expect(find.text('Automatically detected from your device. You can edit it if needed.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'UTC offset'), 'UTC+05:00');
    expect(field.controller!.text, 'UTC+05:00');
  });

  testWidgets('"Skip for now" is not present on the Organization Setup screen', (tester) async {
    await _pumpOrganizationSetupScreen(tester, createHandler: (name, {industry, country, timezone}) async {});

    expect(find.text('Skip for now'), findsNothing);
    expect(find.textContaining('Skip'), findsNothing);
  });

  testWidgets('Continue sends the entered Organization Type, Country, and Time Zone', (tester) async {
    final harness = await _pumpOrganizationSetupScreen(
      tester,
      createHandler: (name, {industry, country, timezone}) async {},
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Church, School, Business, NGO'), 'Church');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your country'), 'Nigeria');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(harness.controller.receivedName, 'Hope Community Church');
    expect(harness.controller.receivedIndustry, 'Church');
    expect(harness.controller.receivedCountry, 'Nigeria');
    expect(harness.controller.receivedTimezone, autoDetectedUtcOffset());
  });

  testWidgets('Organization Type and Country may be left blank', (tester) async {
    final harness = await _pumpOrganizationSetupScreen(
      tester,
      createHandler: (name, {industry, country, timezone}) async {},
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(harness.controller.createCallCount, 1);
    expect(harness.controller.receivedIndustry, '');
    expect(harness.controller.receivedCountry, '');
  });

  testWidgets('the Ready screen shows the real Ready.png illustration and only a "Go to Dashboard" action', (
    tester,
  ) async {
    await _pumpOrganizationSetupScreen(tester, createHandler: (name, {industry, country, timezone}) async {});

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
    final harness = await _pumpOrganizationSetupScreen(
      tester,
      createHandler: (name, {industry, country, timezone}) async {},
    );

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
    final harness = await _pumpOrganizationSetupScreen(
      tester,
      createHandler: (name, {industry, country, timezone}) => gate.future,
    );

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
      createHandler: (name, {industry, country, timezone}) async => throw Exception('network error'),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Could not create the organization. Please try again.'), findsOneWidget);
    expect(harness.router.state.uri.toString(), '/organization-setup');
  });
}
