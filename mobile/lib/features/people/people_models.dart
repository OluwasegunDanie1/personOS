/// Mirrors the approved GET /organizations/:organizationId/people contract
/// exactly (13_API_Specification.md's People Endpoints section). Person.status
/// is a closed v1 allowlist of exactly two values — there is no Visitor/
/// Member/Volunteer/Leader taxonomy at the API level (that is legacy Atlas
/// draft material, superseded per Product Task 030's authority audit).
enum PersonStatus {
  active,
  inactive;

  static PersonStatus fromApiValue(String value) {
    switch (value) {
      case 'ACTIVE':
        return PersonStatus.active;
      case 'INACTIVE':
        return PersonStatus.inactive;
      default:
        throw ArgumentError('Unknown Person.status value: $value');
    }
  }

  String toApiValue() {
    switch (this) {
      case PersonStatus.active:
        return 'ACTIVE';
      case PersonStatus.inactive:
        return 'INACTIVE';
    }
  }
}

/// Write-only through Create Person in v1: the backend persists gender but
/// never returns it (not in PersonSummary, List, or Detail), so this enum
/// exists purely for the Add Person request, not for parsing any response.
/// Canonical API values are exactly MALE/FEMALE (13_API_Specification.md);
/// there is no Other/Prefer-not-to-say/Unspecified authority.
enum PersonGender {
  male,
  female;

  String toApiValue() {
    switch (this) {
      case PersonGender.male:
        return 'MALE';
      case PersonGender.female:
        return 'FEMALE';
    }
  }

  /// Detail-only (Product Task 041): gender is now read back by Person
  /// Detail (Product Task 039), so unlike toApiValue (write-only, used only
  /// by Add Person), this parses a real response value. Canonical values
  /// are exactly MALE/FEMALE — there is no OTHER authority to parse.
  static PersonGender fromApiValue(String value) {
    switch (value) {
      case 'MALE':
        return PersonGender.male;
      case 'FEMALE':
        return PersonGender.female;
      default:
        throw ArgumentError('Unknown Person.gender value: $value');
    }
  }

  String get displayLabel {
    switch (this) {
      case PersonGender.male:
        return 'Male';
      case PersonGender.female:
        return 'Female';
    }
  }
}

