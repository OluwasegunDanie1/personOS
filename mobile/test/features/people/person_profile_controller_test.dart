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
typedef _FollowUpsHandler = Future<FollowUpListResult> Function({
  required String organizationId,
  required String personId,
});

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi({
    required this.detailHandler,
    required this.journeyHandler,
    required this.stagesHandler,
    required this.summaryHandler,
    required this.followUpsHandler,
  }) : super(Dio());

  _DetailHandler detailHandler;
  _JourneyHandler journeyHandler;
  _StagesHandler stagesHandler;
  _SummaryHandler summaryHandler;
  _FollowUpsHandler followUpsHandler;

  int detailCallCount = 0;
  int journeyCallCount = 0;
  int stagesCallCount = 0;
  int summaryCallCount = 0;
  int followUpsCallCount = 0;

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

  @override
  Future<FollowUpListResult> personFollowUps({required String organizationId, required String personId}) {
    followUpsCallCount++;
    return followUpsHandler(organizationId: organizationId, personId: personId);
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
const _emptyFollowUps = FollowUpListResult(followUps: [], nextCursor: null);

FollowUpPersonRef _personRef(String id) => FollowUpPersonRef(id: id, firstName: 'Ada', lastName: 'Lovelace');

FollowUpSummary _followUp(
  String id, {
  FollowUpStatus status = FollowUpStatus.pending,
  String title = 'Follow up',
}) => FollowUpSummary(
  id: id,
  title: title,
  description: null,
  dueDate: null,
  status: status,
  completedAt: null,
  person: _personRef('person-1'),
  assignedTo: null,
);

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
    _FollowUpsHandler? followUpsHandler,
  }) {
    api = _ScriptedPeopleApi(
      detailHandler: detailHandler ?? ({required organizationId, required personId}) async => _detail(),
      journeyHandler: journeyHandler ?? ({required organizationId, required personId}) async => _journey,
      stagesHandler: stagesHandler ?? ({required organizationId}) async => _stages,
      summaryHandler: summaryHandler ?? ({required organizationId, required personId}) async => _summary,
      followUpsHandler: followUpsHandler ?? ({required organizationId, required personId}) async => _emptyFollowUps,
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

  group('refreshDetail (Product Task 047: narrow Detail-only refresh after Edit Person success)', () {
    test('performs a real new GET Detail request and applies the refreshed value as Profile authority', () async {
      var callCount = 0;
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async {
          callCount++;
          if (callCount == 1) return _detail();
          return _detail(id: 'refreshed');
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(api.detailCallCount, 1);

      await container.read(personProfileControllerProvider('person-1').notifier).refreshDetail();

      expect(api.detailCallCount, 2);
      expect(container.read(personProfileControllerProvider('person-1')).detail!.id, 'refreshed');
    });

    test('never touches journey/stages/attendanceSummary/Follow-up state', () async {
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) async =>
            FollowUpListResult(followUps: [_followUp('f1')], nextCursor: null),
      );
      await Future<void>.delayed(Duration.zero);
      expect(api.journeyCallCount, 1);
      expect(api.stagesCallCount, 1);
      expect(api.summaryCallCount, 1);
      expect(api.followUpsCallCount, 1);

      await container.read(personProfileControllerProvider('person-1').notifier).refreshDetail();

      expect(api.journeyCallCount, 1, reason: 'refreshDetail must never re-trigger a Journey reload');
      expect(api.stagesCallCount, 1, reason: 'refreshDetail must never re-trigger a Journey Stages reload');
      expect(api.summaryCallCount, 1, reason: 'refreshDetail must never re-trigger an Attendance Summary reload');
      expect(api.followUpsCallCount, 1, reason: 'refreshDetail must never re-trigger a Follow-up reload');

      final state = container.read(personProfileControllerProvider('person-1'));
      expect(state.journey, isNotNull);
      expect(state.stages, isNotNull);
      expect(state.attendanceSummary, isNotNull);
      expect(state.followUps, isNotEmpty);
    });

    test('a stale Organization A refreshDetail success is discarded after switching to Organization B', () async {
      final refreshGate = Completer<PersonDetail>();
      var callCount = 0;
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) {
          callCount++;
          if (callCount == 1) return Future.value(_detail());
          return refreshGate.future;
        },
      );
      await Future<void>.delayed(Duration.zero);

      final refreshFuture = container.read(personProfileControllerProvider('person-1').notifier).refreshDetail();

      orgController.emit(_orgB);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(personProfileControllerProvider('person-1')).shouldClose, isTrue);

      refreshGate.complete(_detail(id: 'stale-refreshed'));
      await refreshFuture;

      final state = container.read(personProfileControllerProvider('person-1'));
      expect(
        state.detail!.id,
        'person-1',
        reason: 'the stale org-a refreshDetail success must never become authoritative after switching to org-b',
      );
    });

    test('a refreshDetail failure leaves the last known-good Detail in place rather than fabricating or clearing it', () async {
      var callCount = 0;
      buildContainer(
        initialOrgState: _orgA,
        detailHandler: ({required organizationId, required personId}) async {
          callCount++;
          if (callCount == 1) return _detail();
          throw Exception('refresh failed');
        },
      );
      await Future<void>.delayed(Duration.zero);

      await container.read(personProfileControllerProvider('person-1').notifier).refreshDetail();

      final state = container.read(personProfileControllerProvider('person-1'));
      expect(state.status, ProfileLoadStatus.loaded, reason: 'a failed background refresh must not erase a valid Profile');
      expect(state.detail, isNotNull);
    });
  });

  group('Profile Follow-up region', () {
    test('loads Follow-ups for the current person and selected organization using person_id, dueDate_asc, limit 100', () async {
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) async =>
            FollowUpListResult(followUps: [_followUp('f1')], nextCursor: null),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(personProfileControllerProvider('person-1'));
      expect(state.followUpStatus, FollowUpRegionStatus.loaded);
      expect(state.followUps!.single.id, 'f1');
      expect(api.followUpsCallCount, 1);
    });

    test('excludes COMPLETED records; retains PENDING and IN_PROGRESS', () async {
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) async => FollowUpListResult(
          followUps: [
            _followUp('f-pending', status: FollowUpStatus.pending),
            _followUp('f-in-progress', status: FollowUpStatus.inProgress),
            _followUp('f-completed', status: FollowUpStatus.completed),
          ],
          nextCursor: null,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final ids = container.read(personProfileControllerProvider('person-1')).followUps!.map((f) => f.id);
      expect(ids, containsAll(['f-pending', 'f-in-progress']));
      expect(ids.contains('f-completed'), isFalse);
    });

    test('retains hasMore when nextCursor is non-null', () async {
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) async =>
            FollowUpListResult(followUps: [_followUp('f1')], nextCursor: 'cursor-1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(personProfileControllerProvider('person-1')).followUpsHasMore, isTrue);
    });

    test('hasMore is false when nextCursor is null', () async {
      buildContainer(initialOrgState: _orgA);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(personProfileControllerProvider('person-1')).followUpsHasMore, isFalse);
    });

    test('Follow-up loading is region-specific and does not block Profile core from loading', () async {
      final followUpGate = Completer<FollowUpListResult>();
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) => followUpGate.future,
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(personProfileControllerProvider('person-1'));
      expect(state.status, ProfileLoadStatus.loaded, reason: 'core must load independently of the Follow-up region');
      expect(state.followUpStatus, FollowUpRegionStatus.loading);

      followUpGate.complete(const FollowUpListResult(followUps: [], nextCursor: null));
      await Future<void>.delayed(Duration.zero);
    });

    test('a Follow-up failure is region-specific and does not erase valid Profile core data', () async {
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) async => throw Exception('boom'),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(personProfileControllerProvider('person-1'));
      expect(state.followUpStatus, FollowUpRegionStatus.error);
      expect(state.followUpErrorMessage, isNotNull);
      expect(state.status, ProfileLoadStatus.loaded, reason: 'core Detail/Journey/Stages/Attendance must remain valid');
      expect(state.detail, isNotNull);
      expect(state.journey, isNotNull);
      expect(state.stages, isNotNull);
      expect(state.attendanceSummary, isNotNull);
    });

    test('a stale Organization A Follow-up success is discarded after switching to Organization B', () async {
      final followUpGate = Completer<FollowUpListResult>();
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) => followUpGate.future,
      );
      await Future<void>.delayed(Duration.zero);

      orgController.emit(_orgB);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(personProfileControllerProvider('person-1')).shouldClose, isTrue);

      followUpGate.complete(FollowUpListResult(followUps: [_followUp('stale-f1')], nextCursor: null));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(personProfileControllerProvider('person-1'));
      expect(state.followUpStatus, FollowUpRegionStatus.loading, reason: 'the stale org-a success must never apply');
      expect(state.followUps, isNull);
    });

    test('a stale Organization A Follow-up error is discarded after switching to Organization B', () async {
      final followUpGate = Completer<FollowUpListResult>();
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) => followUpGate.future,
      );
      await Future<void>.delayed(Duration.zero);

      orgController.emit(_orgB);
      await Future<void>.delayed(Duration.zero);

      followUpGate.completeError(Exception('stale network failure'));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(personProfileControllerProvider('person-1'));
      expect(state.followUpStatus, FollowUpRegionStatus.loading, reason: 'the stale org-a error must never apply');
      expect(state.followUpErrorMessage, isNull);
    });

    test('an older Follow-up refresh cannot overwrite newer Follow-up state', () async {
      final staleGate = Completer<FollowUpListResult>();
      // Deterministic request-entry signal (Product Task 037B's established
      // convention): proves the initial (generation 1) load has genuinely
      // reached the fake API and is gated, rather than racing two async
      // chains against each other via implicit microtask-ordering timing.
      final initialEntered = Completer<void>();
      var callIndex = 0;
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) {
          callIndex++;
          if (callIndex == 1) {
            if (!initialEntered.isCompleted) initialEntered.complete();
            return staleGate.future;
          }
          return Future.value(FollowUpListResult(followUps: [_followUp('fresh')], nextCursor: null));
        },
      );

      await initialEntered.future;

      final notifier = container.read(personProfileControllerProvider('person-1').notifier);
      await notifier.refreshFollowUps();

      expect(
        container.read(personProfileControllerProvider('person-1')).followUps!.map((f) => f.id),
        ['fresh'],
        reason: 'the newer refresh must be authoritative before the stale generation-1 response is released',
      );

      staleGate.complete(FollowUpListResult(followUps: [_followUp('stale')], nextCursor: null));
      await Future<void>.delayed(Duration.zero);

      final ids = container.read(personProfileControllerProvider('person-1')).followUps!.map((f) => f.id);
      expect(
        ids,
        ['fresh'],
        reason: 'the stale generation-1 response must not overwrite the newer refresh state',
      );
    });

    test('refreshFollowUps performs a real new GET request (the mechanism Create Follow-up success uses)', () async {
      var callCount = 0;
      buildContainer(
        initialOrgState: _orgA,
        followUpsHandler: ({required organizationId, required personId}) async {
          callCount++;
          if (callCount == 1) return const FollowUpListResult(followUps: [], nextCursor: null);
          return FollowUpListResult(followUps: [_followUp('created-1')], nextCursor: null);
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(personProfileControllerProvider('person-1')).followUps, isEmpty);

      await container.read(personProfileControllerProvider('person-1').notifier).refreshFollowUps();

      expect(api.followUpsCallCount, 2);
      expect(container.read(personProfileControllerProvider('person-1')).followUps!.single.id, 'created-1');
    });
  });
}
