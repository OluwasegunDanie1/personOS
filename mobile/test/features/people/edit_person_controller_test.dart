import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/edit_person_controller.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/person_profile_controller.dart';

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

  int detailCallCount = 0;
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
  Future<PersonDetail> detail({required String organizationId, required String personId}) {
    detailCallCount++;
    return detailHandler(organizationId: organizationId, personId: personId);
  }

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
  _FakeOrganizationContextController(this._current);

  OrganizationContextState _current;

  @override
  OrganizationContextState build() => _current;

  void emit(OrganizationContextState next) {
    _current = next;
    state = next;
  }
}

const _org = OrganizationRole(id: 'role-1', name: 'Owner');
OrganizationSummary _orgSummary(String id) => OrganizationSummary(id: id, name: id, logoUrl: null, role: _org);

final _orgA = OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a');
final _orgB = OrganizationContextActive(organizations: [_orgSummary('org-b')], selectedOrganizationId: 'org-b');

PersonDetail _detail({
  String id = 'person-1',
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
  id: 'person-1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: 'ada@example.com',
  phone: '+1234567890',
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
    _DetailHandler? detailHandler,
    _UpdateHandler? updateHandler,
  }) {
    api = _ScriptedPeopleApi(
      detailHandler: detailHandler ?? ({required organizationId, required personId}) async => _detail(),
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
    orgController = _FakeOrganizationContextController(initialOrgState);
    container = ProviderContainer(
      overrides: [
        peopleApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
    );
    addTearDown(container.dispose);
    // Both providers are eagerly attached: a successful submit reads the
    // already-mounted PersonProfileController via
    // ref.read(personProfileControllerProvider(personId).notifier).refreshDetail().
    container.listen(personProfileControllerProvider('person-1'), (_, _) {});
    container.listen(editPersonControllerProvider('person-1'), (_, _) {});
    return container;
  }

  EditPersonFormValues unchangedForm(PersonDetail detail) => EditPersonFormValues(
    firstName: detail.firstName,
    lastName: detail.lastName,
    email: detail.email ?? '',
    phone: detail.phone ?? '',
    status: detail.status,
    gender: detail.gender,
    dateOfBirth: detail.dateOfBirth,
    address: detail.address ?? '',
  );

  group('load', () {
    test('requires personId and uses the selected organization to load real Person Detail', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(editPersonControllerProvider('person-1'));
      expect(state.loadStatus, EditPersonLoadStatus.loaded);
      expect(state.detail, isNotNull);
      expect(state.detail!.id, 'person-1');
      // detailCallCount also reflects PersonProfileController's own
      // independent initial load (both providers are eagerly attached in
      // this harness) — at least one of those calls is EditPersonController's.
      expect(api.detailCallCount, greaterThanOrEqualTo(1));
    });

    test('loaded state exposes exact initial editable values from real Detail authority', () async {
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async => _detail(
          firstName: 'Grace',
          lastName: 'Hopper',
          gender: PersonGender.female,
          dateOfBirth: DateTime.utc(1990, 12, 9),
          address: '221B Baker Street',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      expect(detail.firstName, 'Grace');
      expect(detail.lastName, 'Hopper');
      expect(detail.gender, PersonGender.female);
      expect(detail.dateOfBirth, DateTime.utc(1990, 12, 9));
      expect(detail.address, '221B Baker Street');
    });

    test('a load failure sets a truthful error state and clears detail', () async {
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async => throw Exception('network down'),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(editPersonControllerProvider('person-1'));
      expect(state.loadStatus, EditPersonLoadStatus.error);
      expect(state.detail, isNull);
      expect(state.loadErrorMessage, isNotNull);
    });

    test('retryLoad recovers from a prior failure', () async {
      var shouldFail = true;
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async {
          if (shouldFail) throw Exception('boom');
          return _detail();
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(editPersonControllerProvider('person-1')).loadStatus, EditPersonLoadStatus.error);

      shouldFail = false;
      await container.read(editPersonControllerProvider('person-1').notifier).retryLoad();

      expect(container.read(editPersonControllerProvider('person-1')).loadStatus, EditPersonLoadStatus.loaded);
    });

    test('a stale Organization A load success is discarded after switching to Organization B', () async {
      final gate = Completer<PersonDetail>();
      buildContainer(initialOrgState: _orgA, detailHandler: ({required organizationId, required personId}) => gate.future);
      await Future<void>.delayed(Duration.zero);

      orgController.emit(_orgB);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(editPersonControllerProvider('person-1')).shouldClose, isTrue);

      gate.complete(_detail());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(editPersonControllerProvider('person-1'));
      expect(state.loadStatus, EditPersonLoadStatus.loading, reason: 'the stale org-a success must never be applied');
      expect(state.detail, isNull);
    });

    test('a stale Organization A load error is discarded after switching to Organization B', () async {
      final gate = Completer<PersonDetail>();
      buildContainer(initialOrgState: _orgA, detailHandler: ({required organizationId, required personId}) => gate.future);
      await Future<void>.delayed(Duration.zero);

      orgController.emit(_orgB);
      await Future<void>.delayed(Duration.zero);

      gate.completeError(Exception('stale network failure'));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(editPersonControllerProvider('person-1'));
      expect(state.loadStatus, EditPersonLoadStatus.loading, reason: 'the stale org-a error must never be applied');
      expect(state.loadErrorMessage, isNull);
    });

    test('an older load retry cannot overwrite newer retry state', () async {
      final staleGate = Completer<PersonDetail>();
      final initialEntered = Completer<void>();
      var callIndex = 0;
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) {
          callIndex++;
          if (callIndex == 1) {
            if (!initialEntered.isCompleted) initialEntered.complete();
            return staleGate.future;
          }
          return Future.value(_detail(firstName: 'Fresh'));
        },
      );

      await initialEntered.future;

      final notifier = container.read(editPersonControllerProvider('person-1').notifier);
      await notifier.retryLoad();

      expect(container.read(editPersonControllerProvider('person-1')).detail!.firstName, 'Fresh');

      staleGate.complete(_detail(firstName: 'Stale'));
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(editPersonControllerProvider('person-1')).detail!.firstName,
        'Fresh',
        reason: 'the stale generation-1 response must not overwrite the newer retry state',
      );
    });
  });

  group('normalization / changed-fields-only PATCH', () {
    test('an unchanged form produces no PATCH at all', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container.read(editPersonControllerProvider('person-1').notifier).submit(unchangedForm(detail));

      expect(api.updateCallCount, 0);
      expect(container.read(editPersonControllerProvider('person-1')).submitStatus, EditPersonSubmitStatus.noChange);
    });

    test('a trimmed-but-unchanged firstName produces no firstName field (and no PATCH)', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final form = EditPersonFormValues(
        firstName: '  ${detail.firstName}  ',
        lastName: detail.lastName,
        email: detail.email ?? '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      await container.read(editPersonControllerProvider('person-1').notifier).submit(form);

      expect(api.updateCallCount, 0);
    });

    test('a changed firstName sends firstName only', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final form = EditPersonFormValues(
        firstName: 'Updated',
        lastName: detail.lastName,
        email: detail.email ?? '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      await container.read(editPersonControllerProvider('person-1').notifier).submit(form);

      expect(api.updateCallCount, 1);
      final args = api.lastUpdateArgs!;
      expect(args['firstName']!.isSet, isTrue);
      expect(args['firstName']!.value, 'Updated');
      expect(args['lastName']!.isSet, isFalse);
      expect(args['email']!.isSet, isFalse);
      expect(args['phone']!.isSet, isFalse);
      expect(args['status']!.isSet, isFalse);
      expect(args['gender']!.isSet, isFalse);
      expect(args['dateOfBirth']!.isSet, isFalse);
      expect(args['address']!.isSet, isFalse);
    });

    test('a changed lastName sends lastName only', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final form = EditPersonFormValues(
        firstName: detail.firstName,
        lastName: 'Byron',
        email: detail.email ?? '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      await container.read(editPersonControllerProvider('person-1').notifier).submit(form);

      final args = api.lastUpdateArgs!;
      expect(args['lastName']!.isSet, isTrue);
      expect(args['lastName']!.value, 'Byron');
      expect(args['firstName']!.isSet, isFalse);
    });

    test('empty email from a non-null initial email sends email: null (explicit clear)', () async {
      buildContainer(initialOrgState: _orgA, detailHandler: ({required organizationId, required personId}) async => _detail());
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final form = EditPersonFormValues(
        firstName: detail.firstName,
        lastName: detail.lastName,
        email: '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      await container.read(editPersonControllerProvider('person-1').notifier).submit(form);

      final args = api.lastUpdateArgs!;
      expect(args['email']!.isSet, isTrue);
      expect(args['email']!.value, isNull);
    });

    test('an unchanged null email is omitted', () async {
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async => _detail(email: null),
      );
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: 'Changed',
            lastName: detail.lastName,
            email: '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: detail.dateOfBirth,
            address: detail.address ?? '',
          ));

      expect(api.lastUpdateArgs!['email']!.isSet, isFalse);
    });

    test('empty phone from a non-null initial phone sends phone: null (explicit clear)', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: detail.firstName,
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: detail.dateOfBirth,
            address: detail.address ?? '',
          ));

      final args = api.lastUpdateArgs!;
      expect(args['phone']!.isSet, isTrue);
      expect(args['phone']!.value, isNull);
    });

    test('an unchanged null phone is omitted', () async {
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async => _detail(phone: null),
      );
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: 'Changed',
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: detail.dateOfBirth,
            address: detail.address ?? '',
          ));

      expect(api.lastUpdateArgs!['phone']!.isSet, isFalse);
    });

    test('a status change sends status only', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: detail.firstName,
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: PersonStatus.inactive,
            gender: detail.gender,
            dateOfBirth: detail.dateOfBirth,
            address: detail.address ?? '',
          ));

      final args = api.lastUpdateArgs!;
      expect(args['status']!.isSet, isTrue);
      expect(args['status']!.value, PersonStatus.inactive);
      expect(args['firstName']!.isSet, isFalse);
    });

    test('gender MALE/FEMALE changes send the exact value', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: detail.firstName,
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: PersonGender.male,
            dateOfBirth: detail.dateOfBirth,
            address: detail.address ?? '',
          ));

      final args = api.lastUpdateArgs!;
      expect(args['gender']!.isSet, isTrue);
      expect(args['gender']!.value, PersonGender.male);
    });

    test('clearing a previously-set gender sends gender: null', () async {
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async => _detail(gender: PersonGender.female),
      );
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: detail.firstName,
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: null,
            dateOfBirth: detail.dateOfBirth,
            address: detail.address ?? '',
          ));

      final args = api.lastUpdateArgs!;
      expect(args['gender']!.isSet, isTrue);
      expect(args['gender']!.value, isNull);
    });

    test('an unchanged null gender is omitted', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      expect(detail.gender, isNull);

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: 'Changed',
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: null,
            dateOfBirth: detail.dateOfBirth,
            address: detail.address ?? '',
          ));

      expect(api.lastUpdateArgs!['gender']!.isSet, isFalse);
    });

    test('a dateOfBirth change sends an exact YYYY-MM-DD string', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: detail.firstName,
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: DateTime.utc(2001, 1, 5),
            address: detail.address ?? '',
          ));

      final args = api.lastUpdateArgs!;
      expect(args['dateOfBirth']!.isSet, isTrue);
      expect(args['dateOfBirth']!.value, '2001-01-05');
    });

    test('clearing a previously-set dateOfBirth sends null', () async {
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async =>
            _detail(dateOfBirth: DateTime.utc(2001, 1, 5)),
      );
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: detail.firstName,
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: null,
            address: detail.address ?? '',
          ));

      final args = api.lastUpdateArgs!;
      expect(args['dateOfBirth']!.isSet, isTrue);
      expect(args['dateOfBirth']!.value, isNull);
    });

    test('an unchanged null dateOfBirth is omitted', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      expect(detail.dateOfBirth, isNull);

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: 'Changed',
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: null,
            address: detail.address ?? '',
          ));

      expect(api.lastUpdateArgs!['dateOfBirth']!.isSet, isFalse);
    });

    test('address is trimmed before comparison', () async {
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async => _detail(address: '221B Baker Street'),
      );
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: detail.firstName,
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: detail.dateOfBirth,
            address: '  221B Baker Street  ',
          ));

      expect(api.updateCallCount, 0, reason: 'the only difference is whitespace, which trims away to no change');
    });

    test('a whitespace-only address from a non-null initial address sends address: null', () async {
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async => _detail(address: '221B Baker Street'),
      );
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: detail.firstName,
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: detail.dateOfBirth,
            address: '   ',
          ));

      final args = api.lastUpdateArgs!;
      expect(args['address']!.isSet, isTrue);
      expect(args['address']!.value, isNull);
    });

    test('an unchanged null address is omitted', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      expect(detail.address, isNull);

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: 'Changed',
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: detail.status,
            gender: detail.gender,
            dateOfBirth: detail.dateOfBirth,
            address: '',
          ));

      expect(api.lastUpdateArgs!['address']!.isSet, isFalse);
    });

    test('multiple simultaneous changes send only those exact fields', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;

      await container
          .read(editPersonControllerProvider('person-1').notifier)
          .submit(EditPersonFormValues(
            firstName: 'Updated',
            lastName: detail.lastName,
            email: detail.email ?? '',
            phone: detail.phone ?? '',
            status: PersonStatus.inactive,
            gender: PersonGender.male,
            dateOfBirth: detail.dateOfBirth,
            address: detail.address ?? '',
          ));

      final args = api.lastUpdateArgs!;
      expect(args['firstName']!.isSet, isTrue);
      expect(args['status']!.isSet, isTrue);
      expect(args['gender']!.isSet, isTrue);
      expect(args['lastName']!.isSet, isFalse);
      expect(args['email']!.isSet, isFalse);
      expect(args['phone']!.isSet, isFalse);
      expect(args['dateOfBirth']!.isSet, isFalse);
      expect(args['address']!.isSet, isFalse);
    });
  });

  group('submit', () {
    test('duplicate submit is blocked while one is in flight', () async {
      final gate = Completer<PersonSummary>();
      buildContainer(
        initialOrgState: _orgA,
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
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final notifier = container.read(editPersonControllerProvider('person-1').notifier);
      final form = EditPersonFormValues(
        firstName: 'Updated',
        lastName: detail.lastName,
        email: detail.email ?? '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      final first = notifier.submit(form);
      final second = notifier.submit(form);

      gate.complete(_summary());
      await Future.wait([first, second]);

      expect(api.updateCallCount, 1, reason: 'a second concurrent submit must be ignored while one is in flight');
    });

    test('an API failure preserves the ability to retry (form/edit authority preserved)', () async {
      var shouldFail = true;
      buildContainer(
        initialOrgState: _orgA,
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
            }) async {
              if (shouldFail) throw Exception('boom');
              return _summary();
            },
      );
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final form = EditPersonFormValues(
        firstName: 'Updated',
        lastName: detail.lastName,
        email: detail.email ?? '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      await container.read(editPersonControllerProvider('person-1').notifier).submit(form);
      var state = container.read(editPersonControllerProvider('person-1'));
      expect(state.submitStatus, EditPersonSubmitStatus.error);
      expect(state.submitErrorMessage, isNotNull);
      // Edit authority (the loaded Detail) remains intact after a submit
      // failure — nothing about the load state was disturbed.
      expect(container.read(editPersonControllerProvider('person-1')).detail, isNotNull);

      shouldFail = false;
      await container.read(editPersonControllerProvider('person-1').notifier).submit(form);
      state = container.read(editPersonControllerProvider('person-1'));
      expect(state.submitStatus, EditPersonSubmitStatus.success);
    });

    test('a stale Organization A submit success is discarded after switching to Organization B', () async {
      final gate = Completer<PersonSummary>();
      buildContainer(
        initialOrgState: _orgA,
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
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final notifier = container.read(editPersonControllerProvider('person-1').notifier);
      final form = EditPersonFormValues(
        firstName: 'Updated',
        lastName: detail.lastName,
        email: detail.email ?? '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      final submit = notifier.submit(form);

      orgController.emit(_orgB);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(editPersonControllerProvider('person-1')).shouldClose, isTrue);

      gate.complete(_summary());
      await submit;
      await Future<void>.delayed(Duration.zero);

      final state = container.read(editPersonControllerProvider('person-1'));
      expect(state.submitStatus, isNot(EditPersonSubmitStatus.success), reason: 'the stale org-a success must not apply');
    });

    test('a stale Organization A submit error is discarded after switching to Organization B', () async {
      final gate = Completer<PersonSummary>();
      buildContainer(
        initialOrgState: _orgA,
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
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final notifier = container.read(editPersonControllerProvider('person-1').notifier);
      final form = EditPersonFormValues(
        firstName: 'Updated',
        lastName: detail.lastName,
        email: detail.email ?? '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      final submit = notifier.submit(form);

      orgController.emit(_orgB);
      await Future<void>.delayed(Duration.zero);

      gate.completeError(Exception('stale network failure'));
      await submit;
      await Future<void>.delayed(Duration.zero);

      final state = container.read(editPersonControllerProvider('person-1'));
      expect(state.submitStatus, isNot(EditPersonSubmitStatus.error), reason: 'the stale org-a error must not apply');
      expect(state.submitErrorMessage, isNull);
    });

    test('organization switch closes the flow', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(editPersonControllerProvider('person-1')).shouldClose, isFalse);

      orgController.emit(_orgB);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(editPersonControllerProvider('person-1')).shouldClose, isTrue);
    });

    test('a successful PATCH returns success, triggers a real Profile Detail GET refresh, and never fabricates PersonDetail locally', () async {
      var detailCallIndex = 0;
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async {
          detailCallIndex++;
          // Both EditPersonController and (the eagerly-attached)
          // PersonProfileController independently call detail() once at
          // startup — calls 1 and 2. Only the third call, triggered by
          // EditPersonController.submit()'s post-success refreshDetail(),
          // represents the real post-edit refresh.
          if (detailCallIndex <= 2) return _detail();
          return _detail(firstName: 'Refreshed-From-Backend');
        },
      );
      await Future<void>.delayed(Duration.zero);
      final detail = container.read(editPersonControllerProvider('person-1')).detail!;
      final form = EditPersonFormValues(
        firstName: 'Locally-Typed-Value',
        lastName: detail.lastName,
        email: detail.email ?? '',
        phone: detail.phone ?? '',
        status: detail.status,
        gender: detail.gender,
        dateOfBirth: detail.dateOfBirth,
        address: detail.address ?? '',
      );

      await container.read(editPersonControllerProvider('person-1').notifier).submit(form);

      expect(container.read(editPersonControllerProvider('person-1')).submitStatus, EditPersonSubmitStatus.success);
      expect(api.detailCallCount, 3, reason: 'the real GET Detail must be called again after a successful PATCH');
      expect(
        container.read(personProfileControllerProvider('person-1')).detail!.firstName,
        'Refreshed-From-Backend',
        reason:
            'Profile Detail authority must come from the real GET refresh, never from the locally-typed Edit form value',
      );
    });
  });
}