/// Parses an approved date-only YYYY-MM-DD response value (Person Detail's
/// dateOfBirth) into a UTC-midnight DateTime, mirroring the backend's own
/// date-of-birth.validator.ts storage convention. Deliberately never routed
/// through DateTime.parse's local-time interpretation or any
/// .toLocal()/.toUtc() conversion, so the calendar date can never shift due
/// to device timezone. Callers must read .year/.month/.day directly (never
/// call .toLocal() on the result) to preserve this guarantee.
DateTime parseDateOnly(String value) {
  final parts = value.split('-');
  return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Detail-only (Product Task 039): a Tag as returned by Person Detail's
/// read-only `tags` field. Not part of the approved Person Profile frozen
/// composition (Task 038 §8), so not currently rendered anywhere, but
/// modeled here because Person Detail's real response contract includes it.
class PersonTag {
  const PersonTag({required this.id, required this.name});

  final String id;
  final String name;

  factory PersonTag.fromJson(Map<String, dynamic> json) =>
      PersonTag(id: json['id'] as String, name: json['name'] as String);
}

/// List-only (Product Task 035): {id, name}. Never returned by Create, so
/// this is only ever constructed via PersonSummary.fromJson on a List
/// response. name is the organization's own configured stage label — never
/// transformed, never assumed to be one of a fixed reference set.
class JourneyStageSummary {
  const JourneyStageSummary({required this.id, required this.name});

  final String id;
  final String name;

  factory JourneyStageSummary.fromJson(Map<String, dynamic> json) =>
      JourneyStageSummary(id: json['id'] as String, name: json['name'] as String);
}

/// List-only (Product Task 035): {checkedInAt}. No event detail, status, or
/// attendance id is part of this contract — never returned by Create.
class LastAttendanceSummary {
  const LastAttendanceSummary({required this.checkedInAt});

  final DateTime checkedInAt;

  factory LastAttendanceSummary.fromJson(Map<String, dynamic> json) =>
      LastAttendanceSummary(checkedInAt: DateTime.parse(json['checkedInAt'] as String));
}

/// Mirrors PersonSummary exactly: {id, firstName, lastName, email, phone,
/// status, avatarUrl, joinedAt}, plus the two List-only enrichment fields
/// added by Product Task 035 (currentJourneyStage, lastAttendance) — both
/// optional/nullable so a Create-response-shaped payload (which omits both)
/// still parses successfully. No team/group/role/memberType/followUpCount/
/// notesCount/address/gender/dateOfBirth field exists here — none of those
/// are part of the approved API contract for this endpoint.
class PersonSummary {
  const PersonSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    required this.avatarUrl,
    required this.joinedAt,
    this.currentJourneyStage,
    this.lastAttendance,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final PersonStatus status;
  final String? avatarUrl;
  final DateTime joinedAt;
  final JourneyStageSummary? currentJourneyStage;
  final LastAttendanceSummary? lastAttendance;

  String get displayName => '$firstName $lastName'.trim();

  /// Uppercase first character of firstName + first character of lastName.
  /// Never invents a placeholder letter: a missing name part simply
  /// contributes nothing, and an empty result signals the caller to fall
  /// back to a generic icon instead of fabricated text.
  String get initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return ('$first$last').toUpperCase();
  }

  factory PersonSummary.fromJson(Map<String, dynamic> json) => PersonSummary(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    status: PersonStatus.fromApiValue(json['status'] as String),
    avatarUrl: json['avatarUrl'] as String?,
    joinedAt: DateTime.parse(json['joinedAt'] as String),
    currentJourneyStage: json['currentJourneyStage'] != null
        ? JourneyStageSummary.fromJson(json['currentJourneyStage'] as Map<String, dynamic>)
        : null,
    lastAttendance: json['lastAttendance'] != null
        ? LastAttendanceSummary.fromJson(json['lastAttendance'] as Map<String, dynamic>)
        : null,
  );
}

/// Mirrors the List People response shape exactly: {people, nextCursor}.
/// nextCursor is opaque — never decoded or reinterpreted client-side.
class PeoplePage {
  const PeoplePage({required this.people, required this.nextCursor});

  final List<PersonSummary> people;
  final String? nextCursor;

  factory PeoplePage.fromJson(Map<String, dynamic> json) => PeoplePage(
    people: (json['people'] as List<dynamic>)
        .map((person) => PersonSummary.fromJson(person as Map<String, dynamic>))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}

/// Mirrors the real, implemented GET
/// /organizations/:organizationId/people/:personId response exactly
/// (Product Task 039's read-contract widening): {id, firstName, lastName,
/// email, phone, status, avatarUrl, joinedAt, tags, currentJourneyStage,
/// gender, dateOfBirth, address}. This is Detail-only authority — deliberately
/// a separate class from PersonSummary/PersonListSummary, never constructed
/// from a List response, so PersonSummary is never mistaken for Detail
/// authority anywhere in the app.
class PersonDetail {
  const PersonDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    required this.avatarUrl,
    required this.joinedAt,
    required this.tags,
    required this.currentJourneyStage,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final PersonStatus status;
  final String? avatarUrl;
  final DateTime joinedAt;
  final List<PersonTag> tags;
  final JourneyStageSummary? currentJourneyStage;
  final PersonGender? gender;

  /// Date-only semantic (never a timestamp). Always UTC-midnight — see
  /// parseDateOnly. Read .year/.month/.day directly; never call .toLocal().
  final DateTime? dateOfBirth;
  final String? address;

  String get displayName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return ('$first$last').toUpperCase();
  }

