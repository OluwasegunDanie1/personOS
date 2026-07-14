import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/notifications/notification_models.dart';
import 'package:relvio/features/notifications/notifications_api.dart';
import 'package:relvio/features/notifications/notifications_screen.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';

typedef _ListHandler = Future<NotificationListResult> Function({String? cursor});

class _ScriptedNotificationsApi extends NotificationsApi {
  _ScriptedNotificationsApi({
    required this.listHandler,
    this.markReadHandler,
    this.markAllReadHandler,
    this.clearReadHandler,
  }) : super(Dio());

  _ListHandler listHandler;
  Future<AppNotification> Function(String notificationId)? markReadHandler;
  Future<int> Function()? markAllReadHandler;
  Future<int> Function()? clearReadHandler;

  int listCallCount = 0;
  int markReadCallCount = 0;
  int markAllReadCallCount = 0;
  int clearReadCallCount = 0;

  @override
  Future<NotificationListResult> list({required String organizationId, String? cursor, int? limit, bool? read}) {
    listCallCount++;
    return listHandler(cursor: cursor);
  }

  @override
  Future<AppNotification> markRead({required String organizationId, required String notificationId}) {
    markReadCallCount++;
    return markReadHandler!(notificationId);
  }

  @override
  Future<int> markAllRead({required String organizationId}) {
    markAllReadCallCount++;
    return markAllReadHandler!();
  }

  @override
  Future<int> clearRead({required String organizationId}) {
    clearReadCallCount++;
    return clearReadHandler!();
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

AppNotification _notification({
  String id = 'notif-1',
  String title = 'New follow-up assigned',
  String message = 'You have a new follow-up due soon.',
  bool isRead = false,
  DateTime? createdAt,
}) => AppNotification(
  id: id,
  title: title,
  message: message,
  isRead: isRead,
  createdAt: createdAt ?? DateTime.now().toUtc(),
);

class _Harness {
  _Harness(this.router, this.orgController, this.api);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
  final _ScriptedNotificationsApi api;
}

Future<_Harness> _pumpNotificationsScreen(
  WidgetTester tester, {
  required _ListHandler listHandler,
  Future<AppNotification> Function(String notificationId)? markReadHandler,
  Future<int> Function()? markAllReadHandler,
  Future<int> Function()? clearReadHandler,
  OrganizationContextState initialOrg = _orgA,
  bool settle = true,
}) async {
  final api = _ScriptedNotificationsApi(
    listHandler: listHandler,
    markReadHandler: markReadHandler,
    markAllReadHandler: markAllReadHandler,
    clearReadHandler: clearReadHandler,
  );
  final orgController = _FakeOrganizationContextController(initialOrg);

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('Home'))),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  return _Harness(router, orgController, api);
}

