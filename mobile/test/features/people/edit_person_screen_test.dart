import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/app/routing/primary_navigation_shell.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/edit_person_screen.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/person_profile_screen.dart';

typedef _DetailHandler = Future<PersonDetail> Function({required String organizationId, required String personId});
typedef _UpdateHandler =
    Future<PersonSummary> Function({
      required String organizationId,
      required String personId,
      required FieldUpdate<String> firstName,
      required FieldUpdate<String> lastName,
      required FieldUpdate<String> email,
      required FieldUpdate<String> phone,
      required FieldUpdate<PersonStatus> status,
      required FieldUpdate<PersonGender> gender,
      required FieldUpdate<String> dateOfBirth,
      required FieldUpdate<String> address,
    });

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi({required this.detailHandler, required this.updateHandler}) : super(Dio());

  _DetailHandler detailHandler;
  _UpdateHandler updateHandler;
  int updateCallCount = 0;
  Map<String, FieldUpdate<dynamic>>? lastUpdateArgs;

  @override
  Future<PeoplePage> list({
    required String organizationId,
    String? cursor,
    String? search,
    PersonStatus? status,
    int? limit,
  }) async => const PeoplePage(people: [], nextCursor: null);

  @override
  Future<PersonDetail> detail({required String organizationId, required String personId}) =>
      detailHandler(organizationId: organizationId, personId: personId);

  @override
  Future<PersonJourneyView> journey({required String organizationId, required String personId}) async =>
      const PersonJourneyView(currentStage: null, history: []);

  @override
  Future<List<JourneyStageListEntry>> journeyStages({required String organizationId}) async => const [];

  @override
  Future<AttendanceSummary> attendanceSummary({required String organizationId, required String personId}) async =>
      const AttendanceSummary(totalCount: 0, currentMonthCount: 0);

  @override
  Future<FollowUpListResult> personFollowUps({required String organizationId, required String personId}) async =>
      const FollowUpListResult(followUps: [], nextCursor: null);

  @override
  Future<PersonSummary> update({
    required String organizationId,
    required String personId,
    FieldUpdate<String> firstName = const FieldUpdate.omit(),
    FieldUpdate<String> lastName = const FieldUpdate.omit(),
    FieldUpdate<String> email = const FieldUpdate.omit(),
    FieldUpdate<String> phone = const FieldUpdate.omit(),
    FieldUpdate<PersonStatus> status = const FieldUpdate.omit(),
    FieldUpdate<PersonGender> gender = const FieldUpdate.omit(),
    FieldUpdate<String> dateOfBirth = const FieldUpdate.omit(),
    FieldUpdate<String> address = const FieldUpdate.omit(),
  }) {
    updateCallCount++;
    lastUpdateArgs = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'status': status,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'address': address,
    };
    return updateHandler(
      organizationId: organizationId,
      personId: personId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      status: status,
      gender: gender,
      dateOfBirth: dateOfBirth,
      address: address,
    );
  }
}

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController(this._state);
  OrganizationContextState _state;
  @override
  OrganizationContextState build() => _state;

  void emit(OrganizationContextState next) {
    _state = next;
    state = next;
  }
}

