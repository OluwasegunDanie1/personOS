import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/add_person_controller.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/people_state_controller.dart';

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController(this._current);

  OrganizationContextState _current;

  @override
  OrganizationContextState build() => _current;

  void emit(OrganizationContextState next) {
    _current = next;
    state = next;
  }
}

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi({required this.createHandler, required this.listHandler}) : super(Dio());

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

  Future<PeoplePage> Function({required String organizationId}) listHandler;

  int createCallCount = 0;
  int listCallCount = 0;
  String? lastCreateOrganizationId;
  PersonGender? lastCreateGender;
  DateTime? lastCreateDateOfBirth;
  String? lastCreateAddress;

  @override
  Future<PeoplePage> list({
    required String organizationId,
    String? cursor,
    String? search,
    PersonStatus? status,
    int? limit,
  }) {
    listCallCount++;
    return listHandler(organizationId: organizationId);
  }

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
    lastCreateOrganizationId = organizationId;
    lastCreateGender = gender;
    lastCreateDateOfBirth = dateOfBirth;
    lastCreateAddress = address;
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

const _ownerRole = OrganizationRole(id: 'role-1', name: 'Owner');

OrganizationSummary _org(String id) => OrganizationSummary(id: id, name: id, logoUrl: null, role: _ownerRole);

