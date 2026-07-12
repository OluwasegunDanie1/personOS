import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret, client-side-only app state: the selected organizationId
/// (contextual, not a server-side session — see 16_Security.md's Organization
/// Context Mechanism) and the cached PublicUser profile returned by login.
/// PublicUser contains no auth token or password material, so plain
/// SharedPreferences is an approved storage location for it.
class AppPreferences {
  AppPreferences([SharedPreferencesAsync? preferences]) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const _selectedOrganizationIdKey = 'relvio.organization.selectedId';
  static const _cachedUserKey = 'relvio.auth.cachedUser';

  Future<void> saveSelectedOrganizationId(String organizationId) =>
      _preferences.setString(_selectedOrganizationIdKey, organizationId);

  Future<String?> readSelectedOrganizationId() => _preferences.getString(_selectedOrganizationIdKey);

  Future<void> clearSelectedOrganizationId() => _preferences.remove(_selectedOrganizationIdKey);

  Future<void> saveCachedUserJson(Map<String, dynamic> userJson) =>
      _preferences.setString(_cachedUserKey, jsonEncode(userJson));

  Future<Map<String, dynamic>?> readCachedUserJson() async {
    final raw = await _preferences.getString(_cachedUserKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearCachedUser() => _preferences.remove(_cachedUserKey);
}
