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
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/person_profile_screen.dart';

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
  String? avatarUrl,
  PersonStatus status = PersonStatus.active,
  JourneyStageSummary? currentJourneyStage,
  String? email = 'ada@example.com',
  String? phone = '+1234567890',
  PersonGender? gender,
  DateTime? dateOfBirth,
  String? address,
}) => PersonDetail(
  id: id,
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: email,
  phone: phone,
  status: status,
  avatarUrl: avatarUrl,
  joinedAt: DateTime.utc(2026, 1, 1),
  tags: const [],
  currentJourneyStage: currentJourneyStage,
  gender: gender,
  dateOfBirth: dateOfBirth,
  address: address,
);

const _emptyJourney = PersonJourneyView(currentStage: null, history: []);
const _emptyStages = <JourneyStageListEntry>[];
const _zeroSummary = AttendanceSummary(totalCount: 0, currentMonthCount: 0);
const _emptyFollowUps = FollowUpListResult(followUps: [], nextCursor: null);

class _Harness {
  _Harness(this.router, this.orgController, this.api);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
  final _ScriptedPeopleApi api;
}

Future<_Harness> _pumpProfileScreen(
  WidgetTester tester, {
  required _DetailHandler detailHandler,
  _JourneyHandler? journeyHandler,
  _StagesHandler? stagesHandler,
  _SummaryHandler? summaryHandler,
  _FollowUpsHandler? followUpsHandler,
  OrganizationContextState initialOrg = _orgA,
  bool settle = true,
}) async {
  final api = _ScriptedPeopleApi(
    detailHandler: detailHandler,
    journeyHandler: journeyHandler ?? ({required organizationId, required personId}) async => _emptyJourney,
    stagesHandler: stagesHandler ?? ({required organizationId}) async => _emptyStages,
    summaryHandler: summaryHandler ?? ({required organizationId, required personId}) async => _zeroSummary,
    followUpsHandler: followUpsHandler ?? ({required organizationId, required personId}) async => _emptyFollowUps,
  );
  final orgController = _FakeOrganizationContextController(initialOrg);

  final router = GoRouter(
    initialLocation: '/people',
    routes: [
      GoRoute(
        path: '/people/:personId',
        builder: (context, state) => PersonProfileScreen(personId: state.pathParameters['personId']!),
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
  router.push('/people/p1');
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A gated/never-completing handler leaves a CircularProgressIndicator's
    // indeterminate animation running forever, which pumpAndSettle cannot
    // settle (it would time out); a single pump renders the current frame.
    await tester.pump();
  }
  return _Harness(router, orgController, api);
}

void main() {
  testWidgets('renders real Person Detail values: name, phone, email, gender, date of birth, address', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(
        gender: PersonGender.female,
        dateOfBirth: DateTime.utc(1990, 12, 31),
        address: '221B Baker Street',
      ),
    );

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('+1234567890'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('December 31, 1990'), findsOneWidget);
    expect(find.text('221B Baker Street'), findsOneWidget);
  });

  testWidgets('ACTIVE is rendered truthfully, never relabelled as Member/Active Member', (WidgetTester tester) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async =>
          _fullDetail(status: PersonStatus.active),
    );

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Member'), findsNothing);
    expect(find.text('Active Member'), findsNothing);
    expect(find.text('Visitor'), findsNothing);
    expect(find.text('Volunteer'), findsNothing);
    expect(find.text('Leader'), findsNothing);
  });

  testWidgets('INACTIVE is rendered truthfully', (WidgetTester tester) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async =>
          _fullDetail(status: PersonStatus.inactive),
    );

    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('renders the real organization-configured current Journey Stage name in the pill, never hardcoded', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(
        currentJourneyStage: const JourneyStageSummary(id: 'stage-9', name: 'somos FAMILIA — etapa 3'),
      ),
    );

    expect(find.text('Journey: somos FAMILIA — etapa 3'), findsOneWidget);
  });

  testWidgets('the Journey Stage stepper renders only real ordered stages, never the illustrative mock names', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
      stagesHandler: ({required organizationId}) async => const [
        JourneyStageListEntry(id: 's1', name: 'Newcomer', position: 1),
        JourneyStageListEntry(id: 's2', name: 'Regular Attendee', position: 2),
      ],
      journeyHandler: ({required organizationId, required personId}) async => const PersonJourneyView(
        currentStage: PersonJourneyCurrentStage(id: 's1', name: 'Newcomer', position: 1),
        history: [],
      ),
    );

    expect(find.text('Newcomer'), findsOneWidget);
    expect(find.text('Regular Attendee'), findsOneWidget);
    for (final illustrative in [
      'Visitor',
      'First Visit',
      'Second Visit',
      'Follow-up',
      'New Member',
      'Active Member',
      'Volunteer',
      'Leader',
    ]) {
      expect(find.text(illustrative), findsNothing);
    }
  });

  testWidgets('the current stage is visually distinguished from future/unreached stages', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
      stagesHandler: ({required organizationId}) async => const [
        JourneyStageListEntry(id: 's1', name: 'Stage A', position: 1),
        JourneyStageListEntry(id: 's2', name: 'Stage B', position: 2),
        JourneyStageListEntry(id: 's3', name: 'Stage C', position: 3),
      ],
      journeyHandler: ({required organizationId, required personId}) async => const PersonJourneyView(
        currentStage: PersonJourneyCurrentStage(id: 's2', name: 'Stage B', position: 2),
        history: [],
      ),
    );

    // Reached (checked) = position <= currentPosition, so both position 1
    // (completed) and position 2 (current) render checked; only position 3
    // (future/unreached) renders unchecked.
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2), reason: 'positions 1 and 2 are reached (1 completed, 2 current)');
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget, reason: 'position 3 is future/unreached');
  });

  testWidgets('a null current Journey Stage renders no reached/current stage, never a fabricated one', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
      stagesHandler: ({required organizationId}) async => const [
        JourneyStageListEntry(id: 's1', name: 'Stage A', position: 1),
        JourneyStageListEntry(id: 's2', name: 'Stage B', position: 2),
      ],
    );

    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
    expect(find.textContaining('Journey:'), findsNothing, reason: 'no Journey pill when currentJourneyStage is null');
  });

  testWidgets('renders real Attendance Summary counts using the exact frozen wording', (WidgetTester tester) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
      summaryHandler: ({required organizationId, required personId}) async =>
          const AttendanceSummary(totalCount: 24, currentMonthCount: 6),
    );

    expect(find.textContaining('Total 24 times'), findsOneWidget);
    expect(find.textContaining('This month: 6 times'), findsOneWidget);
  });

  testWidgets('Notes renders as a structural, non-interactive row with no fabricated count', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

    expect(find.text('Notes'), findsOneWidget);
    for (final fakeCount in ['0 notes', '1 note', '2 notes', '3 notes']) {
      expect(find.text(fakeCount), findsNothing);
    }
  });

  testWidgets('Groups and Recent Activity are omitted entirely (Upcoming Follow-ups is real as of Product Task 043)', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

    expect(find.text('Groups'), findsNothing);
    expect(find.text('Recent Activity'), findsNothing);
  });

  testWidgets('Call/Message/Email/More are visible but non-interactive', (WidgetTester tester) async {
    await _pumpProfileScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget, reason: 'unique to the action row; Personal Information has no Message field');
    // 'Email' also appears as a Personal Information field label alongside
    // the action-row item, since this harness's Person has a real email.
    expect(find.text('Email'), findsNWidgets(2));
    expect(find.text('More'), findsOneWidget);

    // No InkWell/GestureDetector/ElevatedButton wraps these icons — tapping
    // must have no effect (no navigation, no exception, no state change).
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.text('Message'), findsOneWidget, reason: 'tapping Message must not navigate away from Profile');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create Follow-up (Product Task 043) and Edit Person (Product Task 047) are both interactive', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

    final createButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create Follow-up'));
    expect(createButton.onPressed, isNotNull);

    final editButton = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Edit Person'));
    expect(editButton.onPressed, isNotNull);
  });

  testWidgets('no green presence dot is rendered', (WidgetTester tester) async {
    await _pumpProfileScreen(tester, detailHandler: ({required organizationId, required personId}) async => _fullDetail());

    // The only production usage of this exact green is the removed presence
    // dot; nothing in the current Profile composition uses it.
    final greenContainers = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          (widget.decoration as BoxDecoration).color == const Color(0xFF16A34A),
    );
    expect(greenContainers, findsNothing);
  });

  testWidgets('null phone/email/gender/dateOfBirth/address are omitted, never fabricated', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async =>
          _fullDetail(email: null, phone: null, gender: null, dateOfBirth: null, address: null),
    );

    expect(find.text('No additional details on file.'), findsOneWidget);
    for (final placeholder in ['null', 'N/A', '—', 'Unknown']) {
      expect(find.text(placeholder), findsNothing);
    }
  });

  testWidgets('back returns to People', (WidgetTester tester) async {
    final harness = await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
    expect(harness.router.state.uri.toString(), '/people');
  });

  testWidgets('Profile is outside the bottom-navigation shell; People shows the shell nav bar', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
    );

    expect(find.byType(NavigationBar), findsNothing, reason: 'Profile must have no bottom navigation bar');
  });

  testWidgets('organization switch while Profile is open closes it to /people', (WidgetTester tester) async {
    final harness = await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
    );

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
    expect(harness.router.state.uri.toString(), '/people');
  });

  testWidgets('a stale Organization A Detail response does not render after switching to Organization B', (
    WidgetTester tester,
  ) async {
    final gate = Completer<PersonDetail>();
    final harness = await _pumpProfileScreen(
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
    expect(find.text('Ada Lovelace'), findsNothing);
  });

  testWidgets('a truthful, retryable error state is shown on load failure and no stale data is visible', (
    WidgetTester tester,
  ) async {
    await _pumpProfileScreen(
      tester,
      detailHandler: ({required organizationId, required personId}) async => throw Exception('network down'),
    );

    expect(find.text('Could not load this person.'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  group('Upcoming Follow-ups region (Product Task 043)', () {
    FollowUpPersonRef personRef() => const FollowUpPersonRef(id: 'p1', firstName: 'Ada', lastName: 'Lovelace');

    FollowUpSummary followUp(
      String id, {
      FollowUpStatus status = FollowUpStatus.pending,
      String title = 'Call to check in',
      DateTime? dueDate,
      FollowUpPersonRef? assignedTo,
    }) => FollowUpSummary(
      id: id,
      title: title,
      description: null,
      dueDate: dueDate,
      status: status,
      completedAt: null,
      person: personRef(),
      assignedTo: assignedTo,
    );

    testWidgets('renders the Upcoming Follow-ups region with a real PENDING follow-up', (WidgetTester tester) async {
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async =>
            FollowUpListResult(followUps: [followUp('f1', title: 'Schedule a home visit')], nextCursor: null),
      );

      expect(find.text('Upcoming Follow-ups'), findsOneWidget);
      expect(find.text('Schedule a home visit'), findsOneWidget);
    });

    testWidgets('renders a real IN_PROGRESS follow-up', (WidgetTester tester) async {
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async => FollowUpListResult(
          followUps: [followUp('f1', status: FollowUpStatus.inProgress, title: 'Follow up on donation')],
          nextCursor: null,
        ),
      );

      expect(find.text('Follow up on donation'), findsOneWidget);
    });

    testWidgets('a COMPLETED follow-up does not render; no invented UPCOMING status exists', (
      WidgetTester tester,
    ) async {
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async => FollowUpListResult(
          followUps: [
            followUp('f-pending', title: 'Pending item'),
            followUp('f-completed', status: FollowUpStatus.completed, title: 'Completed item'),
          ],
          nextCursor: null,
        ),
      );

      expect(find.text('Pending item'), findsOneWidget);
      expect(find.text('Completed item'), findsNothing);
      expect(find.text('UPCOMING'), findsNothing);
    });

    testWidgets('no fake count is shown, and hasMore never produces an exhaustive total claim', (
      WidgetTester tester,
    ) async {
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async =>
            FollowUpListResult(followUps: [followUp('f1')], nextCursor: 'cursor-1'),
      );

      for (final fakeCount in ['1 scheduled follow-up', '2 scheduled follow-ups']) {
        expect(find.textContaining(fakeCount), findsNothing);
      }
      expect(find.text('More follow-ups exist for this person.'), findsOneWidget);
    });

    testWidgets('due date renders when present and is omitted when null (never fabricated)', (
      WidgetTester tester,
    ) async {
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async => FollowUpListResult(
          followUps: [
            followUp('f-with-date', title: 'Has a date', dueDate: DateTime.utc(2026, 8, 2, 9)),
            followUp('f-without-date', title: 'No date'),
          ],
          nextCursor: null,
        ),
      );

      expect(find.textContaining('Due'), findsOneWidget, reason: 'only the follow-up with a real dueDate shows one');
    });

    testWidgets('assignee renders when present and is omitted when null (never fabricated Unassigned)', (
      WidgetTester tester,
    ) async {
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async => FollowUpListResult(
          followUps: [
            followUp(
              'f-assigned',
              title: 'Assigned item',
              assignedTo: const FollowUpPersonRef(id: 'u1', firstName: 'Grace', lastName: 'Hopper'),
            ),
            followUp('f-unassigned', title: 'Unassigned item'),
          ],
          nextCursor: null,
        ),
      );

      expect(find.text('Assigned to Grace Hopper'), findsOneWidget);
      expect(find.text('Unassigned'), findsNothing);
    });

    testWidgets('Follow-up rows are non-interactive: no chevron, no completion control, no detail navigation', (
      WidgetTester tester,
    ) async {
      // A tall viewport so the tap target is reachable without scrolling
      // (mirrors add_person_screen_test.dart's convention).
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async =>
            FollowUpListResult(followUps: [followUp('f1', title: 'Tap-test item')], nextCursor: null),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.text('Tap-test item'));
      await tester.pumpAndSettle();

      expect(find.text('Tap-test item'), findsOneWidget, reason: 'tapping a row must not navigate anywhere');
      expect(tester.takeException(), isNull);
    });

    testWidgets('truthful empty state when no non-completed follow-ups are returned', (WidgetTester tester) async {
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async => const FollowUpListResult(
          followUps: [],
          nextCursor: null,
        ),
      );

      expect(find.text('No follow-ups are currently scheduled.'), findsOneWidget);
      expect(find.textContaining('never had'), findsNothing);
    });

    testWidgets('region loading does not replace the rest of Profile', (WidgetTester tester) async {
      final followUpGate = Completer<FollowUpListResult>();
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) => followUpGate.future,
        // The Follow-up region's own CircularProgressIndicator never
        // settles while followUpGate is unresolved, so pumpAndSettle()
        // would hang — pump explicitly instead to drain the (real-timer-
        // free) Detail/Journey/Stages/Attendance microtask chain.
        settle: false,
      );
      await tester.pump();

      // Profile core rendered even while the Follow-up region is still loading.
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Upcoming Follow-ups'), findsOneWidget);

      followUpGate.complete(const FollowUpListResult(followUps: [], nextCursor: null));
      await tester.pumpAndSettle();
    });

    testWidgets('region error does not replace the rest of Profile', (WidgetTester tester) async {
      await _pumpProfileScreen(
        tester,
        detailHandler: ({required organizationId, required personId}) async => _fullDetail(),
        followUpsHandler: ({required organizationId, required personId}) async => throw Exception('boom'),
      );

      expect(find.text('Ada Lovelace'), findsOneWidget, reason: 'Profile core must remain visible');
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Could not load follow-ups.'), findsOneWidget);
    });
  });
}