const _orgA = OrganizationContextActive(
  organizations: [
    OrganizationSummary(id: 'org-1', name: 'org-1', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner')),
  ],
  selectedOrganizationId: 'org-1',
);

const _orgB = OrganizationContextActive(
  organizations: [
    OrganizationSummary(id: 'org-2', name: 'org-2', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner')),
  ],
  selectedOrganizationId: 'org-2',
);

PersonDetail _fullDetail({
  String id = 'p1',
  String firstName = 'Ada',
  String lastName = 'Lovelace',
  String? email = 'ada@example.com',
  String? phone = '+1234567890',
  PersonStatus status = PersonStatus.active,
  PersonGender? gender,
  DateTime? dateOfBirth,
  String? address,
}) => PersonDetail(
  id: id,
  firstName: firstName,
  lastName: lastName,
  email: email,
  phone: phone,
  status: status,
  avatarUrl: null,
  joinedAt: DateTime.utc(2026, 1, 1),
  tags: const [],
  currentJourneyStage: null,
  gender: gender,
  dateOfBirth: dateOfBirth,
  address: address,
);

PersonSummary _summary() => PersonSummary(
  id: 'p1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: 'ada@example.com',
  phone: '+1234567890',
  status: PersonStatus.active,
  avatarUrl: null,
  joinedAt: DateTime.utc(2026, 1, 1),
);

class _Harness {
  _Harness(this.router, this.orgController, this.api);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
  final _ScriptedPeopleApi api;
}

Future<_Harness> _pumpEditPersonScreen(
  WidgetTester tester, {
  required _DetailHandler detailHandler,
  _UpdateHandler? updateHandler,
  OrganizationContextState initialOrg = _orgA,
  bool startFromProfile = false,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = _ScriptedPeopleApi(
    detailHandler: detailHandler,
    updateHandler:
        updateHandler ??
        ({
          required organizationId,
          required personId,
          required firstName,
          required lastName,
          required email,
          required phone,
          required status,
          required gender,
          required dateOfBirth,
          required address,
        }) async => _summary(),
  );
  final orgController = _FakeOrganizationContextController(initialOrg);

  final router = GoRouter(
    initialLocation: '/people',
    routes: [
      GoRoute(
        path: '/people/:personId',
        builder: (context, state) => PersonProfileScreen(personId: state.pathParameters['personId']!),
      ),
      GoRoute(
        path: '/people/:personId/edit',
        builder: (context, state) => EditPersonScreen(personId: state.pathParameters['personId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PrimaryNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/people', builder: (context, state) => const Scaffold(body: Text('People Screen')))],
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        peopleApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  if (startFromProfile) {
    router.push('/people/p1');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit Person'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  } else {
    router.push('/people/p1/edit');
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  return _Harness(router, orgController, api);
}

void main() {
  group('Routing (Product Task 047)', () {
    testWidgets('the Profile Edit Person button enters /people/:personId/edit', (WidgetTester tester) async {
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        startFromProfile: true,
      );

      expect(harness.router.state.uri.toString(), '/people/p1/edit');
      expect(find.text('Edit person.'), findsOneWidget);
    });

    testWidgets('Edit Person route is outside the bottom-navigation shell', (WidgetTester tester) async {
      await _pumpEditPersonScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('back returns to Person Profile', (WidgetTester tester) async {
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        startFromProfile: true,
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(harness.router.state.uri.toString(), '/people/p1');
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('organization switch while Edit Person is open closes the flow to /people', (WidgetTester tester) async {
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
      );

      harness.orgController.emit(_orgB);
      await tester.pumpAndSettle();

      expect(find.text('People Screen'), findsOneWidget);
    });

    testWidgets('a stale Organization A load does not render after switching to Organization B', (
      WidgetTester tester,
    ) async {
      final gate = Completer<PersonDetail>();
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) => gate.future,
        settle: false,
      );

      harness.orgController.emit(_orgB);
      await tester.pumpAndSettle();
      expect(find.text('People Screen'), findsOneWidget);

      gate.complete(_fullDetail());
      await tester.pumpAndSettle();

      expect(find.text('People Screen'), findsOneWidget);
      expect(find.text('Edit person.'), findsNothing);
    });
  });

  group('Form controls (Product Task 047)', () {
    testWidgets('initial values render from loaded Person Detail', (WidgetTester tester) async {
      await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(
          firstName: 'Grace',
          lastName: 'Hopper',
          email: 'grace@example.com',
          phone: '+19998887777',
          gender: PersonGender.female,
          dateOfBirth: DateTime.utc(1990, 12, 9),
          address: '221B Baker Street',
        ),
      );

      expect(find.text('Grace'), findsOneWidget);
      expect(find.text('Hopper'), findsOneWidget);
      expect(find.text('grace@example.com'), findsOneWidget);
      expect(find.text('+19998887777'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Dec 9, 1990'), findsOneWidget);
      expect(find.text('221B Baker Street'), findsOneWidget);
    });

    testWidgets('exactly 8 editable Person fields are exposed; no other Person field/control exists', (
      WidgetTester tester,
    ) async {
      await _pumpEditPersonScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);

      // No avatar/tags/Journey editor, no Person picker, no delete action.
      expect(find.text('Profile Photo'), findsNothing);
      expect(find.text('Upload photo'), findsNothing);
      expect(find.text('Tags'), findsNothing);
      expect(find.text('Journey Stage'), findsNothing);
      expect(find.text('Person'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Delete Person'), findsNothing);
      expect(find.text('Archive'), findsNothing);
    });

    testWidgets('Status offers exactly Active and Inactive', (WidgetTester tester) async {
      await _pumpEditPersonScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

      await tester.tap(find.byKey(const Key('editPersonStatusField')));
      await tester.pumpAndSettle();

      expect(find.text('Active').hitTestable(), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('Gender offers Male, Female, and a truthful Not specified (null) path; no Other', (
      WidgetTester tester,
    ) async {
      await _pumpEditPersonScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

      await tester.tap(find.byKey(const Key('editPersonGenderField')));
      await tester.pumpAndSettle();

      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      // Appears twice: once as the closed field's currently-selected value
      // (gender starts null in this harness) and once as the open menu's
      // own item.
      expect(find.text('Not specified'), findsNWidgets(2));
      expect(find.text('Other'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('a previously-set gender can be cleared back to Not specified', (WidgetTester tester) async {
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(gender: PersonGender.female),
      );

      await tester.tap(find.byKey(const Key('editPersonGenderField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not specified').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(harness.api.lastUpdateArgs!['gender']!.isSet, isTrue);
      expect(harness.api.lastUpdateArgs!['gender']!.value, isNull);
    });

    testWidgets('Date of Birth uses date-only interaction; no time picker appears', (WidgetTester tester) async {
      await _pumpEditPersonScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

      await tester.tap(find.byKey(const Key('editPersonDateOfBirthField')));
      await tester.pumpAndSettle();

      // A real Material date picker is showing (has an OK/Cancel pair).
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // No time-picker artifact ("Select time" dialog title) ever appears.
      expect(find.text('Select time'), findsNothing);
    });

    testWidgets('an existing Date of Birth can be cleared', (WidgetTester tester) async {
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async =>
            _fullDetail(dateOfBirth: DateTime.utc(1990, 12, 9)),
      );

      expect(find.byKey(const Key('editPersonClearDateOfBirthField')), findsOneWidget);
      await tester.tap(find.byKey(const Key('editPersonClearDateOfBirthField')));
      await tester.pumpAndSettle();

      expect(find.text('Select date'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(harness.api.lastUpdateArgs!['dateOfBirth']!.isSet, isTrue);
      expect(harness.api.lastUpdateArgs!['dateOfBirth']!.value, isNull);
    });

    testWidgets('nullable Email/Phone/Address text fields can be cleared', (WidgetTester tester) async {
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(address: '221B Baker Street'),
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter email address'), '');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter phone number'), '');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter address'), '');

      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      final args = harness.api.lastUpdateArgs!;
      expect(args['email']!.isSet, isTrue);
      expect(args['email']!.value, isNull);
      expect(args['phone']!.isSet, isTrue);
      expect(args['phone']!.value, isNull);
      expect(args['address']!.isSet, isTrue);
      expect(args['address']!.value, isNull);
    });

    testWidgets('an unchanged form shows a truthful no-change result and never calls PATCH', (WidgetTester tester) async {
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(harness.api.updateCallCount, 0);
      expect(find.text('No changes to save.'), findsOneWidget);
      // Still on the Edit screen — no fake success navigation occurred.
      expect(find.text('Edit person.'), findsOneWidget);
    });

    testWidgets('submitting blocks duplicate Save while one is in flight', (WidgetTester tester) async {
      final gate = Completer<PersonSummary>();
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        updateHandler:
            ({
              required organizationId,
              required personId,
              required firstName,
              required lastName,
              required email,
              required phone,
              required status,
              required gender,
              required dateOfBirth,
              required address,
            }) => gate.future,
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Updated');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // The button itself becomes disabled and shows a loading spinner while
      // submitting — the "Save Changes" text is replaced, so a second tap on
      // the same button cannot fire a second submit through the UI at all.
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      gate.complete(_summary());
      await tester.pumpAndSettle();

      expect(harness.api.updateCallCount, 1);
    });

    testWidgets('a submit failure preserves entered values and shows a truthful error', (WidgetTester tester) async {
      await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        updateHandler:
            ({
              required organizationId,
              required personId,
              required firstName,
              required lastName,
              required email,
              required phone,
              required status,
              required gender,
              required dateOfBirth,
              required address,
            }) async => throw Exception('network down'),
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Still-Entered-Value');
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Still-Entered-Value'), findsOneWidget, reason: 'entered form values must survive a submit failure');
      expect(find.text('Edit person.'), findsOneWidget, reason: 'must remain on the Edit screen, not navigate away');
    });

    testWidgets('a load error state supports retry', (WidgetTester tester) async {
      var shouldFail = true;
      await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async {
          if (shouldFail) throw Exception('boom');
          return _fullDetail();
        },
      );

      expect(find.text('Could not load this person.'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Edit person.'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
    });

    testWidgets('a real successful save returns to Person Profile', (WidgetTester tester) async {
      final harness = await _pumpEditPersonScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        startFromProfile: true,
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Updated');
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(harness.router.state.uri.toString(), '/people/p1');
    });
  });
}