  factory PersonDetail.fromJson(Map<String, dynamic> json) => PersonDetail(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    status: PersonStatus.fromApiValue(json['status'] as String),
    avatarUrl: json['avatarUrl'] as String?,
    joinedAt: DateTime.parse(json['joinedAt'] as String),
    tags: (json['tags'] as List<dynamic>)
        .map((tag) => PersonTag.fromJson(tag as Map<String, dynamic>))
        .toList(),
    currentJourneyStage: json['currentJourneyStage'] != null
        ? JourneyStageSummary.fromJson(json['currentJourneyStage'] as Map<String, dynamic>)
        : null,
    gender: json['gender'] != null ? PersonGender.fromApiValue(json['gender'] as String) : null,
    dateOfBirth: json['dateOfBirth'] != null ? parseDateOnly(json['dateOfBirth'] as String) : null,
    address: json['address'] as String?,
  );
}

/// Mirrors the real, implemented GET
/// /organizations/:organizationId/people/:personId/journey response's
/// currentJourneyStage field exactly: {id, name, position}. position is the
/// only field this shallow (Detail-level) currentJourneyStage lacks — it is
/// the reason Person Profile calls this dedicated Journey endpoint rather
/// than relying on Person Detail's own currentJourneyStage alone (Task 038
/// §10: Person Detail alone is not enough for the frozen Journey region).
class PersonJourneyCurrentStage {
  const PersonJourneyCurrentStage({required this.id, required this.name, required this.position});

  final String id;
  final String name;
  final int position;

  factory PersonJourneyCurrentStage.fromJson(Map<String, dynamic> json) => PersonJourneyCurrentStage(
    id: json['id'] as String,
    name: json['name'] as String,
    position: json['position'] as int,
  );
}

/// Narrow projection of one GET .../journey history entry: only the two
/// fields (toStage.id, movedAt) needed to derive, per real stage, the most
/// recent instant it was moved into (see PersonProfileController's stepper
/// date derivation). fromStage/note/movedBy are real, approved response
/// fields but are not required by this first Profile slice's stepper, so
/// they are intentionally not modeled here.
class PersonJourneyHistoryEntry {
  const PersonJourneyHistoryEntry({required this.toStageId, required this.movedAt});

  final String toStageId;
  final DateTime movedAt;

  factory PersonJourneyHistoryEntry.fromJson(Map<String, dynamic> json) => PersonJourneyHistoryEntry(
    toStageId: (json['toStage'] as Map<String, dynamic>)['id'] as String,
    movedAt: DateTime.parse(json['movedAt'] as String),
  );
}

/// Mirrors the real, implemented GET
/// /organizations/:organizationId/people/:personId/journey response shape:
/// {currentJourneyStage, history}. currentStage is null exactly when the
/// Person has no journey history yet.
class PersonJourneyView {
  const PersonJourneyView({required this.currentStage, required this.history});

  final PersonJourneyCurrentStage? currentStage;
  final List<PersonJourneyHistoryEntry> history;

  factory PersonJourneyView.fromJson(Map<String, dynamic> json) => PersonJourneyView(
    currentStage: json['currentJourneyStage'] != null
        ? PersonJourneyCurrentStage.fromJson(json['currentJourneyStage'] as Map<String, dynamic>)
        : null,
    history: (json['history'] as List<dynamic>)
        .map((entry) => PersonJourneyHistoryEntry.fromJson(entry as Map<String, dynamic>))
        .toList(),
  );
}

/// One entry of the real, implemented GET
/// /organizations/:organizationId/journey-stages response's ordered `stages`
/// list: {id, name, position}. name is the organization's own configured
/// stage label — never a fixed/illustrative reference set. Ordering
/// authority (position ascending, then id ascending) belongs to the
/// backend; this model does not re-sort — callers must trust response order.
class JourneyStageListEntry {
  const JourneyStageListEntry({required this.id, required this.name, required this.position});

  final String id;
  final String name;
  final int position;

  factory JourneyStageListEntry.fromJson(Map<String, dynamic> json) => JourneyStageListEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    position: json['position'] as int,
  );
}

