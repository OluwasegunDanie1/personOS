import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import '../people/people_models.dart' show FieldUpdate;
import 'event_models.dart';

/// Integrates the real, implemented Event endpoints
/// (13_API_Specification.md's Event Endpoints section, Product Task 059/060
/// for cancellation): List/Create/View/Update/Cancel Event, plus the
/// read-only Event Attendance list. No capacity/RSVP/registration/
/// announcements/notes/activity endpoint exists, so none is integrated here.
class EventsApi {
  EventsApi(this._dio);

  final Dio _dio;

  Future<EventListResult> list({
    required String organizationId,
    String? cursor,
    String? search,
    String? category,
    int? limit,
  }) async {
    final response = await _dio.get<dynamic>(
      '/organizations/$organizationId/events',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (limit != null) 'limit': limit,
      },
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return EventListResult.fromJson(data);
  }

  Future<EventDetail> detail({required String organizationId, required String eventId}) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId/events/$eventId');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return EventDetail.fromJson(data['event'] as Map<String, dynamic>);
  }

  /// [startDate] must already be a fully-resolved local DateTime, combined
  /// from the user's own explicitly selected calendar Date AND wall-clock
  /// Start Time — this method only performs the final .toUtc() serialization
  /// step. It never invents, defaults, or infers a missing component (no
  /// midnight, no noon, no current-time). [endDate], when supplied, follows
  /// the same rule; omitted End Time means [endDate] is null, which is
  /// simply never sent (endDate stays optional on Create Event).
  Future<EventDetail> create({
    required String organizationId,
    required String title,
    String? category,
    String? description,
    String? venue,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final trimmedCategory = category?.trim();
    final trimmedDescription = description?.trim();
    final trimmedVenue = venue?.trim();

    final response = await _dio.post<dynamic>(
      '/organizations/$organizationId/events',
      data: {
        'title': title.trim(),
        if (trimmedCategory != null && trimmedCategory.isNotEmpty) 'category': trimmedCategory,
        if (trimmedDescription != null && trimmedDescription.isNotEmpty) 'description': trimmedDescription,
        if (trimmedVenue != null && trimmedVenue.isNotEmpty) 'venue': trimmedVenue,
        'startDate': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
      },
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return EventDetail.fromJson(data['event'] as Map<String, dynamic>);
  }

  /// Every parameter defaults to [FieldUpdate.omit] so a field the caller
  /// never mentions can never enter the request body — mirrors
  /// [PeopleApi.update]'s changed-fields-only convention exactly.
  /// [FieldUpdate.clear] always serializes JSON null (never omitted), which
  /// is what lets the backend distinguish omission from explicit clearing
  /// for description/category/venue/endDate. startDate/endDate values, when
  /// set, must already be fully-resolved local DateTimes (same construction
  /// rule as [create]) — this method only performs .toUtc() serialization.
  Future<EventDetail> update({
    required String organizationId,
    required String eventId,
    FieldUpdate<String> title = const FieldUpdate.omit(),
    FieldUpdate<String> description = const FieldUpdate.omit(),
    FieldUpdate<String> category = const FieldUpdate.omit(),
    FieldUpdate<String> venue = const FieldUpdate.omit(),
    FieldUpdate<DateTime> startDate = const FieldUpdate.omit(),
    FieldUpdate<DateTime> endDate = const FieldUpdate.omit(),
  }) async {
    final data = <String, dynamic>{
      if (title.isSet) 'title': title.value,
      if (description.isSet) 'description': description.value,
      if (category.isSet) 'category': category.value,
      if (venue.isSet) 'venue': venue.value,
      if (startDate.isSet) 'startDate': startDate.value?.toUtc().toIso8601String(),
      if (endDate.isSet) 'endDate': endDate.value?.toUtc().toIso8601String(),
    };

    final response = await _dio.patch<dynamic>('/organizations/$organizationId/events/$eventId', data: data);
    final responseData = unwrapEnvelope(response) as Map<String, dynamic>;
    return EventDetail.fromJson(responseData['event'] as Map<String, dynamic>);
  }

  /// Integrates the real, implemented POST
  /// /organizations/:organizationId/events/:eventId/cancel endpoint (Product
  /// Task 059/060). Idempotent on the backend: a repeat call returns the
  /// same cancelledAt unchanged. There is no uncancel/restore endpoint.
  Future<EventDetail> cancel({required String organizationId, required String eventId}) async {
    final response = await _dio.post<dynamic>('/organizations/$organizationId/events/$eventId/cancel');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return EventDetail.fromJson(data['event'] as Map<String, dynamic>);
  }

  /// Integrates the real, implemented GET
  /// /organizations/:organizationId/events/:eventId/attendance endpoint.
  /// Read-only: these are real check-in Attendance records, never a
  /// registration/RSVP/guest list (no such domain exists).
  Future<EventAttendanceListResult> attendance({
    required String organizationId,
    required String eventId,
    String? cursor,
  }) async {
    final response = await _dio.get<dynamic>(
      '/organizations/$organizationId/events/$eventId/attendance',
      queryParameters: {if (cursor != null) 'cursor': cursor},
    );
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return EventAttendanceListResult.fromJson(data);
  }
}