void main() {
  testWidgets('renders real notifications with title/message and a local time', (WidgetTester tester) async {
    await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async => NotificationListResult(
        notifications: [_notification(title: 'New follow-up assigned', message: 'You have a new follow-up due soon.')],
        nextCursor: null,
      ),
    );

    expect(find.text('New follow-up assigned'), findsOneWidget);
    expect(find.text('You have a new follow-up due soon.'), findsOneWidget);
  });

  testWidgets('groups notifications under a truthful local "Today" heading', (WidgetTester tester) async {
    await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async =>
          NotificationListResult(notifications: [_notification(createdAt: DateTime.now().toUtc())], nextCursor: null),
    );

    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('an unread notification shows a distinct visual indicator that a read one does not', (
    WidgetTester tester,
  ) async {
    await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async => NotificationListResult(
        notifications: [
          _notification(id: 'unread-1', title: 'Unread item', isRead: false),
          _notification(id: 'read-1', title: 'Read item', isRead: true),
        ],
        nextCursor: null,
      ),
    );

    expect(find.text('Unread item'), findsOneWidget);
    expect(find.text('Read item'), findsOneWidget);
    expect(find.byKey(const Key('unreadDot-unread-1')), findsOneWidget);
    expect(find.byKey(const Key('unreadDot-read-1')), findsNothing);
  });

  testWidgets('a truthful empty state is shown when there are no notifications', (WidgetTester tester) async {
    await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async => const NotificationListResult(notifications: [], nextCursor: null),
    );

    expect(find.text('No notifications yet.'), findsOneWidget);
  });

  testWidgets('a truthful, retryable error state is shown on load failure', (WidgetTester tester) async {
    await _pumpNotificationsScreen(tester, listHandler: ({cursor}) async => throw Exception('network down'));

    expect(find.text('Could not load notifications.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('tapping an unread notification marks it read via the real API, never navigating anywhere', (
    WidgetTester tester,
  ) async {
    var isRead = false;
    final harness = await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async =>
          NotificationListResult(notifications: [_notification(id: 'notif-1', isRead: isRead)], nextCursor: null),
      markReadHandler: (id) async {
        isRead = true;
        return _notification(id: 'notif-1', isRead: true);
      },
    );

    await tester.tap(find.byKey(const Key('notificationRow-notif-1')));
    await tester.pumpAndSettle();

    expect(harness.api.markReadCallCount, 1);
    expect(harness.router.state.uri.toString(), '/notifications', reason: 'a row must never navigate');
  });

  testWidgets('duplicate mark-read submissions for the same notification are ignored while one is in flight', (
    WidgetTester tester,
  ) async {
    final gate = Completer<AppNotification>();
    final harness = await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async =>
          NotificationListResult(notifications: [_notification(id: 'notif-1', isRead: false)], nextCursor: null),
      markReadHandler: (id) => gate.future,
    );

    await tester.tap(find.byKey(const Key('notificationRow-notif-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('notificationRow-notif-1')));
    await tester.pump();

    expect(harness.api.markReadCallCount, 1);

    gate.complete(_notification(id: 'notif-1', isRead: true));
    await tester.pumpAndSettle();
  });

  testWidgets('Mark All Read calls the real action then refreshes the real list', (WidgetTester tester) async {
    var markedAll = false;
    final harness = await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async => NotificationListResult(
        notifications: [_notification(id: 'notif-1', isRead: markedAll)],
        nextCursor: null,
      ),
      markAllReadHandler: () async {
        markedAll = true;
        return 1;
      },
    );

    await tester.tap(find.byKey(const Key('notificationsMarkAllReadButton')));
    await tester.pumpAndSettle();

    expect(harness.api.markAllReadCallCount, 1);
    expect(harness.api.listCallCount, greaterThanOrEqualTo(2), reason: 'a real refresh must follow the mutation');
  });

  testWidgets('duplicate Mark All Read submissions are ignored while one is in flight', (WidgetTester tester) async {
    final gate = Completer<int>();
    final harness = await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async =>
          NotificationListResult(notifications: [_notification()], nextCursor: null),
      markAllReadHandler: () => gate.future,
    );

    await tester.tap(find.byKey(const Key('notificationsMarkAllReadButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('notificationsMarkAllReadButton')));
    await tester.pump();

    expect(harness.api.markAllReadCallCount, 1);

    gate.complete(1);
    await tester.pumpAndSettle();
  });

  testWidgets('Clear Read calls the real action then refreshes, and is absent/disabled with no read notifications', (
    WidgetTester tester,
  ) async {
    var cleared = false;
    final harness = await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async => NotificationListResult(
        notifications: cleared
            ? [_notification(id: 'unread-1', isRead: false)]
            : [_notification(id: 'unread-1', isRead: false), _notification(id: 'read-1', isRead: true)],
        nextCursor: null,
      ),
      clearReadHandler: () async {
        cleared = true;
        return 1;
      },
    );

    await tester.tap(find.byKey(const Key('notificationsClearReadButton')));
    await tester.pumpAndSettle();

    expect(harness.api.clearReadCallCount, 1);
    expect(harness.api.listCallCount, greaterThanOrEqualTo(2));
  });

  testWidgets('Clear Read is disabled when there are no read notifications (unread is never clearable)', (
    WidgetTester tester,
  ) async {
    await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async =>
          NotificationListResult(notifications: [_notification(id: 'unread-1', isRead: false)], nextCursor: null),
    );

    final button = tester.widget<OutlinedButton>(find.byKey(const Key('notificationsClearReadButton')));
    expect(button.onPressed, isNull);
  });

  testWidgets('loading more (pagination) requests the next real cursor page', (WidgetTester tester) async {
    var page = 0;
    final harness = await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) async {
        page++;
        if (page == 1) {
          return NotificationListResult(
            notifications: List.generate(20, (i) => _notification(id: 'n$i', title: 'Item $i')),
            nextCursor: 'cursor-2',
          );
        }
        return NotificationListResult(notifications: [_notification(id: 'n-next', title: 'Next page item')], nextCursor: null);
      },
    );

    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await tester.pumpAndSettle();

    expect(harness.api.listCallCount, greaterThanOrEqualTo(2));
  });

  testWidgets('a stale Organization A response does not render after switching to Organization B', (
    WidgetTester tester,
  ) async {
    final staleGate = Completer<NotificationListResult>();
    var callIndex = 0;
    final harness = await _pumpNotificationsScreen(
      tester,
      listHandler: ({cursor}) {
        callIndex++;
        if (callIndex == 1) return staleGate.future;
        return Future.value(
          NotificationListResult(notifications: [_notification(id: 'fresh', title: 'Fresh notification')], nextCursor: null),
        );
      },
      settle: false,
    );

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('Fresh notification'), findsOneWidget, reason: 'org-b data must be shown after the switch');

    staleGate.complete(
      NotificationListResult(notifications: [_notification(id: 'stale', title: 'Stale notification')], nextCursor: null),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stale notification'), findsNothing, reason: 'the stale org-a response must never render');
    expect(find.text('Fresh notification'), findsOneWidget, reason: 'org-b data must remain authoritative');
  });
}
