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

/// Mirrors the approved Dashboard Summary response shape exactly:
/// {totalPeople, newPeople, pendingFollowUps, upcomingEvents}. No
/// attendanceRate/todayAttendance/recentActivity/journeyStageDistribution/
/// growth field exists on this endpoint — do not add them here.
class DashboardSummary {
  const DashboardSummary({
    required this.totalPeople,
    required this.newPeople,
    required this.pendingFollowUps,
    required this.upcomingEvents,
  });

  final int totalPeople;
  final int newPeople;
  final int pendingFollowUps;
  final List<UpcomingEvent> upcomingEvents;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    totalPeople: json['totalPeople'] as int,
    newPeople: json['newPeople'] as int,
    pendingFollowUps: json['pendingFollowUps'] as int,
    upcomingEvents: (json['upcomingEvents'] as List<dynamic>)
        .map((event) => UpcomingEvent.fromJson(event as Map<String, dynamic>))
        .toList(),
  );
}
