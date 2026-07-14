import 'package:dio/dio.dart';

import '../../core/api/api_envelope.dart';
import 'organization_models.dart';

/// Integrates the actual implemented Organization endpoints only:
/// GET/POST /organizations, GET/PATCH /organizations/:organizationId, and
/// (Product Task 050/052) the read-only GET .../members, GET .../roles, and
/// GET .../permissions endpoints. Does not implement Delete Organization
/// (deferred/unresolved) or any Invite/Remove-Member/Update-Member-Role/
/// Create-Update-Delete-Role/Assign-Permission endpoint — none of those are
/// approved v1 authority.
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

  /// Integrates the real, implemented GET
  /// /organizations/:organizationId/members endpoint (Product Task 050,
  /// integrated by Product Task 052). Read-only: no invite, remove, or
  /// role-change method exists here, matching approved authority exactly.
  Future<List<OrganizationMemberSummary>> listMembers(String organizationId) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId/members');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return (data['members'] as List<dynamic>)
        .map((member) => OrganizationMemberSummary.fromJson(member as Map<String, dynamic>))
        .toList();
  }

  /// Integrates the real, implemented GET /organizations/:organizationId/roles
  /// endpoint (Product Task 050, integrated by Product Task 052). Each
  /// role's permissions are already embedded in this response via the real
  /// RolePermission join — read-only: no create/update/delete method exists
  /// here.
  Future<List<RoleSummary>> listRoles(String organizationId) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId/roles');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return (data['roles'] as List<dynamic>)
        .map((role) => RoleSummary.fromJson(role as Map<String, dynamic>))
        .toList();
  }

  /// Integrates the real, implemented GET
  /// /organizations/:organizationId/permissions endpoint (Product Task 050).
  /// Returns exactly the distinct Permission rows currently assigned, via
  /// RolePermission, to any Role in the validated organization — never the
  /// full global platform catalogue. Not currently consumed by any screen
  /// (Product Task 052's Roles & Permissions screen uses each role's own
  /// already-embedded `permissions` field from listRoles() instead, since
  /// that alone fully supports the frozen per-role permissions composition);
  /// provided here so the Flutter API layer mirrors the full approved
  /// backend contract 1:1.
  Future<List<PermissionSummary>> listPermissions(String organizationId) async {
    final response = await _dio.get<dynamic>('/organizations/$organizationId/permissions');
    final data = unwrapEnvelope(response) as Map<String, dynamic>;
    return (data['permissions'] as List<dynamic>)
        .map((permission) => PermissionSummary.fromJson(permission as Map<String, dynamic>))
        .toList();
  }
}
