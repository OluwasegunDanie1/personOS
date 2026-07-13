import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/people_state_controller.dart';

class _RecordedCall {
  _RecordedCall({required this.organizationId, required this.cursor, required this.search, required this.status});

  final String organizationId;
  final String? cursor;
  final String? search;
  final PersonStatus? status;
}

typedef _Handler =
    Future<PeoplePage> Function({
      required String organizationId,
      String? cursor,
      String? search,
      PersonStatus? status,
      int? limit,
    });

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi(this.handler) : super(Dio());

  _Handler handler;
  final List<_RecordedCall> calls = [];

  @override
  Future<PeoplePage> list({
    required String organizationId,
    String? cursor,
    String? search,
    PersonStatus? status,
    int? limit,
  }) {
    calls.add(_RecordedCall(organizationId: organizationId, cursor: cursor, search: search, status: status));
    return handler(organizationId: organizationId, cursor: cursor, search: search, status: status, limit: limit);
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

PersonSummary _person(String id, {String firstName = 'Ada', String lastName = 'Lovelace'}) => PersonSummary(
  id: id,
  firstName: firstName,
  lastName: lastName,
  email: '$id@example.com',
  phone: null,
  status: PersonStatus.active,
  avatarUrl: null,
  joinedAt: DateTime.utc(2026, 1, 1),
);

Future<PeoplePage> _immediate(List<PersonSummary> people, {String? nextCursor}) async =>
    PeoplePage(people: people, nextCursor: nextCursor);

void main() {
  late _ScriptedPeopleApi api;
  late _FakeOrganizationContextController orgController;
  late ProviderContainer container;

  ProviderContainer buildContainer(OrganizationContextState initialOrgState, _Handler handler) {
    api = _ScriptedPeopleApi(handler);
    orgController = _FakeOrganizationContextController(initialOrgState);
    container = ProviderContainer(
      overrides: [
        peopleApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
    );
    addTearDown(container.dispose);
    // A bare container.read() only recomputes a provider on its *next* read
    // after a watched dependency invalidates it — it does not eagerly
    // re-run build() the moment organizationContextControllerProvider
    // changes. A real ConsumerWidget's ref.watch subscribes and is notified
    // eagerly; container.listen reproduces that same eager-recompute
    // behavior here so the controller's org-switch reaction actually runs
    // without an extra manual read in every test.
    container.listen(peopleDirectoryControllerProvider, (_, _) {});
    return container;
  }

  test('no People request before active organization authority exists', () async {
    buildContainer(const OrganizationContextEmpty(), (
      {required organizationId, cursor, search, status, limit}) => _immediate([]));

    final state = container.read(peopleDirectoryControllerProvider);

    expect(state.status, PeopleLoadStatus.idle);
    expect(api.calls, isEmpty);
  });

  test('active organization initial load populates the directory', () async {
    buildContainer(
      OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'),
      ({required organizationId, cursor, search, status, limit}) => _immediate([_person('p1'), _person('p2')]),
    );

    await Future<void>.delayed(Duration.zero);

    final state = container.read(peopleDirectoryControllerProvider);
    expect(state.status, PeopleLoadStatus.loaded);
    expect(state.people, hasLength(2));
    expect(api.calls.single.organizationId, 'org-a');
    expect(api.calls.single.search, isNull);
    expect(api.calls.single.status, isNull);
  });

  test('search restarts first-page loading and whitespace-only search clears the filter', () async {
    buildContainer(
      OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'),
      ({required organizationId, cursor, search, status, limit}) => _immediate([_person('p1')]),
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(peopleDirectoryControllerProvider.notifier);
    notifier.updateSearch('john');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(container.read(peopleDirectoryControllerProvider).search, 'john');
    expect(api.calls.last.search, 'john');

    notifier.updateSearch('   ');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(container.read(peopleDirectoryControllerProvider).search, '');
    expect(api.calls.last.search, isNull);
  });

  test('status filter resets pagination and preserves current search', () async {
    buildContainer(
      OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'),
      ({required organizationId, cursor, search, status, limit}) =>
          _immediate([_person('p1')], nextCursor: 'cursor-1'),
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(peopleDirectoryControllerProvider.notifier);
    notifier.updateSearch('john');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    notifier.updateStatusFilter(PeopleStatusFilter.active);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(peopleDirectoryControllerProvider);
    expect(state.statusFilter, PeopleStatusFilter.active);
    expect(state.search, 'john');
    expect(api.calls.last.search, 'john');
    expect(api.calls.last.status, PersonStatus.active);
  });

  test('pagination appends and stops when nextCursor is null', () async {
    buildContainer(
      OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'),
      ({required organizationId, cursor, search, status, limit}) {
        if (cursor == null) return _immediate([_person('p1'), _person('p2')], nextCursor: 'cursor-1');
        return _immediate([_person('p3')], nextCursor: null);
      },
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(peopleDirectoryControllerProvider.notifier);
    await notifier.loadNextPage();

    var state = container.read(peopleDirectoryControllerProvider);
    expect(state.people.map((p) => p.id), ['p1', 'p2', 'p3']);
    expect(state.hasMore, isFalse);

    final callsBefore = api.calls.length;
    await notifier.loadNextPage();
    expect(api.calls.length, callsBefore, reason: 'must not request another page once nextCursor is null');
  });

  test('duplicate next-page requests are prevented while one is in flight', () async {
    final gate = Completer<PeoplePage>();
    var pageCallCount = 0;

    buildContainer(OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'), (
      {required organizationId, cursor, search, status, limit}) {
      if (cursor == null) return _immediate([_person('p1')], nextCursor: 'cursor-1');
      pageCallCount++;
      return gate.future;
    });
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(peopleDirectoryControllerProvider.notifier);
    final first = notifier.loadNextPage();
    final second = notifier.loadNextPage();

    gate.complete(PeoplePage(people: [_person('p2')], nextCursor: null));
    await Future.wait([first, second]);

    expect(pageCallCount, 1, reason: 'a second concurrent call must be ignored while one is in flight');
  });

  test('duplicate person ids across pages are not duplicated visibly', () async {
    buildContainer(
      OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'),
      ({required organizationId, cursor, search, status, limit}) {
        if (cursor == null) return _immediate([_person('p1')], nextCursor: 'cursor-1');
        return _immediate([_person('p1'), _person('p2')], nextCursor: null);
      },
    );
    await Future<void>.delayed(Duration.zero);

    await container.read(peopleDirectoryControllerProvider.notifier).loadNextPage();

    final ids = container.read(peopleDirectoryControllerProvider).people.map((p) => p.id).toList();
    expect(ids, ['p1', 'p2']);
  });

  test('refresh replaces accumulated pages with a fresh page one, preserving search and filter', () async {
    var refreshed = false;
    buildContainer(OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'), (
      {required organizationId, cursor, search, status, limit}) {
      if (refreshed) return _immediate([_person('fresh')], nextCursor: null);
      if (cursor == null) return _immediate([_person('p1')], nextCursor: 'cursor-1');
      return _immediate([_person('p2')], nextCursor: null);
    });
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(peopleDirectoryControllerProvider.notifier);
    notifier.updateSearch('john');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    notifier.updateStatusFilter(PeopleStatusFilter.active);
    await Future<void>.delayed(Duration.zero);
    await notifier.loadNextPage();

    refreshed = true;
    await notifier.refresh();

    final state = container.read(peopleDirectoryControllerProvider);
    expect(state.people.map((p) => p.id), ['fresh']);
    expect(state.search, 'john');
    expect(state.statusFilter, PeopleStatusFilter.active);
    expect(api.calls.last.search, 'john');
    expect(api.calls.last.status, PersonStatus.active);
  });

  test('organization switch clears prior People/search/filter/pagination state', () async {
    buildContainer(
      OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'),
      ({required organizationId, cursor, search, status, limit}) =>
          _immediate([_person('org-a-person')], nextCursor: 'cursor-a'),
    );
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(peopleDirectoryControllerProvider.notifier);
    notifier.updateSearch('john');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    notifier.updateStatusFilter(PeopleStatusFilter.active);
    await Future<void>.delayed(Duration.zero);

    api.handler = ({required organizationId, cursor, search, status, limit}) => _immediate([_person('org-b-person')]);
    orgController.emit(
      OrganizationContextActive(organizations: [_orgSummary('org-b')], selectedOrganizationId: 'org-b'),
    );
    await Future<void>.delayed(Duration.zero);

    final state = container.read(peopleDirectoryControllerProvider);
    expect(state.people.map((p) => p.id), ['org-b-person']);
    expect(state.search, '');
    expect(state.statusFilter, PeopleStatusFilter.all);
    expect(state.nextCursor, isNull);
  });

  test('a stale Organization A response cannot overwrite Organization B state', () async {
    final orgAGate = Completer<PeoplePage>();

    buildContainer(OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'), (
      {required organizationId, cursor, search, status, limit}) {
      return orgAGate.future;
    });

    // org-a's initial load is now in flight and gated.
    api.handler = ({required organizationId, cursor, search, status, limit}) => _immediate([_person('org-b-person')]);
    orgController.emit(
      OrganizationContextActive(organizations: [_orgSummary('org-b')], selectedOrganizationId: 'org-b'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(peopleDirectoryControllerProvider).people.map((p) => p.id), ['org-b-person']);

    // org-a's stale response now arrives late.
    orgAGate.complete(PeoplePage(people: [_person('org-a-person')], nextCursor: null));
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(peopleDirectoryControllerProvider).people.map((p) => p.id),
      ['org-b-person'],
      reason: 'the disposed org-a instance must never mutate the current org-b state',
    );
  });

  test('a stale older-search response cannot overwrite a newer search result', () async {
    final staleGate = Completer<PeoplePage>();

    buildContainer(OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'), (
      {required organizationId, cursor, search, status, limit}) {
      if (search == 'a') return staleGate.future;
      return _immediate([_person('result-for-$search')]);
    });
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(peopleDirectoryControllerProvider.notifier);
    notifier.updateSearch('a');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    notifier.updateSearch('ab');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(container.read(peopleDirectoryControllerProvider).people.single.id, 'result-for-ab');

    staleGate.complete(PeoplePage(people: [_person('result-for-a')], nextCursor: null));
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(peopleDirectoryControllerProvider).people.single.id,
      'result-for-ab',
      reason: 'the stale search=a response must not overwrite the newer search=ab state',
    );
  });

  test('a stale pagination response cannot apply after a generation change', () async {
    final staleGate = Completer<PeoplePage>();

    buildContainer(OrganizationContextActive(organizations: [_orgSummary('org-a')], selectedOrganizationId: 'org-a'), (
      {required organizationId, cursor, search, status, limit}) {
      if (cursor != null) return staleGate.future;
      return _immediate([_person('p1')], nextCursor: 'cursor-1');
    });
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(peopleDirectoryControllerProvider.notifier);
    final pagination = notifier.loadNextPage();

    // A filter change bumps the generation while pagination is still in flight.
    notifier.updateStatusFilter(PeopleStatusFilter.active);
    await Future<void>.delayed(Duration.zero);

    staleGate.complete(PeoplePage(people: [_person('stale-page-person')], nextCursor: null));
    await pagination;
    await Future<void>.delayed(Duration.zero);

    final ids = container.read(peopleDirectoryControllerProvider).people.map((p) => p.id);
    expect(ids.contains('stale-page-person'), isFalse);
  });
}
