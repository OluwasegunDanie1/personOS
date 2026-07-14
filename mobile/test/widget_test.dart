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
  testWidgets('an unauthenticated device boots through splash into onboarding, Welcome, and Sign In', (
    WidgetTester tester,
  ) async {
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
    // must redirect into the onboarding carousel (Product Task 077) — there
    // is no persisted "has seen onboarding" flag, so this is always the
    // pre-auth entry point.
    expect(find.text('Organize everything in one place.'), findsOneWidget);
    expect(find.text('Welcome back.'), findsNothing);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Skip jumps directly to the carousel's frozen 4th panel ("Let's get
    // started."), not to any other screen.
    expect(find.text("Let's get started."), findsOneWidget);

    await tester.tap(find.text('Already a member? Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
  });
}
