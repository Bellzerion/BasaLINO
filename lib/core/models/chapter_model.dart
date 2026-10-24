// lib/core/models/chapter_model.dart
import 'package:equatable/equatable.dart';

enum ChapterStatus { locked, unlocked, completed }

class ChapterModel extends Equatable {
  const ChapterModel({
    required this.id,
    required this.storyId,
    required this.orderIndex,
    required this.status,
    this.completedAt,
  });

  final String id;
  final String storyId;
  final int orderIndex;
  final ChapterStatus status;
  final DateTime? completedAt;

  bool get isLocked => status == ChapterStatus.locked;
  bool get isCompleted => status == ChapterStatus.completed;
  bool get isUnlocked => status == ChapterStatus.unlocked;

  factory ChapterModel.fromMap(String id, Map<String, dynamic> map) {
    return ChapterModel(
      id: id,
      storyId: map['storyId'] as String? ?? '',
      orderIndex: map['orderIndex'] as int? ?? 0,
      status: ChapterStatus.locked,
    );
  }

  ChapterModel copyWith({ChapterStatus? status, DateTime? completedAt}) {
    return ChapterModel(
      id: id,
      storyId: storyId,
      orderIndex: orderIndex,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, storyId, orderIndex, status];
}
