import 'package:basalino/core/models/cloud_progress_model.dart';
import 'package:basalino/core/models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserProfile maps Firestore fields into an immutable model', () {
    final createdAt = DateTime.utc(2026, 11, 10);
    final profile = UserProfile.fromMap('user-1', {
      'uid': 'user-1',
      'email': 'reader@example.com',
      'nickname': 'Reader',
      'preferredLanguage': 'en',
      'approvalStatus': 'approved',
      'totalXp': 120,
      'createdAt': Timestamp.fromDate(createdAt),
    });

    expect(profile.uid, 'user-1');
    expect(profile.email, 'reader@example.com');
    expect(profile.nickname, 'Reader');
    expect(profile.preferredLanguage, 'en');
    expect(profile.approvalStatus.name, 'approved');
    expect(profile.totalXp, 120);
    expect(profile.createdAt.isAtSameMomentAs(createdAt), isTrue);
  });

  test('CloudProgress maps Firestore counts and timestamp', () {
    final lastUpdated = DateTime.utc(2026, 11, 10, 8);
    final profile = <String, dynamic>{
      'uid': 'user-1',
      'totalXp': 125,
      'createdAt': Timestamp.fromDate(lastUpdated),
    };
    final storyProgress = <Map<String, dynamic>>[
      {
        'storyId': 'story-1',
        'isStoryCompleted': true,
        'completedChapterIds': ['chapter-1', 'chapter-2'],
        'vocabularyWordsPracticed': 3,
        'updatedAt': Timestamp.fromDate(lastUpdated),
      },
      {
        'storyId': 'story-2',
        'isStoryCompleted': true,
        'completedChapterIds': ['chapter-1'],
        'vocabularyWordsPracticed': 2,
      },
    ];
    final progress = CloudProgress.fromCanonicalDocuments(
      uid: 'user-1',
      profile: profile,
      storyProgress: storyProgress,
    );

    expect(progress.uid, 'user-1');
    expect(progress.xp, 125);
    expect(progress.storiesCompleted, 2);
    expect(progress.chaptersCompleted, 3);
    expect(progress.vocabularyPracticed, 5);
    expect(progress.lastUpdated!.isAtSameMomentAs(lastUpdated), isTrue);
  });

  test('model mapping rejects data belonging to a different document UID', () {
    expect(
      () => CloudProgress.fromCanonicalDocuments(
        uid: 'user-1',
        profile: {'uid': 'user-2'},
        storyProgress: const [],
      ),
      throwsFormatException,
    );
    expect(
      () => UserProfile.fromMap('user-1', {
        'email': 'reader@example.com',
        'nickname': 'Reader',
        'preferredLanguage': 'en',
        'approvalStatus': 'approved',
        'totalXp': 0,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 10)),
      }),
      throwsFormatException,
    );
    expect(
      () => UserProfile.fromMap('user-1', {
        'uid': 'user-1',
        'email': 'reader@example.com',
        'nickname': 'Reader',
        'preferredLanguage': 'en',
        'approvalStatus': 'approved',
        'totalXp': 1.5,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 10)),
      }),
      throwsFormatException,
    );
  });
}
