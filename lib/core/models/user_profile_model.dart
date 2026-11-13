import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'user_model.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.preferredLanguage,
    required this.approvalStatus,
    required this.totalXp,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String preferredLanguage;
  final ApprovalStatus approvalStatus;
  final int totalXp;
  final DateTime createdAt;

  factory UserProfile.fromMap(String documentId, Map<String, dynamic> map) {
    final uid = map['uid'];
    if (uid is! String || uid != documentId) {
      throw const FormatException('Profile UID does not match its document.');
    }

    final email = map['email'];
    final displayName = map['displayName'] ?? map['nickname'];
    final preferredLanguage = map['preferredLanguage'];
    final rawApprovalStatus = map['approvalStatus'];
    final rawTotalXp = map['totalXp'];
    if (email is! String ||
        preferredLanguage is! String ||
        !{'en', 'tl', 'bik'}.contains(preferredLanguage) ||
        (displayName != null && displayName is! String) ||
        (rawTotalXp != null && (rawTotalXp is! int || rawTotalXp < 0))) {
      throw const FormatException('Profile fields are missing or invalid.');
    }

    final approvalStatus = switch (rawApprovalStatus) {
      'pending' => ApprovalStatus.pending,
      'approved' => ApprovalStatus.approved,
      'rejected' => ApprovalStatus.rejected,
      _ => throw const FormatException('Profile approvalStatus is invalid.'),
    };
    final createdAt = _readDateTime(map['createdAt']);
    if (createdAt == null) {
      throw const FormatException('Profile createdAt is missing or invalid.');
    }

    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName as String?,
      preferredLanguage: preferredLanguage,
      approvalStatus: approvalStatus,
      totalXp: rawTotalXp as int? ?? 0,
      createdAt: createdAt,
    );
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    preferredLanguage,
    approvalStatus,
    totalXp,
    createdAt,
  ];
}
