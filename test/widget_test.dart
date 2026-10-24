import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:basalino/main.dart';

void main() {
  testWidgets('BasaLINO app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BasaLinoApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(BasaLinoApp), findsOneWidget);
  });
}
