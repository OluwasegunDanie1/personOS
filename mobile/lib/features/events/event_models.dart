/// Mirrors the approved GET/POST/PATCH
/// /organizations/:organizationId/events response shape exactly:
/// {id, title, description, category, venue, startDate, endDate,
/// cancelledAt, createdAt}. cancelledAt is the sole Cancel Event authority
/// (Product Task 059/060) — there is no separate status/lifecycle column,
/// no capacity/expected field, and no timezone-identity field.
class EventSummary {
  const EventSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.venue,
    required this.startDate,
    required this.endDate,
    required this.cancelledAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? venue;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  factory EventSummary.fromJson(Map<String, dynamic> json) => EventSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    category: json['category'] as String?,
    venue: json['venue'] as String?,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Detail-only (View/Create/Update/Cancel Event): adds createdBy — id,
/// firstName, lastName only, never email/phone/status/passwordHash.
class EventCreatorRef {
  const EventCreatorRef({required this.id, required this.firstName, required this.lastName});

  final String id;
  final String firstName;
  final String lastName;

  String get displayName => '$firstName $lastName'.trim();

  factory EventCreatorRef.fromJson(Map<String, dynamic> json) => EventCreatorRef(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
  );
}

class EventDetail extends EventSummary {
  const EventDetail({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.venue,
    required super.startDate,
    required super.endDate,
    required super.cancelledAt,
    required super.createdAt,
    required this.createdBy,
  });

  final EventCreatorRef createdBy;

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    final summary = EventSummary.fromJson(json);
    return EventDetail(
      id: summary.id,
      title: summary.title,
      description: summary.description,
      category: summary.category,
      venue: summary.venue,
      startDate: summary.startDate,
      endDate: summary.endDate,
      cancelledAt: summary.cancelledAt,
      createdAt: summary.createdAt,
      createdBy: EventCreatorRef.fromJson(json['createdBy'] as Map<String, dynamic>),
    );
  }
}

class EventListResult {
  const EventListResult({required this.events, required this.nextCursor});

  final List<EventSummary> events;
  final String? nextCursor;

  factory EventListResult.fromJson(Map<String, dynamic> json) => EventListResult(
    events: (json['events'] as List<dynamic>)
        .map((event) => EventSummary.fromJson(event as Map<String, dynamic>))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}

/// Read-only: mirrors GET .../events/:eventId/attendance's
/// EventAttendanceEntry exactly: {id, person{id,firstName,lastName},
/// status, checkedInBy{id,firstName,lastName}|null, checkedInAt}. This is
/// the existing check-in Attendance record, never a "registration"/RSVP/
/// guest concept — no such domain exists.
class EventAttendanceRecord {
  const EventAttendanceRecord({
    required this.id,
    required this.personId,
    required this.personFirstName,
    required this.personLastName,
    required this.status,
    required this.checkedInAt,
  });

  final String id;
  final String personId;
  final String personFirstName;
  final String personLastName;
  final String status;
  final DateTime checkedInAt;

  String get personDisplayName => '$personFirstName $personLastName'.trim();

  factory EventAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final person = json['person'] as Map<String, dynamic>;
    return EventAttendanceRecord(
      id: json['id'] as String,
      personId: person['id'] as String,
      personFirstName: person['firstName'] as String,
      personLastName: person['lastName'] as String,
      status: json['status'] as String,
      checkedInAt: DateTime.parse(json['checkedInAt'] as String),
    );
  }
}

class EventAttendanceListResult {
  const EventAttendanceListResult({required this.attendance, required this.nextCursor});

  final List<EventAttendanceRecord> attendance;
  final String? nextCursor;

  factory EventAttendanceListResult.fromJson(Map<String, dynamic> json) => EventAttendanceListResult(
    attendance: (json['attendance'] as List<dynamic>)
        .map((entry) => EventAttendanceRecord.fromJson(entry as Map<String, dynamic>))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}

/// Controller-authority lifecycle precedence (Product Task 061/062), always
/// derived — never persisted, never a value read off any response field
/// except cancelledAt/startDate/endDate themselves:
/// CANCELLED (cancelledAt != null) -> TODAY (startDate is today in
/// device-local calendar time) -> COMPLETED ((endDate ?? startDate) < now)
/// -> UPCOMING (remaining non-cancelled future state).
enum EventLifecycleStatus { cancelled, today, completed, upcoming }

EventLifecycleStatus deriveEventLifecycleStatus(EventSummary event, {DateTime? now}) {
  if (event.cancelledAt != null) return EventLifecycleStatus.cancelled;

  final reference = now ?? DateTime.now();
  final localStart = event.startDate.toLocal();
  final isToday =
      localStart.year == reference.year && localStart.month == reference.month && localStart.day == reference.day;
  if (isToday) return EventLifecycleStatus.today;

  final effectiveEnd = (event.endDate ?? event.startDate).toLocal();
  if (effectiveEnd.isBefore(reference)) return EventLifecycleStatus.completed;

  return EventLifecycleStatus.upcoming;
}
