import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CloudProgress extends Equatable {
  const CloudProgress({
    required this.uid,
    required this.xp,
    required this.storiesCompleted,
    required this.chaptersCompleted,
    required this.vocabularyPracticed,
    required this.lastUpdated,
  });

  final String uid;
  final int xp;
  final int storiesCompleted;
  final int chaptersCompleted;
  final int vocabularyPracticed;
  final DateTime? lastUpdated;

  factory CloudProgress.fromCanonicalDocuments({
    required String uid,
    required Map<String, dynamic>? profile,
    required Iterable<Map<String, dynamic>> storyProgress,
    required Iterable<Map<String, dynamic>> chapterMetadata,
  }) {
    if (profile?['uid'] is String && profile!['uid'] != uid) {
      throw const FormatException('Progress UID does not match its document.');
    }

    var storiesCompleted = 0;
    var chaptersCompleted = 0;
    DateTime? lastUpdated = _readDateTime(
      profile?['updatedAt'] ?? profile?['createdAt'],
    );
    final chaptersByStory = <String, Set<String>>{};
    for (final chapter in chapterMetadata) {
      final storyId = chapter['storyId'];
      final chapterId = chapter['id'];
      if (storyId is String && chapterId is String) {
        chaptersByStory.putIfAbsent(storyId, () => <String>{}).add(chapterId);
      }
    }

    for (final story in storyProgress) {
      final storyId = story['storyId'];
      final completed = story['completedChapterIds'];
      final completedIds = completed is List
          ? completed.whereType<String>().toSet()
          : <String>{};
      chaptersCompleted += completedIds.length;
      final storyChapterIds = storyId is String
          ? chaptersByStory[storyId]
          : null;
      if (storyChapterIds != null &&
          storyChapterIds.isNotEmpty &&
          storyChapterIds.every(completedIds.contains)) {
        storiesCompleted++;
      }
      final updatedAt = _readDateTime(story['updatedAt']);
      if (updatedAt != null &&
          (lastUpdated == null || updatedAt.isAfter(lastUpdated))) {
        lastUpdated = updatedAt;
      }
    }

    return CloudProgress(
      uid: uid,
      xp: _readInt(profile?['totalXp']),
      storiesCompleted: storiesCompleted,
      chaptersCompleted: chaptersCompleted,
      vocabularyPracticed: 0,
      lastUpdated: lastUpdated,
    );
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int _readInt(Object? value) => value is int && value >= 0 ? value : 0;

  @override
  List<Object?> get props => [
    uid,
    xp,
    storiesCompleted,
    chaptersCompleted,
    vocabularyPracticed,
    lastUpdated,
  ];
}
