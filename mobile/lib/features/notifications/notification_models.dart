/// Mirrors the approved GET /organizations/:organizationId/notifications
/// response shape exactly: {id, title, message, isRead, createdAt}
/// (Product Task 064/066). There is no category field and no deep-link
/// field on this contract — do not add either here.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    isRead: json['isRead'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class NotificationListResult {
  const NotificationListResult({required this.notifications, required this.nextCursor});

  final List<AppNotification> notifications;
  final String? nextCursor;

  factory NotificationListResult.fromJson(Map<String, dynamic> json) => NotificationListResult(
    notifications: (json['notifications'] as List<dynamic>)
        .map((entry) => AppNotification.fromJson(entry as Map<String, dynamic>))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}
