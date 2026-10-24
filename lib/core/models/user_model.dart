// lib/core/models/user_model.dart
import 'package:equatable/equatable.dart';

enum ApprovalStatus { pending, approved, rejected }

class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.preferredLanguage,
    required this.approvalStatus,
    required this.totalXp,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String nickname;
  final String preferredLanguage;
  final ApprovalStatus approvalStatus;
  final int totalXp;
  final DateTime createdAt;

  bool get isApproved => approvalStatus == ApprovalStatus.approved;

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    ApprovalStatus status;
    switch (map['approvalStatus'] as String? ?? 'pending') {
      case 'approved':
        status = ApprovalStatus.approved;
        break;
      case 'rejected':
        status = ApprovalStatus.rejected;
        break;
      default:
        status = ApprovalStatus.pending;
    }
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      preferredLanguage: map['preferredLanguage'] as String? ?? 'en',
      approvalStatus: status,
      totalXp: map['totalXp'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate() as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'nickname': nickname,
        'preferredLanguage': preferredLanguage,
        'approvalStatus': approvalStatus.name,
        'totalXp': totalXp,
      };

  UserModel copyWith({
    String? nickname,
    String? preferredLanguage,
    ApprovalStatus? approvalStatus,
    int? totalXp,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      nickname: nickname ?? this.nickname,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      totalXp: totalXp ?? this.totalXp,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [uid, nickname, preferredLanguage, approvalStatus, totalXp];
}
