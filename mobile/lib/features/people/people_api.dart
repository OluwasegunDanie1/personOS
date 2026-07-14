import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import 'people_models.dart';

String _formatDateOnly(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Integrates the real, implemented GET and POST
/// /organizations/:organizationId/people endpoints. This task's approved
/// list query dimensions are cursor, limit, search, and status —
/// journeyStageId and sort are explicitly out of scope for this slice (no
/// UI drives them). Update/Delete Person and the Person Detail endpoint are
/// not integrated here (Person Profile remains deferred to its own
/// controlled slice).
class PeopleApi {
  PeopleApi(this._dio);

  final Dio _dio;

  Future<PeoplePage> list({
    required String organizationId,
    String? cursor,
    String? search,
    PersonStatus? status,
    int? limit,
  }) async {
    final response = await _dio.get<dynamic>(
      '/organizations/$organizationId/people',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status.toApiValue(),
        if (limit != null) 'limit': limit,
      },
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return PeoplePage.fromJson(data);
  }

  /// Integrates the real, implemented POST /organizations/:organizationId/people
  /// endpoint. Serializes only the eight approved Create Person fields (Task
  /// 033B) — no avatarUrl/group/notes/occupation/currentJourneyStageId/tags,
  /// none of which the backend DTO accepts (the global ValidationPipe's
  /// forbidNonWhitelisted would reject the whole request if any were sent).
  /// gender/dateOfBirth/address are write-only: the create response still
  /// returns the unchanged PersonSummary shape, so none of these three are
  /// ever parsed back out of the response.
  Future<PersonSummary> create({
    required String organizationId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    required PersonStatus status,
    PersonGender? gender,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    final trimmedEmail = email?.trim();
    final trimmedPhone = phone?.trim();
    final trimmedAddress = address?.trim();

    final response = await _dio.post<dynamic>(
      '/organizations/$organizationId/people',
      data: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        if (trimmedEmail != null && trimmedEmail.isNotEmpty) 'email': trimmedEmail.toLowerCase(),
        if (trimmedPhone != null && trimmedPhone.isNotEmpty) 'phone': trimmedPhone,
        'status': status.toApiValue(),
        if (gender != null) 'gender': gender.toApiValue(),
        if (dateOfBirth != null) 'dateOfBirth': _formatDateOnly(dateOfBirth),
        if (trimmedAddress != null && trimmedAddress.isNotEmpty) 'address': trimmedAddress,
      },
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return PersonSummary.fromJson(data['person'] as Map<String, dynamic>);
  }

  /// Integrates the real, implemented GET
  /// /organizations/:organizationId/people/:personId endpoint (Product Task
  /// 039's widened read contract). This is the only place PersonDetail is
  /// ever constructed — PersonSummary/List responses are never substituted.
  Future<PersonDetail> detail({required String organizationId, required String personId}) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId/people/$personId');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return PersonDetail.fromJson(data['person'] as Map<String, dynamic>);
  }

  /// Integrates the real, implemented GET
  /// /organizations/:organizationId/people/:personId/journey endpoint.
  Future<PersonJourneyView> journey({required String organizationId, required String personId}) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId/people/$personId/journey');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return PersonJourneyView.fromJson(data);
  }

  /// Integrates the real, implemented GET
  /// /organizations/:organizationId/journey-stages endpoint. Preserves
  /// response order (position ascending, then id ascending) — never re-sorts.
  Future<List<JourneyStageListEntry>> journeyStages({required String organizationId}) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId/journey-stages');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return (data['stages'] as List<dynamic>)
        .map((stage) => JourneyStageListEntry.fromJson(stage as Map<String, dynamic>))
        .toList();
  }

  /// Integrates the real, implemented GET
  /// /organizations/:organizationId/people/:personId/attendance/summary
  /// endpoint (Product Task 039). Never substitutes People List's
  /// lastAttendance or paginates Person Attendance history to compute counts.
  Future<AttendanceSummary> attendanceSummary({required String organizationId, required String personId}) async {
    final response = await _dio.get<dynamic>(
      '/organizations/$organizationId/people/$personId/attendance/summary',
    );
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return AttendanceSummary.fromJson(data['attendanceSummary'] as Map<String, dynamic>);
  }

  /// Integrates the real, implemented PATCH
  /// /organizations/:organizationId/people/:personId endpoint (Product Task
  /// 045's write-authority correction, integrated by Product Task 047).
  /// Every parameter defaults to [FieldUpdate.omit] so a field the caller
  /// never mentions can never enter the request body — the changed-fields
  /// diff is entirely the caller's (EditPersonController's) responsibility;
  /// this method only ever serializes whatever [FieldUpdate]s it is given.
  /// [FieldUpdate.clear] always serializes JSON `null` (never omitted, never
  /// treated as "no change"), which is what lets the backend distinguish
  /// omission from explicit clearing for the five nullable fields. Parses
  /// the response through the existing, narrower Person summary shape
  /// (PersonSummary.fromJson) — never PersonDetail — since Update Person's
  /// response deliberately never echoes gender/dateOfBirth/address/
  /// currentJourneyStage (13_API_Specification.md's Update Person section).
  Future<PersonSummary> update({
    required String organizationId,
    required String personId,
    FieldUpdate<String> firstName = const FieldUpdate.omit(),
    FieldUpdate<String> lastName = const FieldUpdate.omit(),
    FieldUpdate<String> email = const FieldUpdate.omit(),
    FieldUpdate<String> phone = const FieldUpdate.omit(),
    FieldUpdate<PersonStatus> status = const FieldUpdate.omit(),
    FieldUpdate<PersonGender> gender = const FieldUpdate.omit(),
    // Date-only YYYY-MM-DD, never a DateTime — this is a calendar date, not
    // an absolute instant, and must never be routed through
    // .toUtc().toIso8601String() the way Follow-up.dueDate is.
    FieldUpdate<String> dateOfBirth = const FieldUpdate.omit(),
    FieldUpdate<String> address = const FieldUpdate.omit(),
  }) async {
    final data = <String, dynamic>{
      if (firstName.isSet) 'firstName': firstName.value,
      if (lastName.isSet) 'lastName': lastName.value,
      if (email.isSet) 'email': email.value,
      if (phone.isSet) 'phone': phone.value,
      if (status.isSet) 'status': status.value?.toApiValue(),
      if (gender.isSet) 'gender': gender.value?.toApiValue(),
      if (dateOfBirth.isSet) 'dateOfBirth': dateOfBirth.value,
      if (address.isSet) 'address': address.value,
    };

    final response = await _dio.patch<dynamic>('/organizations/$organizationId/people/$personId', data: data);

    final responseData = unwrapEnvelope(response) as Map<String, dynamic>;
    return PersonSummary.fromJson(responseData['person'] as Map<String, dynamic>);
  }

  /// Integrates the real, implemented GET /organizations/:organizationId/follow-ups
  /// endpoint (Product Task 043), scoped to exactly one bounded person-scoped
  /// page: person_id, sort=dueDate_asc (the real approved sort value — not
  /// "due_date_asc"; confirmed against follow-ups.constants.ts and
  /// 13_API_Specification.md), limit=100. No status filter is ever sent; the
  /// Profile "non-completed" presentation filter is applied client-side over
  /// the real returned records (never as a request parameter, never inventing
  /// an UPCOMING backend value). Never recursively follows nextCursor.
  Future<FollowUpListResult> personFollowUps({required String organizationId, required String personId}) async {
    final response = await _dio.get<dynamic>(
      '/organizations/$organizationId/follow-ups',
      queryParameters: {'person_id': personId, 'sort': 'dueDate_asc', 'limit': 100},
    );
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return FollowUpListResult.fromJson(data);
  }

  /// Integrates the real, implemented POST /organizations/:organizationId/follow-ups
  /// endpoint. Serializes only the approved Create Follow-Up fields (personId,
  /// title, optional description/dueDate) — no assignedTo (Product Task 043's
  /// assignee ruling: no authoritative organization-member read boundary
  /// exists yet, so the field is never sent, never hardcoded, never fabricated).
  /// dueDate, when supplied, must already be a fully-resolved instant —
  /// i.e. a local DateTime built from the user's own explicitly selected
  /// calendar date AND wall-clock time (create_follow_up_screen.dart's due
  /// picker). This method only performs the final .toUtc() serialization
  /// step; it never invents, defaults, or infers any time component (no
  /// midnight, no noon, no current-time, no date-only semantic) — Product
  /// Task 043A's due-instant ruling explicitly rejected that behavior.
  Future<FollowUpSummary> createFollowUp({
    required String organizationId,
    required String personId,
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    final trimmedDescription = description?.trim();

    final response = await _dio.post<dynamic>(
      '/organizations/$organizationId/follow-ups',
      data: {
        'personId': personId,
        'title': title.trim(),
        if (trimmedDescription != null && trimmedDescription.isNotEmpty) 'description': trimmedDescription,
        if (dueDate != null) 'dueDate': dueDate.toUtc().toIso8601String(),
      },
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return FollowUpSummary.fromJson(data['followUp'] as Map<String, dynamic>);
  }
}
