/// Mirrors GET /organizations' per-membership shape exactly:
/// {id, name, logoUrl, role:{id,name}}.
class OrganizationRole {
  const OrganizationRole({required this.id, required this.name});

  final String id;
  final String name;

  factory OrganizationRole.fromJson(Map<String, dynamic> json) =>
      OrganizationRole(id: json['id'] as String, name: json['name'] as String);
}

class OrganizationSummary {
  const OrganizationSummary({required this.id, required this.name, required this.logoUrl, required this.role});

  final String id;
  final String name;
  final String? logoUrl;
  final OrganizationRole role;

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) => OrganizationSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    logoUrl: json['logoUrl'] as String?,
    role: OrganizationRole.fromJson(json['role'] as Map<String, dynamic>),
  );
}

/// Mirrors the real Create/Detail/Update Organization response shape exactly:
/// {id, name, industry, country, timezone} (Product Task 092). logoUrl,
/// email, phone, address, and subscriptionPlan remain excluded — none of
/// those is approved API authority.
class OrganizationDetail {
  const OrganizationDetail({
    required this.id,
    required this.name,
    required this.industry,
    required this.country,
    required this.timezone,
  });

  final String id;
  final String name;
  final String? industry;
  final String? country;
  final String? timezone;

  factory OrganizationDetail.fromJson(Map<String, dynamic> json) => OrganizationDetail(
    id: json['id'] as String,
    name: json['name'] as String,
    industry: json['industry'] as String?,
    country: json['country'] as String?,
    timezone: json['timezone'] as String?,
  );
}

/// Mirrors GET /organizations/:organizationId/members' per-user shape
/// exactly: {id, firstName, lastName, email} (Product Task 050/052). No
/// phone or avatar exists on this contract — neither is invented here.
class OrganizationMemberUser {
  const OrganizationMemberUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  String get displayName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return ('$first$last').toUpperCase();
  }

  factory OrganizationMemberUser.fromJson(Map<String, dynamic> json) => OrganizationMemberUser(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
  );
}

/// Mirrors GET /organizations/:organizationId/members' approved response
/// shape exactly: {membershipId, user:{id,firstName,lastName,email},
/// role:{id,name}}. No status, invite state, permissions summary, phone, or
/// activity field exists on this contract — none of those are invented here
/// (Product Task 050's approved read authority; Product Task 052 integrates
/// it for the first time).
class OrganizationMemberSummary {
  const OrganizationMemberSummary({required this.membershipId, required this.user, required this.role});

  final String membershipId;
  final OrganizationMemberUser user;
  final OrganizationRole role;

  factory OrganizationMemberSummary.fromJson(Map<String, dynamic> json) => OrganizationMemberSummary(
    membershipId: json['membershipId'] as String,
    user: OrganizationMemberUser.fromJson(json['user'] as Map<String, dynamic>),
    role: OrganizationRole.fromJson(json['role'] as Map<String, dynamic>),
  );
}

/// Mirrors both the per-role embedded permission entries on GET
/// .../roles and the flat GET .../permissions response's own entries:
/// {id, name} only. No category, group, or description exists on Permission
/// — none is invented here (Product Task 050/052).
class PermissionSummary {
  const PermissionSummary({required this.id, required this.name});

  final String id;
  final String name;

  factory PermissionSummary.fromJson(Map<String, dynamic> json) =>
      PermissionSummary(id: json['id'] as String, name: json['name'] as String);
}

/// Mirrors GET /organizations/:organizationId/roles' approved response shape
/// exactly: {id, name, description, permissions:[{id,name}]}. permissions is
/// the real, already-embedded RolePermission join — never a separate
/// invented grouping. An empty permissions array is a real, truthful result
/// (Product Task 050/052), not a loading or error state.
class RoleSummary {
  const RoleSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
  });

  final String id;
  final String name;
  final String? description;
  final List<PermissionSummary> permissions;

  factory RoleSummary.fromJson(Map<String, dynamic> json) => RoleSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    permissions: (json['permissions'] as List<dynamic>)
        .map((permission) => PermissionSummary.fromJson(permission as Map<String, dynamic>))
        .toList(),
  );
}
