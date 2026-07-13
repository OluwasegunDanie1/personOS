import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/people_screen.dart';

PersonSummary _person({
  required String id,
  required String firstName,
  required String lastName,
  String? email,
  String? phone,
  PersonStatus status = PersonStatus.active,
  String? avatarUrl,
  JourneyStageSummary? currentJourneyStage,
  LastAttendanceSummary? lastAttendance,
}) => PersonSummary(
  id: id,
  firstName: firstName,
  lastName: lastName,
  email: email,
  phone: phone,
  status: status,
  avatarUrl: avatarUrl,
  joinedAt: _joinedAt,
  currentJourneyStage: currentJourneyStage,
  lastAttendance: lastAttendance,
);

final _joinedAt = DateTime.utc(2026, 1, 1);

class _FakePeopleApi extends PeopleApi {
  _FakePeopleApi(this._page) : super(Dio());

  final PeoplePage _page;

  @override
  Future<PeoplePage> list({
    required String organizationId,
    String? cursor,
    String? search,
    PersonStatus? status,
    int? limit,
  }) async => _page;
}

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController(this._state);

  final OrganizationContextState _state;

  @override
  OrganizationContextState build() => _state;
}

const _activeOrg = OrganizationContextActive(
  organizations: [OrganizationSummary(id: 'org-1', name: 'org-1', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner'))],
  selectedOrganizationId: 'org-1',
);

Widget _wrap(PeoplePage page) {
  final router = GoRouter(
    initialLocation: '/people',
    routes: [
      GoRoute(path: '/people', builder: (context, state) => const PeopleScreen()),
      GoRoute(path: '/people/add', builder: (context, state) => const Scaffold(body: Text('Add Person Screen'))),
    ],
  );

  return ProviderScope(
    overrides: [
      peopleApiProvider.overrideWithValue(_FakePeopleApi(page)),
      organizationContextControllerProvider.overrideWith(() => _FakeOrganizationContextController(_activeOrg)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('renders header, search field, exact chips, and the Add Person action', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        PeoplePage(
          people: [
            PersonSummary(
              id: 'p1',
              firstName: 'Ada',
              lastName: 'Lovelace',
              email: 'ada@example.com',
              phone: null,
              status: PersonStatus.active,
              avatarUrl: null,
              joinedAt: _joinedAt,
            ),
          ],
          nextCursor: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('People'), findsOneWidget);
    expect(find.text('Manage everyone in your organization.'), findsOneWidget);
    expect(find.text('Search people...'), findsOneWidget);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);

    for (final legacy in ['Visitors', 'Members', 'Volunteers', 'Leaders']) {
      expect(find.text(legacy), findsNothing);
    }

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('null'), findsNothing);

    expect(find.text('Import People'), findsNothing);
    expect(find.text('Add First Person'), findsNothing);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();
    expect(find.text('People'), findsOneWidget, reason: 'tapping a row must not navigate anywhere yet');

    // Floating (bottom-right, above bottom nav), not full-width: an
    // extended FAB with a person-add icon and "Add Person" label.
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    expect(find.descendant(of: fab, matching: find.text('Add Person')), findsOneWidget);
    expect(find.descendant(of: fab, matching: find.byIcon(Icons.person_add_outlined)), findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(find.text('Add Person Screen'), findsOneWidget, reason: 'the FAB must push /people/add');
  });

  testWidgets('renders the approved empty state with Add First Person and no Import People', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const PeoplePage(people: [], nextCursor: null)));
    await tester.pumpAndSettle();

    expect(find.text('No people yet.'), findsOneWidget);
    expect(find.text('Start building your community by adding your first person.'), findsOneWidget);
    expect(find.text('Import People'), findsNothing);
    expect(find.text('Coming soon'), findsNothing);

    expect(find.text('Add First Person'), findsOneWidget);
    await tester.tap(find.text('Add First Person'));
    await tester.pumpAndSettle();
    expect(find.text('Add Person Screen'), findsOneWidget, reason: 'Add First Person must push /people/add');
  });

  group('populated person card composition', () {
    testWidgets('renders name, journey badge, phone-before-email order, and the attendance block together', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PeoplePage(
            people: [
              _person(
                id: 'p1',
                firstName: 'Ada',
                lastName: 'Lovelace',
                email: 'ada@example.com',
                phone: '5551234567',
                currentJourneyStage: const JourneyStageSummary(id: 'stage-1', name: 'Connected Guest'),
                lastAttendance: LastAttendanceSummary(checkedInAt: DateTime.now().toUtc()),
              ),
            ],
            nextCursor: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('AL'), findsOneWidget, reason: 'initials fallback since avatarUrl is null');
      expect(find.text('Connected Guest'), findsOneWidget);
      expect(find.text('Last attendance'), findsOneWidget);
      expect(find.textContaining('Today,'), findsOneWidget);

      final phoneY = tester.getTopLeft(find.text('5551234567')).dy;
      final emailY = tester.getTopLeft(find.text('ada@example.com')).dy;
      expect(phoneY, lessThan(emailY), reason: 'Phone must render above Email');
    });

    testWidgets('omits journey badge, attendance block, phone row, and email row when all are absent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _wrapPage([_person(id: 'p1', firstName: 'Grace', lastName: 'Hopper')]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('Last attendance'), findsNothing);
      expect(find.byIcon(Icons.phone_outlined), findsNothing);
      expect(find.byIcon(Icons.mail_outline), findsNothing);
      for (final placeholder in ['Never', 'No attendance', '—', 'N/A']) {
        expect(find.text(placeholder), findsNothing);
      }
    });

    testWidgets('no attendance block renders when lastAttendance is null (no placeholder)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(_wrapPage([_person(id: 'p1', firstName: 'Grace', lastName: 'Hopper')])));
      await tester.pumpAndSettle();

      expect(find.text('Last attendance'), findsNothing);
    });

    testWidgets("today's attendance formats as Today, h:mm AM/PM", (WidgetTester tester) async {
      final now = DateTime.now();
      final today9am = DateTime(now.year, now.month, now.day, 9, 0).toUtc();

      await tester.pumpWidget(
        _wrap(
          _wrapPage([
            _person(
              id: 'p1',
              firstName: 'Ada',
              lastName: 'Lovelace',
              lastAttendance: LastAttendanceSummary(checkedInAt: today9am),
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Today,'), findsOneWidget);
      for (final raw in ['T00:00', 'Z', '+00:00']) {
        expect(find.textContaining(raw), findsNothing);
      }
    });

    testWidgets('non-today attendance formats as MMM d, yyyy', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          _wrapPage([
            _person(
              id: 'p1',
              firstName: 'Ada',
              lastName: 'Lovelace',
              lastAttendance: LastAttendanceSummary(checkedInAt: DateTime.utc(2025, 5, 25, 9, 0)),
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('May 25, 2025'), findsOneWidget);
      expect(find.textContaining('Today,'), findsNothing);
    });

    testWidgets('journey badge preserves the organization-configured name exactly (no transformation)', (
      WidgetTester tester,
    ) async {
      const rawName = 'somos FAMILIA — etapa 3';
      await tester.pumpWidget(
        _wrap(
          _wrapPage([
            _person(
              id: 'p1',
              firstName: 'Ada',
              lastName: 'Lovelace',
              currentJourneyStage: const JourneyStageSummary(id: 'stage-1', name: rawName),
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(rawName), findsOneWidget);
    });

    testWidgets('Person.status is not rendered as a second badge/dot on the card', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          _wrapPage([
            _person(
              id: 'p1',
              firstName: 'Grace',
              lastName: 'Hopper',
              status: PersonStatus.inactive,
              currentJourneyStage: const JourneyStageSummary(id: 'stage-1', name: 'Connected Guest'),
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connected Guest'), findsOneWidget);
      expect(find.text('INACTIVE'), findsNothing);
      expect(find.text('ACTIVE'), findsNothing);
    });

    testWidgets('no avatarUrl shows initials fallback', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(_wrapPage([_person(id: 'p1', firstName: 'Ada', lastName: 'Lovelace')])));
      await tester.pumpAndSettle();

      expect(find.text('AL'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('no usable initials shows the generic person icon fallback', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(_wrapPage([_person(id: 'p1', firstName: '', lastName: '')])));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('a non-empty avatarUrl attempts the network image path', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          _wrapPage([
            _person(id: 'p1', firstName: 'Ada', lastName: 'Lovelace', avatarUrl: 'https://example.test/ada.png'),
          ]),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, 'https://example.test/ada.png');
    });

    testWidgets('an unreachable avatarUrl falls back to initials without a broken-image glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _wrapPage([
            _person(id: 'p1', firstName: 'Ada', lastName: 'Lovelace', avatarUrl: 'https://invalid.test/ada.png'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no trailing three-dot icon renders, and the card does not navigate on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(_wrapPage([_person(id: 'p1', firstName: 'Ada', lastName: 'Lovelace')])));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsNothing);

      await tester.tap(find.text('Ada Lovelace'));
      await tester.pumpAndSettle();

      expect(find.text('People'), findsOneWidget, reason: 'the card must not push /people/:id or any route');
    });
  });
}

PeoplePage _wrapPage(List<PersonSummary> people) => PeoplePage(people: people, nextCursor: null);
