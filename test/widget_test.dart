import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:basalino/app/bootstrap/providers.dart';
import 'package:basalino/core/config/auth_mode.dart';
import 'package:basalino/main.dart';

void main() {
  testWidgets('BasaLINO app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authModeProvider.overrideWithValue(AuthMode.local)],
        child: BasaLinoApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(BasaLinoApp), findsOneWidget);
  });
}
