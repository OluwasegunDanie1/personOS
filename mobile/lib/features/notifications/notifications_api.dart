import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import 'notification_models.dart';

/// Integrates the real, implemented Notifications endpoints (Product Task
/// 064/066): List, Mark Read, Mark All Read, Clear Read. There is no
/// category filter (no such column) and no notification-generation, push,
/// email/SMS, or preferences endpoint — none is integrated here.
class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

  Future<NotificationListResult> list({
    required String organizationId,
    String? cursor,
    int? limit,
    bool? read,
  }) async {
    final response = await _dio.get<dynamic>(
      '/organizations/$organizationId/notifications',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (limit != null) 'limit': limit,
        if (read != null) 'read': read.toString(),
      },
    );

    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return NotificationListResult.fromJson(data);
  }

  Future<AppNotification> markRead({required String organizationId, required String notificationId}) async {
    final response = await _dio.patch<dynamic>(
      '/organizations/$organizationId/notifications/$notificationId/read',
    );
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return AppNotification.fromJson(data['notification'] as Map<String, dynamic>);
  }

  Future<int> markAllRead({required String organizationId}) async {
    final response = await _dio.patch<dynamic>('/organizations/$organizationId/notifications/read-all');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return data['markedCount'] as int;
  }

  Future<int> clearRead({required String organizationId}) async {
    final response = await _dio.delete<dynamic>('/organizations/$organizationId/notifications/read');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return data['clearedCount'] as int;
  }
}