PersonSummary _person(String id) => PersonSummary(
  id: id,
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: null,
  phone: null,
  status: PersonStatus.active,
  avatarUrl: null,
  joinedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  late _ScriptedPeopleApi api;
  late _FakeOrganizationContextController orgController;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    required OrganizationContextState initialOrgState,
    required Future<PersonSummary> Function({
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
    createHandler,
    Future<PeoplePage> Function({required String organizationId})? listHandler,
  }) {
    api = _ScriptedPeopleApi(
      createHandler: createHandler,
      listHandler: listHandler ?? ({required organizationId}) async => PeoplePage(people: [], nextCursor: null),
    );
    orgController = _FakeOrganizationContextController(initialOrgState);
    container = ProviderContainer(
      overrides: [
        peopleApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
    );
    addTearDown(container.dispose);
    // Eagerly attach both controllers (matches the People Directory test
    // precedent): a bare container.read() only recomputes on next access.
    container.listen(peopleDirectoryControllerProvider, (_, _) {});
    container.listen(addPersonControllerProvider, (_, _) {});
    return container;
  }

  test('successful submit calls create then refreshes the People Directory', () async {
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) async => _person('new-person'),
      listHandler: ({required organizationId}) async => PeoplePage(people: [_person('new-person')], nextCursor: null),
    );
    await Future<void>.delayed(Duration.zero);

    final initialListCalls = api.listCallCount;

    await container
        .read(addPersonControllerProvider.notifier)
        .submit(firstName: 'Ada', lastName: 'Lovelace', email: '', phone: '', status: PersonStatus.active);

    expect(api.createCallCount, 1);
    expect(api.listCallCount, greaterThan(initialListCalls), reason: 'refresh() must call list() again');
    expect(container.read(addPersonControllerProvider).status, AddPersonSubmitStatus.success);
    expect(container.read(peopleDirectoryControllerProvider).people.map((p) => p.id), ['new-person']);
  });

  test('duplicate submit taps produce exactly one create call', () async {
    final gate = Completer<PersonSummary>();
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) => gate.future,
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(addPersonControllerProvider.notifier);
    final first = notifier.submit(firstName: 'Ada', lastName: 'Lovelace', email: '', phone: '', status: PersonStatus.active);
    final second = notifier.submit(firstName: 'Ada', lastName: 'Lovelace', email: '', phone: '', status: PersonStatus.active);

    gate.complete(_person('new-person'));
    await Future.wait([first, second]);

    expect(api.createCallCount, 1);
  });

  test('cancel() invalidates the generation so a late create response has no effect', () async {
    final gate = Completer<PersonSummary>();
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) => gate.future,
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(addPersonControllerProvider.notifier);
    final pending = notifier.submit(firstName: 'Ada', lastName: 'Lovelace', email: '', phone: '', status: PersonStatus.active);

    notifier.cancel();
    gate.complete(_person('new-person'));
    await pending;

    expect(
      container.read(addPersonControllerProvider).status,
      isNot(AddPersonSubmitStatus.success),
      reason: 'a cancelled submit must not transition to success',
    );
  });

  test('organization switch while the form is idle sets shouldClose', () async {
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) async => _person('new-person'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(addPersonControllerProvider).shouldClose, isFalse);

    orgController.emit(OrganizationContextActive(organizations: [_org('org-b')], selectedOrganizationId: 'org-b'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(addPersonControllerProvider).shouldClose, isTrue);
  });

  test('a stale Organization A create success does not refresh Organization B People state', () async {
    final gate = Completer<PersonSummary>();
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) => gate.future,
      listHandler: ({required organizationId}) async =>
          PeoplePage(people: [_person('$organizationId-existing')], nextCursor: null),
    );
    await Future<void>.delayed(Duration.zero);

    final pending = container
        .read(addPersonControllerProvider.notifier)
        .submit(firstName: 'Ada', lastName: 'Lovelace', email: '', phone: '', status: PersonStatus.active);

    // Organization switches to B while org-A's create is still in flight.
    orgController.emit(OrganizationContextActive(organizations: [_org('org-b')], selectedOrganizationId: 'org-b'));
    await Future<void>.delayed(Duration.zero);

    final listCallsBeforeStaleResponse = api.listCallCount;

    // org-A's stale create response now resolves.
    gate.complete(_person('org-a-created-person'));
    await pending;
    await Future<void>.delayed(Duration.zero);

    expect(
      api.listCallCount,
      listCallsBeforeStaleResponse,
      reason: 'the stale org-A success must never trigger a directory refresh',
    );
    expect(container.read(addPersonControllerProvider).status, isNot(AddPersonSubmitStatus.success));
    expect(
      container.read(peopleDirectoryControllerProvider).people.map((p) => p.id),
      ['org-b-existing'],
      reason: 'org-B People state must remain exactly what org-B loaded, untouched by the stale org-A response',
    );
  });

  test('gender is optional and omitted when not supplied', () async {
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) async => _person('new-person'),
    );
    await Future<void>.delayed(Duration.zero);

    await container
        .read(addPersonControllerProvider.notifier)
        .submit(firstName: 'Ada', lastName: 'Lovelace', email: '', phone: '', status: PersonStatus.active);

    expect(api.lastCreateGender, isNull);
  });

  test('MALE passes to the API when Gender is selected as Male', () async {
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) async => _person('new-person'),
    );
    await Future<void>.delayed(Duration.zero);

    await container
        .read(addPersonControllerProvider.notifier)
        .submit(
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: '',
          phone: '',
          status: PersonStatus.active,
          gender: PersonGender.male,
        );

    expect(api.lastCreateGender, PersonGender.male);
  });

  test('FEMALE passes to the API when Gender is selected as Female', () async {
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) async => _person('new-person'),
    );
    await Future<void>.delayed(Duration.zero);

    await container
        .read(addPersonControllerProvider.notifier)
        .submit(
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: '',
          phone: '',
          status: PersonStatus.active,
          gender: PersonGender.female,
        );

    expect(api.lastCreateGender, PersonGender.female);
  });

  test('Date of Birth is optional and the exact selected value passes to the API', () async {
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) async => _person('new-person'),
    );
    await Future<void>.delayed(Duration.zero);

    await container
        .read(addPersonControllerProvider.notifier)
        .submit(
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: '',
          phone: '',
          status: PersonStatus.active,
          dateOfBirth: DateTime(2001, 7, 14),
        );

    expect(api.lastCreateDateOfBirth, DateTime(2001, 7, 14));
  });

  test('Address is optional and the trimmed value passes to the API', () async {
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) async => _person('new-person'),
    );
    await Future<void>.delayed(Duration.zero);

    await container
        .read(addPersonControllerProvider.notifier)
        .submit(
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: '',
          phone: '',
          status: PersonStatus.active,
          address: '123 Main St',
        );

    expect(api.lastCreateAddress, '123 Main St');
  });

  test('the optional new fields do not weaken duplicate-submit prevention', () async {
    final gate = Completer<PersonSummary>();
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) => gate.future,
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(addPersonControllerProvider.notifier);
    final first = notifier.submit(
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: '',
      phone: '',
      status: PersonStatus.active,
      gender: PersonGender.male,
      dateOfBirth: DateTime(2001, 7, 14),
      address: '123 Main St',
    );
    final second = notifier.submit(
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: '',
      phone: '',
      status: PersonStatus.active,
      gender: PersonGender.male,
      dateOfBirth: DateTime(2001, 7, 14),
      address: '123 Main St',
    );

    gate.complete(_person('new-person'));
    await Future.wait([first, second]);

    expect(api.createCallCount, 1);
  });

  test('the optional new fields do not weaken stale-response protection after cancel()', () async {
    final gate = Completer<PersonSummary>();
    buildContainer(
      initialOrgState: OrganizationContextActive(organizations: [_org('org-a')], selectedOrganizationId: 'org-a'),
      createHandler:
          ({
            required organizationId,
            required firstName,
            required lastName,
            email,
            phone,
            required status,
            gender,
            dateOfBirth,
            address,
          }) => gate.future,
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(addPersonControllerProvider.notifier);
    final pending = notifier.submit(
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: '',
      phone: '',
      status: PersonStatus.active,
      gender: PersonGender.female,
      dateOfBirth: DateTime(1990, 3, 3),
      address: '9 Elm St',
    );

    notifier.cancel();
    gate.complete(_person('new-person'));
    await pending;

    expect(
      container.read(addPersonControllerProvider).status,
      isNot(AddPersonSubmitStatus.success),
      reason: 'a cancelled submit with gender/DOB/address supplied must still not transition to success',
    );
  });
}
