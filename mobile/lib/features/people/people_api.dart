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
}
