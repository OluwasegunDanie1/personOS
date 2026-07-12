import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import 'organization_models.dart';

/// Integrates the actual implemented Organization endpoints only:
/// GET/POST /organizations, GET/PATCH /organizations/:organizationId.
/// Does not implement Delete Organization (deferred/unresolved) or any
/// Team/Membership/Invitation/Role endpoint.
class OrganizationsApi {
  OrganizationsApi(this._dio);

  final Dio _dio;

  Future<List<OrganizationSummary>> list() async {
    final response = await _dio.get<dynamic>('/organizations');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    final organizations = data['organizations'] as List<dynamic>;
    return organizations
        .map((organization) => OrganizationSummary.fromJson(organization as Map<String, dynamic>))
        .toList();
  }

  Future<OrganizationDetail> create(String name) async {
    final response = await _dio.post<dynamic>('/organizations', data: {'name': name});
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return OrganizationDetail.fromJson(data['organization'] as Map<String, dynamic>);
  }

  Future<OrganizationDetail> detail(String organizationId) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return OrganizationDetail.fromJson(data['organization'] as Map<String, dynamic>);
  }

  Future<OrganizationDetail> update(String organizationId, String name) async {
    final response = await _dio.patch<dynamic>('/organizations/$organizationId', data: {'name': name});
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return OrganizationDetail.fromJson(data['organization'] as Map<String, dynamic>);
  }
}
