import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/create_follow_up_controller.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/person_profile_controller.dart';

typedef _DetailHandler = Future<PersonDetail> Function({required String organizationId, required String personId});
typedef _JourneyHandler = Future<PersonJourneyView> Function({
  required String organizationId,
  required String personId,
});
typedef _StagesHandler = Future<List<JourneyStageListEntry>> Function({required String organizationId});
typedef _SummaryHandler = Future<AttendanceSummary> Function({
  required String organizationId,
  required String personId,
});
typedef _FollowUpsHandler = Future<FollowUpListResult> Function({
  required String organizationId,
  required String personId,
});
typedef _CreateFollowUpHandler = Future<FollowUpSummary> Function({
  required String organizationId,
  required String personId,
  required String title,
  String? description,
  DateTime? dueDate,
});

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi({
    required this.detailHandler,
    required this.journeyHandler,
    required this.stagesHandler,
    required this.summaryHandler,
    required this.followUpsHandler,
    required this.createFollowUpHandler,
  }) : super(Dio());

  _DetailHandler detailHandler;
  _JourneyHandler journeyHandler;
  _StagesHandler stagesHandler;
  _SummaryHandler summaryHandler;
  _FollowUpsHandler followUpsHandler;
  _CreateFollowUpHandler createFollowUpHandler;

  int createFollowUpCallCount = 0;
  int followUpsCallCount = 0;
  Map<String, dynamic>? lastCreateArgs;

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
  Future<PersonJourneyView> journey({required String organizationId, required String personId}) =>
      journeyHandler(organizationId: organizationId, personId: personId);

  @override
  Future<List<JourneyStageListEntry>> journeyStages({required String organizationId}) =>
      stagesHandler(organizationId: organizationId);

  @override
  Future<AttendanceSummary> attendanceSummary({required String organizationId, required String personId}) =>
      summaryHandler(organizationId: organizationId, personId: personId);

  @override
  Future<FollowUpListResult> personFollowUps({required String organizationId, required String personId}) {
    followUpsCallCount++;
    return followUpsHandler(organizationId: organizationId, personId: personId);
  }

  @override
  Future<FollowUpSummary> createFollowUp({
    required String organizationId,
    required String personId,
    required String title,
    String? description,
    DateTime? dueDate,
  }) {
    createFollowUpCallCount++;
    lastCreateArgs = {
      'organizationId': organizationId,
      'personId': personId,
      'title': title,
      'description': description,
      'dueDate': dueDate,
    };
    return createFollowUpHandler(
      organizationId: organizationId,
      personId: personId,
      title: title,
      description: description,
      dueDate: dueDate,
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

PersonDetail _detail() => PersonDetail(
  id: 'person-1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: null,
  phone: null,
  status: PersonStatus.active,
  avatarUrl: null,
  joinedAt: DateTime.utc(2026, 1, 1),
  tags: const [],
  currentJourneyStage: null,
  gender: null,
  dateOfBirth: null,
  address: null,
);

FollowUpSummary _createdFollowUp({String id = 'fu-new'}) => FollowUpSummary(
  id: id,
  title: 'New follow-up',
  description: null,
  dueDate: null,
  status: FollowUpStatus.pending,
  completedAt: null,
  person: const FollowUpPersonRef(id: 'person-1', firstName: 'Ada', lastName: 'Lovelace'),
  assignedTo: null,
);

const _journey = PersonJourneyView(currentStage: null, history: []);
const _stages = <JourneyStageListEntry>[];
const _summary = AttendanceSummary(totalCount: 0, currentMonthCount: 0);
const _emptyFollowUps = FollowUpListResult(followUps: [], nextCursor: null);

void main() {
  late _ScriptedPeopleApi api;
  late _FakeOrganizationContextController orgController;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    required OrganizationContextState initialOrgState,
    _FollowUpsHandler? followUpsHandler,
    _CreateFollowUpHandler? createFollowUpHandler,
  }) {
    api = _ScriptedPeopleApi(
      detailHandler: ({required organizationId, required personId}) async => _detail(),
      journeyHandler: ({required organizationId, required personId}) async => _journey,
      stagesHandler: ({required organizationId}) async => _stages,
      summaryHandler: ({required organizationId, required personId}) async => _summary,
      followUpsHandler: followUpsHandler ?? ({required organizationId, required personId}) async => _emptyFollowUps,
      createFollowUpHandler:
          createFollowUpHandler ??
          ({required organizationId, required personId, required title, description, dueDate}) async =>
              _createdFollowUp(),
    );
    orgController = _FakeOrganizationContextController(initialOrgState);
    container = ProviderContainer(
      overrides: [
        peopleApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
    );
    addTearDown(container.dispose);
    // Both providers are eagerly attached: Create Follow-up's success path
    // reads the already-mounted PersonProfileController via
    // ref.read(personProfileControllerProvider(personId).notifier).
    container.listen(personProfileControllerProvider('person-1'), (_, _) {});
    container.listen(createFollowUpControllerProvider('person-1'), (_, _) {});
    return container;
  }

  test('submit uses the current personId and the pinned selected organization', () async {
    buildContainer(initialOrgState: _orgA);
    await Future<void>.delayed(Duration.zero);

    await container.read(createFollowUpControllerProvider('person-1').notifier).submit(title: 'New follow-up');

    expect(api.lastCreateArgs!['personId'], 'person-1');
    expect(api.lastCreateArgs!['organizationId'], 'org-a');
  });

  test('duplicate submit is blocked while one is in flight', () async {
    final gate = Completer<FollowUpSummary>();
    buildContainer(
      initialOrgState: _orgA,
      createFollowUpHandler:
          ({required organizationId, required personId, required title, description, dueDate}) => gate.future,
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(createFollowUpControllerProvider('person-1').notifier);
    final first = notifier.submit(title: 'First');
    final second = notifier.submit(title: 'Second');

    gate.complete(_createdFollowUp());
    await Future.wait([first, second]);

    expect(api.createFollowUpCallCount, 1, reason: 'a second concurrent submit must be ignored while one is in flight');
  });

  test('sends the exact create body (title, optional description/dueDate)', () async {
    buildContainer(initialOrgState: _orgA);
    await Future<void>.delayed(Duration.zero);

    final dueDate = DateTime.utc(2026, 8, 2);
    await container
        .read(createFollowUpControllerProvider('person-1').notifier)
        .submit(title: 'New follow-up', description: 'Details', dueDate: dueDate);

    expect(api.lastCreateArgs!['title'], 'New follow-up');
    expect(api.lastCreateArgs!['description'], 'Details');
    expect(api.lastCreateArgs!['dueDate'], dueDate);
  });

  test('a stale Organization A success is discarded after switching to Organization B', () async {
    final gate = Completer<FollowUpSummary>();
    buildContainer(
      initialOrgState: _orgA,
      createFollowUpHandler:
          ({required organizationId, required personId, required title, description, dueDate}) => gate.future,
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(createFollowUpControllerProvider('person-1').notifier);
    final submit = notifier.submit(title: 'New follow-up');

    orgController.emit(_orgB);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(createFollowUpControllerProvider('person-1')).shouldClose, isTrue);

    gate.complete(_createdFollowUp());
    await submit;
    await Future<void>.delayed(Duration.zero);

    final state = container.read(createFollowUpControllerProvider('person-1'));
    expect(state.status, isNot(CreateFollowUpSubmitStatus.success), reason: 'the stale org-a success must not apply');
  });

  test('a stale Organization A error is discarded after switching to Organization B', () async {
    final gate = Completer<FollowUpSummary>();
    buildContainer(
      initialOrgState: _orgA,
      createFollowUpHandler:
          ({required organizationId, required personId, required title, description, dueDate}) => gate.future,
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(createFollowUpControllerProvider('person-1').notifier);
    final submit = notifier.submit(title: 'New follow-up');

    orgController.emit(_orgB);
    await Future<void>.delayed(Duration.zero);

    gate.completeError(Exception('stale network failure'));
    await submit;
    await Future<void>.delayed(Duration.zero);

    final state = container.read(createFollowUpControllerProvider('person-1'));
    expect(state.status, isNot(CreateFollowUpSubmitStatus.error), reason: 'the stale org-a error must not apply');
    expect(state.errorMessage, isNull);
  });

  test('organization switch sets shouldClose', () async {
    buildContainer(initialOrgState: _orgA);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(createFollowUpControllerProvider('person-1')).shouldClose, isFalse);

    orgController.emit(_orgB);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(createFollowUpControllerProvider('person-1')).shouldClose, isTrue);
  });

  test('API failure surfaces an error and preserves the ability to retry', () async {
    var shouldFail = true;
    buildContainer(
      initialOrgState: _orgA,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async {
        if (shouldFail) throw Exception('boom');
        return _createdFollowUp();
      },
    );
    await Future<void>.delayed(Duration.zero);

    await container.read(createFollowUpControllerProvider('person-1').notifier).submit(title: 'New follow-up');
    var state = container.read(createFollowUpControllerProvider('person-1'));
    expect(state.status, CreateFollowUpSubmitStatus.error);
    expect(state.errorMessage, isNotNull);

    shouldFail = false;
    await container.read(createFollowUpControllerProvider('person-1').notifier).submit(title: 'New follow-up');
    state = container.read(createFollowUpControllerProvider('person-1'));
    expect(state.status, CreateFollowUpSubmitStatus.success);
  });

  test('successful create returns success and triggers a real Profile Follow-up GET refresh', () async {
    var followUpsCallIndex = 0;
    buildContainer(
      initialOrgState: _orgA,
      followUpsHandler: ({required organizationId, required personId}) async {
        followUpsCallIndex++;
        if (followUpsCallIndex == 1) return _emptyFollowUps;
        return FollowUpListResult(followUps: [_createdFollowUp(id: 'fu-refreshed')], nextCursor: null);
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(personProfileControllerProvider('person-1')).followUps, isEmpty);

    await container.read(createFollowUpControllerProvider('person-1').notifier).submit(title: 'New follow-up');

    expect(container.read(createFollowUpControllerProvider('person-1')).status, CreateFollowUpSubmitStatus.success);
    expect(api.followUpsCallCount, 2, reason: 'the real GET must be called again after a successful create');
    expect(
      container.read(personProfileControllerProvider('person-1')).followUps!.single.id,
      'fu-refreshed',
      reason: 'the GET refresh remains the sole displayed-collection authority, never a locally fabricated entry',
    );
  });
}
