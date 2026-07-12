import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import 'dashboard_models.dart';

/// Integrates the sole approved Reports/Dashboard endpoint. Every other
/// bare Reports path (attendance/growth/follow-ups/export) remains
/// unresolved and is deliberately not integrated here.
class DashboardApi {
  DashboardApi(this._dio);

  final Dio _dio;

  Future<DashboardSummary> fetch(String organizationId) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId/reports/dashboard');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return DashboardSummary.fromJson(data);
  }
}
