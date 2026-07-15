/// Mirrors GET /organizations/:organizationId/reports/dashboard's approved
/// upcomingEvents item shape exactly: {id, title, startDate}.
class UpcomingEvent {
  const UpcomingEvent({required this.id, required this.title, required this.startDate});

  final String id;
  final String title;
  final DateTime startDate;

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) => UpcomingEvent(
    id: json['id'] as String,
    title: json['title'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
  );
}

/// Mirrors GET /reports/dashboard's approved recentMembers item shape
/// exactly: {id, firstName, lastName, joinedAt} (Product Task 054/056).
/// joinedAt reuses the same Person.createdAt mapping PersonSummary.joinedAt
/// already establishes elsewhere — no new field/meaning.
class RecentMember {
  const RecentMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.joinedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime joinedAt;

  String get displayName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return ('$first$last').toUpperCase();
  }

  factory RecentMember.fromJson(Map<String, dynamic> json) => RecentMember(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    joinedAt: DateTime.parse(json['joinedAt'] as String),
  );
}

/// Mirrors GET /reports/dashboard's approved pendingTasks item shape
/// exactly: {id, title, description, dueDate} (Product Task 054/056). This
/// is the existing FollowUp domain reused, not a new Task domain — no
/// priority, category, assignee, or completion-percentage field exists on
/// this contract. dueDate remains the existing absolute-instant-or-null
/// FollowUp.dueDate contract, parsed the same way FollowUpSummary.dueDate
/// already is.
class PendingTask {
  const PendingTask({required this.id, required this.title, required this.description, required this.dueDate});

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;

  factory PendingTask.fromJson(Map<String, dynamic> json) => PendingTask(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
  );
}

/// Mirrors the approved Dashboard Summary response shape exactly:
/// {totalPeople, newPeople, pendingFollowUps, upcomingEvents, recentMembers,
/// pendingTasks}. No attendanceRate/todayAttendance/recentActivity/
/// journeyStageDistribution/growth field exists on this endpoint — do not
/// add them here.
class DashboardSummary {
  const DashboardSummary({
    required this.totalPeople,
    required this.newPeople,
    required this.pendingFollowUps,
    required this.upcomingEvents,
    required this.recentMembers,
    required this.pendingTasks,
  });

  final int totalPeople;
  final int newPeople;
  final int pendingFollowUps;
  final List<UpcomingEvent> upcomingEvents;
  final List<RecentMember> recentMembers;
  final List<PendingTask> pendingTasks;

  /// Each list field is defensively treated as empty when absent/null
  /// (Product Task 088) rather than crashing the whole dashboard — the
  /// approved contract always returns a real array, but this keeps the
  /// screen resilient to any transient serialization anomaly.
  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    totalPeople: json['totalPeople'] as int,
    newPeople: json['newPeople'] as int,
    pendingFollowUps: json['pendingFollowUps'] as int,
    upcomingEvents: (json['upcomingEvents'] as List<dynamic>? ?? const [])
        .map((event) => UpcomingEvent.fromJson(event as Map<String, dynamic>))
        .toList(),
    recentMembers: (json['recentMembers'] as List<dynamic>? ?? const [])
        .map((member) => RecentMember.fromJson(member as Map<String, dynamic>))
        .toList(),
    pendingTasks: (json['pendingTasks'] as List<dynamic>? ?? const [])
        .map((task) => PendingTask.fromJson(task as Map<String, dynamic>))
        .toList(),
  );
}
