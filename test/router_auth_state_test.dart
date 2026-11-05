import 'package:basalino/app/bootstrap/providers.dart';
import 'package:basalino/app/router/app_router.dart';
import 'package:basalino/core/services/local_auth_repository.dart';
import 'package:basalino/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:basalino/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'XP updates preserve router and current route; sign-out still redirects',
    (tester) async {
      final authRepository = LocalAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          currentUserProvider.overrideWith(
            (ref) => UserModel(
              uid: 'test-user',
              email: 'test@example.com',
              nickname: 'Tester',
              preferredLanguage: 'en',
              approvalStatus: ApprovalStatus.approved,
              totalXp: 0,
              createdAt: DateTime(2026),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');

      await authRepository.addXp(5);
      await tester.pumpAndSettle();

      expect(identical(container.read(routerProvider), router), isTrue);
      expect(router.routeInformationProvider.value.uri.path, '/profile');

      await authRepository.signOut();
      await tester.pumpAndSettle();
      expect(container.read(authRoutingStateProvider), isNull);
      expect(router.routeInformationProvider.value.uri.path, '/login');
    },
  );
}
