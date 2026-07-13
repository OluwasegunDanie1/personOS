import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import 'people_models.dart';

/// Integrates the real, implemented GET /organizations/:organizationId/people
/// endpoint only. This task's approved query dimensions are cursor, limit,
/// search, and status — journeyStageId and sort are explicitly out of scope
/// for this slice (no UI drives them). Create/Update/Delete Person and the
/// Person Detail endpoint are not integrated here (Add Person and Person
/// Profile remain deferred to their own controlled slices).
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
}
