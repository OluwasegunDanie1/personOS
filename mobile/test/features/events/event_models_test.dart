import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/features/events/event_models.dart';

EventSummary _event({DateTime? startDate, DateTime? endDate, DateTime? cancelledAt}) => EventSummary(
  id: 'event-1',
  title: 'Sunday Service',
  description: null,
  category: null,
  venue: null,
  startDate: startDate ?? DateTime.now().toUtc(),
  endDate: endDate,
  cancelledAt: cancelledAt,
  createdAt: DateTime.now().toUtc(),
);

void main() {
  group('EventSummary.fromJson / EventDetail.fromJson', () {
    test('parses the exact approved fields including cancelledAt when null', () {
      final event = EventSummary.fromJson({
        'id': 'event-1',
        'title': 'Sunday Service',
        'description': null,
        'category': null,
        'venue': null,
        'startDate': '2026-08-02T09:00:00.000Z',
        'endDate': null,
        'cancelledAt': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(event.id, 'event-1');
      expect(event.startDate, DateTime.parse('2026-08-02T09:00:00.000Z'));
      expect(event.endDate, isNull);
      expect(event.cancelledAt, isNull);
    });

    test('parses cancelledAt when non-null', () {
      final event = EventSummary.fromJson({
        'id': 'event-1',
        'title': 'Team Retreat',
        'description': null,
        'category': null,
        'venue': null,
        'startDate': '2026-08-02T09:00:00.000Z',
        'endDate': null,
        'cancelledAt': '2026-07-20T10:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(event.cancelledAt, DateTime.parse('2026-07-20T10:00:00.000Z'));
    });

    test('EventDetail.fromJson adds createdBy on top of the summary shape', () {
      final detail = EventDetail.fromJson({
        'id': 'event-1',
        'title': 'Sunday Service',
        'description': 'Weekly service',
        'category': 'Worship',
        'venue': 'Main Auditorium',
        'startDate': '2026-08-02T09:00:00.000Z',
        'endDate': '2026-08-02T11:00:00.000Z',
        'cancelledAt': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'createdBy': {'id': 'user-1', 'firstName': 'Ada', 'lastName': 'Lovelace'},
      });

      expect(detail.createdBy.displayName, 'Ada Lovelace');
      expect(detail.category, 'Worship');
    });
  });

  group('deriveEventLifecycleStatus', () {
    final now = DateTime(2026, 7, 14, 12, 0);

    test('CANCELLED takes precedence over every other state', () {
      final event = _event(
        startDate: DateTime(2026, 7, 14, 9, 0),
        endDate: DateTime(2026, 7, 14, 10, 0),
        cancelledAt: DateTime(2026, 7, 10),
      );

      expect(deriveEventLifecycleStatus(event, now: now), EventLifecycleStatus.cancelled);
    });

    test('TODAY: non-cancelled and startDate is today in local calendar time', () {
      final event = _event(startDate: DateTime(2026, 7, 14, 18, 0));
      expect(deriveEventLifecycleStatus(event, now: now), EventLifecycleStatus.today);
    });

    test('TODAY applies even if the event already started earlier today', () {
      final event = _event(startDate: DateTime(2026, 7, 14, 6, 0), endDate: DateTime(2026, 7, 14, 8, 0));
      expect(deriveEventLifecycleStatus(event, now: now), EventLifecycleStatus.today);
    });

    test('COMPLETED: non-cancelled, not today, and (endDate ?? startDate) < now', () {
      final event = _event(startDate: DateTime(2026, 7, 10, 9, 0), endDate: DateTime(2026, 7, 10, 11, 0));
      expect(deriveEventLifecycleStatus(event, now: now), EventLifecycleStatus.completed);
    });

    test('COMPLETED uses startDate when endDate is null', () {
      final event = _event(startDate: DateTime(2026, 7, 10, 9, 0), endDate: null);
      expect(deriveEventLifecycleStatus(event, now: now), EventLifecycleStatus.completed);
    });

    test('UPCOMING: the remaining non-cancelled future state', () {
      final event = _event(startDate: DateTime(2026, 7, 20, 9, 0));
      expect(deriveEventLifecycleStatus(event, now: now), EventLifecycleStatus.upcoming);
    });
  });
}
