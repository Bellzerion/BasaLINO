import 'dart:convert';

import 'package:basalino/features/explore/presentation/explore_scene_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'animated Mayon model is bundled with its local animation data',
    () async {
      final model = jsonDecode(
        await rootBundle.loadString('assets/models/mount_mayon_animated.gltf'),
      ) as Map<String, dynamic>;
      final buffer = (model['buffers'] as List<dynamic>).single;
      final animation = (model['animations'] as List<dynamic>).single;

      expect(model['asset']['version'], '2.0');
      expect(
        (buffer as Map<String, dynamic>)['uri'],
        startsWith('data:application/octet-stream;base64,'),
      );
      expect(
        (animation as Map<String, dynamic>)['name'],
        'Mayon_Eruption_Loop',
      );
    },
  );

  testWidgets('Mayon exploration landing explains and starts the experience', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreSceneScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Explore in AR-Style'), findsOneWidget);
    expect(find.text('Mayon Volcano'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bikol legend'), findsOneWidget);
  });
}
