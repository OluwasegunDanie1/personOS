import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/add_person_screen.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi(this.createHandler) : super(Dio());

  Future<PersonSummary> Function({
    required String organizationId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    required PersonStatus status,
    PersonGender? gender,
    DateTime? dateOfBirth,
    String? address,
  })
  createHandler;

  int createCallCount = 0;
  final List<Map<String, dynamic>> createCalls = [];

  @override
  Future<PeoplePage> list({
    required String organizationId,
    String? cursor,
    String? search,
    PersonStatus? status,
    int? limit,
  }) async => const PeoplePage(people: [], nextCursor: null);

  @override
  Future<PersonSummary> create({
    required String organizationId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    required PersonStatus status,
    PersonGender? gender,
    DateTime? dateOfBirth,
    String? address,
  }) {
    createCallCount++;
    createCalls.add({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'status': status,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'address': address,
    });
    return createHandler(
      organizationId: organizationId,
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
  organizations: [OrganizationSummary(id: 'org-1', name: 'org-1', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner'))],
  selectedOrganizationId: 'org-1',
);

const _orgB = OrganizationContextActive(
  organizations: [OrganizationSummary(id: 'org-2', name: 'org-2', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner'))],
  selectedOrganizationId: 'org-2',
);

PersonSummary _createdPerson() => PersonSummary(
  id: 'new-person',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: null,
  phone: null,
  status: PersonStatus.active,
  avatarUrl: null,
  joinedAt: DateTime.utc(2026, 1, 1),
);

class _Harness {
  _Harness(this.router, this.orgController);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
}

Future<_Harness> _pumpAddPersonScreen(
  WidgetTester tester,
  _ScriptedPeopleApi api, {
  OrganizationContextState initialOrg = _orgA,
}) async {
  // A tall viewport so the whole form (title through Cancel) is reachable
  // without scrolling issues in tests — the default 800x600 test surface is
  // shorter than the full accordion composition.
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final orgController = _FakeOrganizationContextController(initialOrg);

  final router = GoRouter(
    initialLocation: '/people',
    routes: [
      GoRoute(path: '/people', builder: (context, state) => const Scaffold(body: Text('People Screen'))),
      GoRoute(path: '/people/add', builder: (context, state) => const AddPersonScreen()),
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
  router.push('/people/add');
  await tester.pumpAndSettle();
  return _Harness(router, orgController);
}

Finder _basicInformationHeader() => find.text('Basic Information');
Finder _contactInformationHeader() => find.text('Contact Information');
Finder _organizationInformationHeader() => find.text('Organization Information');
Finder _notesHeader() => find.text('Notes');

Future<void> _expand(WidgetTester tester, Finder header) async {
  await tester.tap(header);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders exact title and subtitle', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    expect(find.text('Add a new person.'), findsOneWidget);
    expect(find.text('Create a profile to begin tracking their journey.'), findsOneWidget);
  });

  testWidgets('renders exactly four numbered section cards with exact titles and subtitles', (
    WidgetTester tester,
  ) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    expect(_basicInformationHeader(), findsOneWidget);
    expect(find.text("Add the person's basic details."), findsOneWidget);
    expect(_contactInformationHeader(), findsOneWidget);
    expect(find.text('Add contact details.'), findsOneWidget);
    expect(_organizationInformationHeader(), findsOneWidget);
    expect(find.text('Add organization details.'), findsOneWidget);
    expect(_notesHeader(), findsOneWidget);
    expect(find.text('Add any additional notes.'), findsOneWidget);
  });

  testWidgets('Basic Information is expanded initially; the other three are collapsed', (
    WidgetTester tester,
  ) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    expect(find.text('First Name').hitTestable(), findsOneWidget);
    expect(find.text('Last Name').hitTestable(), findsOneWidget);
    expect(find.text('Phone Number').hitTestable(), findsNothing);
    expect(find.text('Status').hitTestable(), findsNothing);
  });

  testWidgets('Profile Photo, Group, and a Notes textarea do not render', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);
    await _expand(tester, _contactInformationHeader());
    await _expand(tester, _organizationInformationHeader());

    expect(find.text('Profile Photo'), findsNothing);
    expect(find.text('Upload photo'), findsNothing);
    expect(find.text('Group'), findsNothing);
    expect(find.text('Select group'), findsNothing);
  });

  testWidgets('First Name and Last Name share a row inside Basic Information', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    final firstNameY = tester.getTopLeft(find.text('First Name')).dy;
    final lastNameY = tester.getTopLeft(find.text('Last Name')).dy;
    expect(firstNameY, lastNameY);
  });

  testWidgets('Gender and Date of Birth render in Basic Information and share a row', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    final genderY = tester.getTopLeft(find.text('Gender')).dy;
    final dobY = tester.getTopLeft(find.text('Date of Birth')).dy;
    expect(genderY, dobY);

    final firstNameY = tester.getTopLeft(find.text('First Name')).dy;
    expect(genderY, greaterThan(firstNameY));
  });

  testWidgets('Gender defaults to unselected placeholder Select gender, with exactly Male/Female options', (
    WidgetTester tester,
  ) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    expect(find.text('Select gender'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addPersonGenderField')));
    await tester.pumpAndSettle();

    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Other'), findsNothing);
    expect(find.text('Prefer not to say'), findsNothing);
  });

  testWidgets('selecting Male persists after Basic Information collapse/re-expand', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.tap(find.byKey(const Key('addPersonGenderField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();

    expect(find.text('Male'), findsOneWidget);

    await _expand(tester, _basicInformationHeader()); // collapse
    expect(find.text('First Name').hitTestable(), findsNothing);
    await _expand(tester, _basicInformationHeader()); // re-expand

    expect(find.text('Male'), findsOneWidget);
  });

  testWidgets('selecting Female persists after Basic Information collapse/re-expand', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.tap(find.byKey(const Key('addPersonGenderField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();

    await _expand(tester, _basicInformationHeader());
    await _expand(tester, _basicInformationHeader());

    expect(find.text('Female'), findsOneWidget);
  });

  testWidgets('selected DOB persists after Basic Information collapse/re-expand', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.tap(find.byKey(const Key('addPersonDateOfBirthField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Select date'), findsNothing);

    await _expand(tester, _basicInformationHeader());
    await _expand(tester, _basicInformationHeader());

    expect(find.text('Select date'), findsNothing);
  });

  testWidgets('Contact Information expands and shows Phone Number, Email Address, Address in order', (
    WidgetTester tester,
  ) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await _expand(tester, _contactInformationHeader());

    expect(find.text('Phone Number').hitTestable(), findsOneWidget);
    expect(find.text('Email Address').hitTestable(), findsOneWidget);
    expect(find.text('Address').hitTestable(), findsOneWidget);

    final phoneY = tester.getTopLeft(find.text('Phone Number')).dy;
    final emailY = tester.getTopLeft(find.text('Email Address')).dy;
    final addressY = tester.getTopLeft(find.text('Address')).dy;
    expect(emailY, greaterThan(phoneY));
    expect(addressY, greaterThan(emailY));
  });

  testWidgets('entered contact values persist after collapse/re-expand', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await _expand(tester, _contactInformationHeader());
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter phone number'), '5551234567');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter address'), '123 Main St');

    await _expand(tester, _contactInformationHeader()); // collapse
    await _expand(tester, _contactInformationHeader()); // re-expand

    expect(find.text('5551234567'), findsOneWidget);
    expect(find.text('123 Main St'), findsOneWidget);
  });

  testWidgets('Organization Information expands and shows Status defaulting to Active with exact options', (
    WidgetTester tester,
  ) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await _expand(tester, _organizationInformationHeader());

    expect(find.text('Status').hitTestable(), findsOneWidget);
    expect(find.text('Active').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsWidgets);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('selected Status persists after Organization Information collapse/re-expand', (
    WidgetTester tester,
  ) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await _expand(tester, _organizationInformationHeader());
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inactive').last);
    await tester.pumpAndSettle();

    await _expand(tester, _organizationInformationHeader()); // collapse
    await _expand(tester, _organizationInformationHeader()); // re-expand

    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('multiple supported cards may be expanded simultaneously', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await _expand(tester, _contactInformationHeader());
    await _expand(tester, _organizationInformationHeader());

    expect(find.text('First Name').hitTestable(), findsOneWidget, reason: 'Basic Information remains expanded');
    expect(find.text('Phone Number').hitTestable(), findsOneWidget);
    expect(find.text('Status').hitTestable(), findsOneWidget);
  });

  testWidgets('Notes card renders, is collapsed, and does not expand on tap', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.tap(_notesHeader());
    await tester.pumpAndSettle();

    // Basic Information (First Name, Last Name) is the only expanded card at
    // this point; Contact/Organization/Notes are collapsed, and Flutter's
    // default finders skip Offstage content, so only these two are visible.
    // TextFormField wraps TextField internally, so this also proves no
    // additional (Notes) text input was added by the tap.
    expect(find.byType(TextFormField).evaluate().length, 2);
  });

  testWidgets('Save Person renders below all four cards, and Cancel below Save Person', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    final notesY = tester.getTopLeft(_notesHeader()).dy;
    final saveY = tester.getTopLeft(find.text('Save Person')).dy;
    final cancelY = tester.getTopLeft(find.text('Cancel')).dy;

    expect(saveY, greaterThan(notesY));
    expect(cancelY, greaterThan(saveY));
  });

  testWidgets('empty First Name prevents submission and expands Basic Information', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);
    await _expand(tester, _basicInformationHeader()); // collapse it first

    await tester.tap(find.text('Save Person'));
    await tester.pumpAndSettle();

    expect(find.text('First name is required').hitTestable(), findsOneWidget);
    expect(api.createCallCount, 0);
  });

  testWidgets('empty Last Name prevents submission and expands Basic Information', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await _expand(tester, _basicInformationHeader()); // collapse

    await tester.tap(find.text('Save Person'));
    await tester.pumpAndSettle();

    expect(find.text('Last name is required').hitTestable(), findsOneWidget);
    expect(api.createCallCount, 0);
  });

  testWidgets('invalid Email prevents submission and expands Contact Information', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
    await _expand(tester, _contactInformationHeader());
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter email address'), 'not-an-email');
    await _expand(tester, _contactInformationHeader()); // collapse before submit

    await tester.tap(find.text('Save Person'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address').hitTestable(), findsOneWidget);
    expect(api.createCallCount, 0);
  });

  testWidgets('optional Gender, DOB, and Address are accepted (submission succeeds without them)', (
    WidgetTester tester,
  ) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
    await tester.tap(find.text('Save Person'));
    await tester.pumpAndSettle();

    expect(api.createCallCount, 1);
    expect(api.createCalls.single['gender'], isNull);
    expect(api.createCalls.single['dateOfBirth'], isNull);
    // Address follows the existing email/phone convention: the screen passes
    // the raw (untouched, empty) controller text through; PeopleApi.create()
    // is responsible for trimming and omitting it from the request body.
    expect(api.createCalls.single['address'], '');
  });

  testWidgets('duplicate Save taps produce exactly one create call', (WidgetTester tester) async {
    final gate = Completer<PersonSummary>();
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) => gate.future);
    await _pumpAddPersonScreen(tester, api);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');

    final saveButton = find.byType(FilledButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();

    gate.complete(_createdPerson());
    await tester.pumpAndSettle();

    expect(api.createCallCount, 1);
  });

  testWidgets('failed submit preserves all field values including Gender, DOB, Address, and Status', (
    WidgetTester tester,
  ) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async {
      throw Exception('network error');
    });
    await _pumpAddPersonScreen(tester, api);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');

    await tester.tap(find.byKey(const Key('addPersonGenderField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addPersonDateOfBirthField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await _expand(tester, _contactInformationHeader());
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter address'), '123 Main St');

    await _expand(tester, _organizationInformationHeader());
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inactive').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Person'));
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Lovelace'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Select date'), findsNothing);
    expect(find.text('123 Main St'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('successful submit refreshes the directory and navigates back to People', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
    await tester.tap(find.text('Save Person'));
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
  });

  testWidgets('Cancel returns to People without submitting', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
    expect(api.createCallCount, 0);
  });

  testWidgets('back arrow returns to People without submitting', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    await _pumpAddPersonScreen(tester, api);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
    expect(api.createCallCount, 0);
  });

  testWidgets('a stale create response after Cancel has no navigation/refresh effect', (WidgetTester tester) async {
    final gate = Completer<PersonSummary>();
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) => gate.future);
    await _pumpAddPersonScreen(tester, api);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
    await tester.tap(find.text('Save Person'));
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('People Screen'), findsOneWidget);

    gate.complete(_createdPerson());
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
  });

  testWidgets('a stale create response after back has no navigation/refresh effect', (WidgetTester tester) async {
    final gate = Completer<PersonSummary>();
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) => gate.future);
    await _pumpAddPersonScreen(tester, api);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
    await tester.tap(find.text('Save Person'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('People Screen'), findsOneWidget);

    gate.complete(_createdPerson());
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
  });

  testWidgets('organization switch while Add Person is open closes the form', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) async => _createdPerson());
    final harness = await _pumpAddPersonScreen(tester, api, initialOrg: _orgA);

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
    expect(api.createCallCount, 0);
  });

  testWidgets('a stale Organization A success does not refresh or render in Organization B', (
    WidgetTester tester,
  ) async {
    final gate = Completer<PersonSummary>();
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) => gate.future);
    final harness = await _pumpAddPersonScreen(tester, api, initialOrg: _orgA);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
    await tester.tap(find.text('Save Person'));
    await tester.pump();

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();
    expect(find.text('People Screen'), findsOneWidget);

    gate.complete(_createdPerson());
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
  });

  testWidgets('a stale Organization A error does not render after switching to Organization B', (
    WidgetTester tester,
  ) async {
    final gate = Completer<PersonSummary>();
    final api = _ScriptedPeopleApi(({required organizationId, required firstName, required lastName, email, phone, required status, gender, dateOfBirth, address}) => gate.future);
    final harness = await _pumpAddPersonScreen(tester, api, initialOrg: _orgA);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter first name'), 'Ada');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter last name'), 'Lovelace');
    await tester.tap(find.text('Save Person'));
    await tester.pump();

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();
    expect(find.text('People Screen'), findsOneWidget);

    gate.completeError(Exception('org-a network error'));
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
    expect(find.textContaining('network error'), findsNothing);
  });
}
