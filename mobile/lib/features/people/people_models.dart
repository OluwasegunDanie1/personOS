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

/// Mirrors PersonSummary exactly: {id, firstName, lastName, email, phone,
/// status, avatarUrl, joinedAt}. No journeyStage/lastAttendance/team/group/
/// role/memberType/followUpCount/notesCount field exists here — none of
/// those are part of the approved API contract for this endpoint.
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
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final PersonStatus status;
  final String? avatarUrl;
  final DateTime joinedAt;

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
