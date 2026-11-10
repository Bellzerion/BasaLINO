import 'dart:convert';

import 'package:basalino/core/models/sync_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SyncEvent round-trips and deeply freezes payload data', () {
    final source = <String, Object?>{
      'attempt': <String, Object?>{'score': 95},
      'questionIds': <Object?>['q1', 'q2'],
    };
    final event = SyncEvent(
      eventId: 'event-1',
      userId: 'user-1',
      deviceId: 'device-1',
      type: SyncEventType.quizAttemptSubmitted,
      aggregateId: 'story-1',
      occurredAt: DateTime.utc(2026, 11, 10),
      schemaVersion: 1,
      payload: source,
    );
    source['later'] = true;

    expect(event.toMap()['type'], 'quiz_attempt_submitted');
    final restored = SyncEvent.fromMap(event.toMap());
    expect(restored.type, SyncEventType.quizAttemptSubmitted);
    expect(restored.occurredAt.isUtc, isTrue);
    expect(restored.payload.containsKey('later'), isFalse);
    expect(
      () => (restored.payload['attempt'] as Map<String, Object?>)['score'] = 1,
      throwsUnsupportedError,
    );
    expect(
      () => (restored.payload['questionIds'] as List<Object?>).add('q3'),
      throwsUnsupportedError,
    );
  });

  test('bundled translations share stable vocabulary identities', () async {
    final chapters = jsonDecode(
      await rootBundle.loadString('assets/data/chapters.json'),
    ) as List<dynamic>;
    final identityLanguages = <String, Set<String>>{};

    for (final chapter in chapters.cast<Map<String, dynamic>>()) {
      final translations = chapter['translations'] as Map<String, dynamic>;
      for (final languageEntry in translations.entries) {
        final hints =
            (languageEntry.value as Map<String, dynamic>)['vocabularyHints']
                as List<dynamic>;
        for (final hint in hints.cast<Map<String, dynamic>>()) {
          final vocabularyId = hint['vocabularyId'];
          expect(vocabularyId, isA<String>());
          expect((vocabularyId as String).trim(), isNotEmpty);
          identityLanguages
              .putIfAbsent(vocabularyId, () => <String>{})
              .add(languageEntry.key);
        }
      }
    }

    expect(
      identityLanguages.values.any((languages) => languages.length > 1),
      isTrue,
    );
  });
}
