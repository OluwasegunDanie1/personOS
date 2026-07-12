// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart'
    hide Options;
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/app/app.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/core/storage/app_preferences.dart';
import 'package:relvio/core/storage/secure_token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('an unauthenticated device boots through splash to the sign-in screen', (WidgetTester tester) async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(SecureTokenStorage(const FlutterSecureStorage())),
          appPreferencesProvider.overrideWithValue(AppPreferences(SharedPreferencesAsync())),
        ],
        child: const RelvioApp(),
      ),
    );

    // First frame: session restoration is still pending, so the splash
    // screen (the Relvio wordmark, no sign-in form yet) must be shown
    // rather than any authenticated content.
    expect(find.text('Relvio'), findsOneWidget);
    expect(find.text('Welcome back.'), findsNothing);

    await tester.pumpAndSettle();

    // No stored tokens means restoration resolves to unauthenticated, which
    // must redirect to sign-in rather than stranding the user on splash.
    expect(find.text('Welcome back.'), findsOneWidget);
  });
}
