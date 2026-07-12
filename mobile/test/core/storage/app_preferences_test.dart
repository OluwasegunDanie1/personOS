// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/storage/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';

void main() {
  late AppPreferences preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    preferences = AppPreferences(SharedPreferencesAsync());
  });

  test('reads return null before anything is saved', () async {
    expect(await preferences.readSelectedOrganizationId(), isNull);
    expect(await preferences.readCachedUserJson(), isNull);
  });

  test('persists and clears the selected organization id', () async {
    await preferences.saveSelectedOrganizationId('org-1');
    expect(await preferences.readSelectedOrganizationId(), 'org-1');

    await preferences.clearSelectedOrganizationId();
    expect(await preferences.readSelectedOrganizationId(), isNull);
  });

  test('persists and clears the cached PublicUser JSON', () async {
    final userJson = {'id': 'user-1', 'email': 'ada@example.com'};
    await preferences.saveCachedUserJson(userJson);

    expect(await preferences.readCachedUserJson(), userJson);

    await preferences.clearCachedUser();
    expect(await preferences.readCachedUserJson(), isNull);
  });
}
