import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/people_screen.dart';

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
  return ProviderScope(
    overrides: [
      peopleApiProvider.overrideWithValue(_FakePeopleApi(page)),
      organizationContextControllerProvider.overrideWith(() => _FakeOrganizationContextController(_activeOrg)),
    ],
    child: const MaterialApp(home: PeopleScreen()),
  );
}

void main() {
  testWidgets('renders header, search field, and the exact All/Active/Inactive chips only', (
    WidgetTester tester,
  ) async {
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

    expect(find.text('Add Person'), findsNothing);
    expect(find.text('Add First Person'), findsNothing);
    expect(find.text('Import People'), findsNothing);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();
    expect(find.text('People'), findsOneWidget, reason: 'tapping a row must not navigate anywhere yet');
  });

  testWidgets('renders the approved empty state with no Add Person/Import destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const PeoplePage(people: [], nextCursor: null)));
    await tester.pumpAndSettle();

    expect(find.text('No people yet.'), findsOneWidget);
    expect(find.text('Start building your community by adding your first person.'), findsOneWidget);
    expect(find.text('Add First Person'), findsNothing);
    expect(find.text('Import People'), findsNothing);
    expect(find.text('Coming soon'), findsNothing);
  });
}
