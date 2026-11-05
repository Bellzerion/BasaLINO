import 'package:basalino/app/bootstrap/providers.dart';
import 'package:basalino/app/router/app_router.dart';
import 'package:basalino/l10n/app_localizations_context.dart';
import 'package:basalino/l10n/generated/app_localizations.dart';
import 'package:basalino/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test(
    'story completion actions are translated in all supported languages',
    () async {
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final tagalog = await AppLocalizations.delegate.load(const Locale('tl'));
      final bikol = await AppLocalizations.delegate.load(const Locale('bik'));

      expect(english.storyCompletionReturnToMap, 'Return to Adventure Map');
      expect(
        tagalog.storyCompletionReturnToMap,
        'Bumalik sa Mapa ng Pakikipagsapalaran',
      );
      expect(
        bikol.storyCompletionReturnToMap,
        'Bumalik sa Mapa kan Pakikipagsapalaran',
      );
      expect(english.storyCompletionReplay, 'Replay Story');
      expect(tagalog.storyCompletionChapters, 'Mga Kabanatang Natapos');
      expect(bikol.storyCompletionDate, 'Petsa kan Pagtapos');
    },
  );

  testWidgets('language switching updates localized app text for all locales', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _LocalizationHome(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          appLanguageProvider.overrideWith((ref) => 'en'),
        ],
        child: const BasaLinoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reading becomes an adventure.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tagalog'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nagiging pakikipagsapalaran ang pagbabasa.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Bikol'));
    await tester.pumpAndSettle();
    expect(find.text('An pagbasa nagigin pakikipagsapalaran.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Reading becomes an adventure.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _LocalizationHome extends ConsumerWidget {
  const _LocalizationHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.loginTagline)),
      body: Column(
        children: [
          TextButton(
            onPressed: () {
              ref.read(appLanguageProvider.notifier).state = 'tl';
            },
            child: const Text('Tagalog'),
          ),
          TextButton(
            onPressed: () {
              ref.read(appLanguageProvider.notifier).state = 'bik';
            },
            child: const Text('Bikol'),
          ),
          TextButton(
            onPressed: () {
              ref.read(appLanguageProvider.notifier).state = 'en';
            },
            child: const Text('English'),
          ),
        ],
      ),
    );
  }
}
