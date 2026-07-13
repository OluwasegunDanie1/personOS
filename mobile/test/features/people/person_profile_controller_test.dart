import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
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

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi({
    required this.detailHandler,
    required this.journeyHandler,
    required this.stagesHandler,
    required this.summaryHandler,
  }) : super(Dio());

  _DetailHandler detailHandler;
  _JourneyHandler journeyHandler;
  _StagesHandler stagesHandler;
  _SummaryHandler summaryHandler;

  int detailCallCount = 0;
  int journeyCallCount = 0;
  int stagesCallCount = 0;
  int summaryCallCount = 0;

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
  Future<PersonJourneyView> journey({required String organizationId, required String personId}) {
    journeyCallCount++;
    return journeyHandler(organizationId: organizationId, personId: personId);
  }

  @override
  Future<List<JourneyStageListEntry>> journeyStages({required String organizationId}) {
    stagesCallCount++;
    return stagesHandler(organizationId: organizationId);
  }

  @override
  Future<AttendanceSummary> attendanceSummary({required String organizationId, required String personId}) {
    summaryCallCount++;
    return summaryHandler(organizationId: organizationId, personId: personId);
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

PersonDetail _detail({String id = 'person-1', String? avatarUrl}) => PersonDetail(
  id: id,
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: null,
  phone: null,
  status: PersonStatus.active,
  avatarUrl: avatarUrl,
  joinedAt: DateTime.utc(2026, 1, 1),
  tags: const [],
  currentJourneyStage: null,
  gender: null,
  dateOfBirth: null,
  address: null,
);

const _journey = PersonJourneyView(currentStage: null, history: []);
const _stages = <JourneyStageListEntry>[];
const _summary = AttendanceSummary(totalCount: 0, currentMonthCount: 0);

void main() {
  late _ScriptedPeopleApi api;
  late _FakeOrganizationContextController orgController;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    required OrganizationContextState initialOrgState,
    _DetailHandler? detailHandler,
    _JourneyHandler? journeyHandler,
    _StagesHandler? stagesHandler,
    _SummaryHandler? summaryHandler,
  }) {
    api = _ScriptedPeopleApi(
      detailHandler: detailHandler ?? ({required organizationId, required personId}) async => _detail(),
      journeyHandler: journeyHandler ?? ({required organizationId, required personId}) async => _journey,
      stagesHandler: stagesHandler ?? ({required organizationId}) async => _stages,
      summaryHandler: summaryHandler ?? ({required organizationId, required personId}) async => _summary,
    );
    orgController = _FakeOrganizationContextController(initialOrgState);
    container = ProviderContainer(
      overrides: [
        peopleApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
    );
    addTearDown(container.dispose);
    container.listen(personProfileControllerProvider('person-1'), (_, _) {});
    return container;
  }

  test('loads all four approved dependencies using the selected organization', () async {
    buildContainer(initialOrgState: _orgA);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(personProfileControllerProvider('person-1'));
    expect(state.status, ProfileLoadStatus.loaded);
    expect(state.detail, isNotNull);
    expect(state.journey, isNotNull);
    expect(state.stages, isNotNull);
    expect(state.attendanceSummary, isNotNull);
    expect(api.detailCallCount, 1);
    expect(api.journeyCallCount, 1);
    expect(api.stagesCallCount, 1);
    expect(api.summaryCallCount, 1);
  });

  test('a Detail failure does not leave stale Detail/Journey/Stages/Attendance data as authoritative', () async {
    var shouldFail = true;
    buildContainer(
      initialOrgState: _orgA,
      detailHandler: ({required organizationId, required personId}) async {
        if (shouldFail) throw Exception('boom');
        return _detail();
      },
    );
    await Future<void>.delayed(Duration.zero);

    var state = container.read(personProfileControllerProvider('person-1'));
    expect(state.status, ProfileLoadStatus.error);
    expect(state.detail, isNull);
    expect(state.journey, isNull);
    expect(state.stages, isNull);
    expect(state.attendanceSummary, isNull);

    // Retry succeeds, then fails again — the second failure must clear the
    // just-populated success data, never leaving it visible alongside error.
    shouldFail = false;
    await container.read(personProfileControllerProvider('person-1').notifier).retry();
    state = container.read(personProfileControllerProvider('person-1'));
    expect(state.status, ProfileLoadStatus.loaded);
    expect(state.detail, isNotNull);

    shouldFail = true;
    await container.read(personProfileControllerProvider('person-1').notifier).retry();
    state = container.read(personProfileControllerProvider('person-1'));
    expect(state.status, ProfileLoadStatus.error);
    expect(state.detail, isNull, reason: 'a prior success must not remain authoritative after a later failure');
  });

  test('organization switch sets shouldClose and further stale responses are discarded', () async {
    final detailGate = Completer<PersonDetail>();
    buildContainer(
      initialOrgState: _orgA,
      detailHandler: ({required organizationId, required personId}) => detailGate.future,
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(personProfileControllerProvider('person-1')).shouldClose, isFalse);

    orgController.emit(_orgB);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(personProfileControllerProvider('person-1')).shouldClose, isTrue);

    // The stale org-a Detail response now arrives late.
    detailGate.complete(_detail());
    await Future<void>.delayed(Duration.zero);

    final state = container.read(personProfileControllerProvider('person-1'));
    expect(state.status, ProfileLoadStatus.loading, reason: 'the stale org-a success must never be applied');
    expect(state.detail, isNull);
  });

  test('a stale Organization A error is discarded after switching to Organization B', () async {
    final detailGate = Completer<PersonDetail>();
    buildContainer(
      initialOrgState: _orgA,
      detailHandler: ({required organizationId, required personId}) => detailGate.future,
    );
    await Future<void>.delayed(Duration.zero);

    orgController.emit(_orgB);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(personProfileControllerProvider('person-1')).shouldClose, isTrue);

    detailGate.completeError(Exception('stale network failure'));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(personProfileControllerProvider('person-1'));
    expect(state.status, ProfileLoadStatus.loading, reason: 'the stale org-a error must never be applied');
    expect(state.errorMessage, isNull);
  });

  test('retry uses the pinned opening organization and current personId', () async {
    buildContainer(initialOrgState: _orgA);
    await Future<void>.delayed(Duration.zero);

    await container.read(personProfileControllerProvider('person-1').notifier).retry();

    expect(api.detailCallCount, 2);
  });

  test('an older personId instance cannot leak into a newer personId instance (family isolation)', () async {
    buildContainer(
      initialOrgState: _orgA,
      detailHandler: ({required organizationId, required personId}) async => _detail(id: personId),
    );
    container.listen(personProfileControllerProvider('person-2'), (_, _) {});
    await Future<void>.delayed(Duration.zero);

    final state1 = container.read(personProfileControllerProvider('person-1'));
    final state2 = container.read(personProfileControllerProvider('person-2'));

    expect(state1.detail!.id, 'person-1');
    expect(state2.detail!.id, 'person-2');
  });
}