/// Mirrors the real, implemented GET
/// /organizations/:organizationId/people/:personId/attendance/summary
/// response's attendanceSummary object exactly: {totalCount,
/// currentMonthCount}. No latestAttendance, history, percentage, streak, or
/// trend field exists here — none of those are part of this endpoint's
/// approved contract.
class AttendanceSummary {
  const AttendanceSummary({required this.totalCount, required this.currentMonthCount});

  final int totalCount;
  final int currentMonthCount;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) => AttendanceSummary(
    totalCount: json['totalCount'] as int,
    currentMonthCount: json['currentMonthCount'] as int,
  );
}

/// Mirrors the real, implemented Follow-Up person/assignedTo reference shape
/// exactly: {id, firstName, lastName}. Used for both FollowUpSummary.person
/// and FollowUpSummary.assignedTo (13_API_Specification.md's Follow-Up
/// Endpoints section — both fields share this identical shape).
class FollowUpPersonRef {
  const FollowUpPersonRef({required this.id, required this.firstName, required this.lastName});

  final String id;
  final String firstName;
  final String lastName;

  String get displayName => '$firstName $lastName'.trim();

  factory FollowUpPersonRef.fromJson(Map<String, dynamic> json) => FollowUpPersonRef(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
  );
}

/// The closed v1 accepted API values for FollowUp.status are exactly PENDING,
/// IN_PROGRESS, COMPLETED (13_API_Specification.md's "Follow-Up Status"
/// section). There is no UPCOMING, OVERDUE, CANCELLED, SNOOZED, BLOCKED, or
/// ESCALATED value — "upcoming" is a Profile-presentation-level concept
/// (non-completed), never a parsed or transmitted status value.
enum FollowUpStatus {
  pending,
  inProgress,
  completed;

  static FollowUpStatus fromApiValue(String value) {
    switch (value) {
      case 'PENDING':
        return FollowUpStatus.pending;
      case 'IN_PROGRESS':
        return FollowUpStatus.inProgress;
      case 'COMPLETED':
        return FollowUpStatus.completed;
      default:
        throw ArgumentError('Unknown FollowUp.status value: $value');
    }
  }
}

/// Mirrors the real, implemented List/Create Follow-Up response shape
/// exactly: {id, title, description, dueDate, status, completedAt, person,
/// assignedTo}. dueDate/completedAt are absolute-instant timestamps (never
/// date-only semantics, unlike Person.dateOfBirth) — parsed via the standard
/// DateTime.parse of a full ISO 8601 instant.
class FollowUpSummary {
  const FollowUpSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.completedAt,
    required this.person,
    required this.assignedTo,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final FollowUpStatus status;
  final DateTime? completedAt;
  final FollowUpPersonRef person;
  final FollowUpPersonRef? assignedTo;

  factory FollowUpSummary.fromJson(Map<String, dynamic> json) => FollowUpSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
    status: FollowUpStatus.fromApiValue(json['status'] as String),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    person: FollowUpPersonRef.fromJson(json['person'] as Map<String, dynamic>),
    assignedTo: json['assignedTo'] != null
        ? FollowUpPersonRef.fromJson(json['assignedTo'] as Map<String, dynamic>)
        : null,
  );
}

/// Mirrors the real, implemented List Follow-Ups response shape exactly:
/// {followUps, nextCursor}. hasMore mirrors PeopleDirectoryState/PeoplePage's
/// existing nextCursor-presence convention — the Profile region uses this to
/// avoid claiming an exhaustive total when more records exist beyond the
/// bounded first page.
class FollowUpListResult {
  const FollowUpListResult({required this.followUps, required this.nextCursor});

  final List<FollowUpSummary> followUps;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  factory FollowUpListResult.fromJson(Map<String, dynamic> json) => FollowUpListResult(
    followUps: (json['followUps'] as List<dynamic>)
        .map((followUp) => FollowUpSummary.fromJson(followUp as Map<String, dynamic>))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}
