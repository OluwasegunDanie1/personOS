import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/features/organizations/edit_organization_screen.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';

typedef _UpdateHandler = Future<void> Function(String organizationId, String name);

const _role = OrganizationRole(id: 'r1', name: 'Owner');

OrganizationContextActive _activeContext({String id = 'org-1', String name = 'Hope Community Church'}) =>
    OrganizationContextActive(
      organizations: [OrganizationSummary(id: id, name: name, logoUrl: null, role: _role)],
      selectedOrganizationId: id,
    );

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController(this._initial, {required this.updateHandler});

  final OrganizationContextState _initial;
  final _UpdateHandler updateHandler;
  int updateCallCount = 0;
  int restoreCallCount = 0;
  String? receivedOrganizationId;
  String? receivedName;

  @override
  OrganizationContextState build() => _initial;

  @override
  Future<void> restore() async {
    restoreCallCount++;
  }

  @override
  Future<void> updateOrganizationName({required String organizationId, required String name}) async {
    updateCallCount++;
    receivedOrganizationId = organizationId;
    receivedName = name;
    await updateHandler(organizationId, name);

    final current = state;
    if (current is OrganizationContextActive) {
      state = OrganizationContextActive(
        organizations: current.organizations
            .map((o) => o.id == organizationId ? OrganizationSummary(id: o.id, name: name, logoUrl: o.logoUrl, role: o.role) : o)
            .toList(),
        selectedOrganizationId: current.selectedOrganizationId,
      );
    }
  }

  void emit(OrganizationContextState next) => state = next;
}

class _Harness {
  _Harness(this.controller);
  final _FakeOrganizationContextController controller;
}

Future<_Harness> _pumpEditOrganizationScreen(
  WidgetTester tester, {
  required _UpdateHandler updateHandler,
  OrganizationContextState? initial,
  bool settle = true,
}) async {
  final controller = _FakeOrganizationContextController(initial ?? _activeContext(), updateHandler: updateHandler);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [organizationContextControllerProvider.overrideWith(() => controller)],
      child: const MaterialApp(home: EditOrganizationScreen()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  return _Harness(controller);
}

void main() {
  testWidgets('hydrates the field with the real active organization name', (tester) async {
    await _pumpEditOrganizationScreen(tester, updateHandler: (id, name) async {});

    final field = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Enter organization name'));
    expect(field.controller!.text, 'Hope Community Church');
  });

  testWidgets('Save is disabled when the name is unchanged, and no request is sent', (tester) async {
    final harness = await _pumpEditOrganizationScreen(tester, updateHandler: (id, name) async {});

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    expect(harness.controller.updateCallCount, 0);
  });

  testWidgets('changing the name enables Save and submits only the changed value', (tester) async {
    final harness = await _pumpEditOrganizationScreen(tester, updateHandler: (id, name) async {});

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Renamed Church');
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(harness.controller.updateCallCount, 1);
    expect(harness.controller.receivedOrganizationId, 'org-1');
    expect(harness.controller.receivedName, 'Renamed Church');
    expect(find.text('Saved.'), findsOneWidget);
  });

  testWidgets('blocks a duplicate submission while the request is in flight', (tester) async {
    final gate = Completer<void>();
    final harness = await _pumpEditOrganizationScreen(tester, updateHandler: (id, name) => gate.future);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Renamed Church');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(harness.controller.updateCallCount, 1);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows a truthful error and preserves entered text on failure', (tester) async {
    await _pumpEditOrganizationScreen(
      tester,
      updateHandler: (id, name) async => throw Exception('network down'),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Renamed Church');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not update the organization name. Please try again.'), findsOneWidget);
    final field = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Enter organization name'));
    expect(field.controller!.text, 'Renamed Church');
  });

  testWidgets('a further edit after a successful save clears the stale "Saved." confirmation', (tester) async {
    await _pumpEditOrganizationScreen(tester, updateHandler: (id, name) async {});

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Renamed Church');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Renamed Church Again');
    await tester.pump();

    expect(find.text('Saved.'), findsNothing);
  });

  testWidgets('refuses to submit and reports a truthful message if the active organization changed', (
    tester,
  ) async {
    final harness = await _pumpEditOrganizationScreen(tester, updateHandler: (id, name) async {});

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Renamed Church');
    await tester.pump();

    // Simulate the user switching to a different organization elsewhere
    // before this pending edit is submitted.
    harness.controller.emit(_activeContext(id: 'org-2', name: 'Other Org'));
    await tester.pump();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(harness.controller.updateCallCount, 0);
    expect(find.text('Your active organization changed. Please try again.'), findsOneWidget);
  });

  testWidgets('shows a real loading indicator — never a silently-empty form — while organization context restores', (
    tester,
  ) async {
    await _pumpEditOrganizationScreen(
      tester,
      updateHandler: (id, name) async {},
      initial: const OrganizationContextRestoring(),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('shows a truthful error state (with retry) — never a silently-empty form — on organization context failure', (
    tester,
  ) async {
    final harness = await _pumpEditOrganizationScreen(
      tester,
      updateHandler: (id, name) async {},
      initial: const OrganizationContextFailure('network error'),
    );

    expect(find.text('Could not load your organization.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
    await tester.pump();

    expect(harness.controller.restoreCallCount, 1);
  });

  testWidgets('shows a truthful unavailable state — never a silently-empty form — when there is no active organization', (
    tester,
  ) async {
    await _pumpEditOrganizationScreen(
      tester,
      updateHandler: (id, name) async {},
      initial: const OrganizationContextEmpty(),
    );

    expect(find.text('No active organization is available right now.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
