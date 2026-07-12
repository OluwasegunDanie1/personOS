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

/// Mirrors the narrower Create/Detail/Update Organization response shape
/// exactly: {id, name} only — no industry/logoUrl/country/timezone/etc.
class OrganizationDetail {
  const OrganizationDetail({required this.id, required this.name});

  final String id;
  final String name;

  factory OrganizationDetail.fromJson(Map<String, dynamic> json) =>
      OrganizationDetail(id: json['id'] as String, name: json['name'] as String);
}
