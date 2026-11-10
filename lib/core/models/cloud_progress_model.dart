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
  }) {
    if (profile?['uid'] is String && profile!['uid'] != uid) {
      throw const FormatException('Progress UID does not match its document.');
    }

    var storiesCompleted = 0;
    var chaptersCompleted = 0;
    var vocabularyPracticed = 0;
    DateTime? lastUpdated = _readDateTime(
      profile?['updatedAt'] ?? profile?['createdAt'],
    );
    for (final story in storyProgress) {
      if (story['isStoryCompleted'] == true) storiesCompleted++;
      final completed = story['completedChapterIds'];
      if (completed is List) chaptersCompleted += completed.length;
      vocabularyPracticed += _readInt(story['vocabularyWordsPracticed']);
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
      vocabularyPracticed: vocabularyPracticed,
      lastUpdated: lastUpdated,
    );
  }

  static int _readInt(Object? value) => value is num ? value.toInt() : 0;

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

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
