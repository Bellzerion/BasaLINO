import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  final _uuid = const Uuid();

  LocalAuthRepository() {
    // Default guest/demo user ready for local MVP exploration
    _currentUser = UserModel(
      uid: 'demo_learner_1',
      email: 'learner@basalino.ph',
      nickname: 'BasalinoLearner',
      preferredLanguage: 'en',
      approvalStatus: ApprovalStatus.approved,
      totalXp: 45,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    _controller.add(_currentUser);
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = UserModel(
      uid: 'user_${email.hashCode}',
      email: email,
      nickname: email.split('@').first,
      preferredLanguage: 'en',
      approvalStatus: ApprovalStatus.approved,
      totalXp: 0,
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = UserModel(
      uid: _uuid.v4(),
      email: email,
      nickname: nickname,
      preferredLanguage: 'en',
      approvalStatus: ApprovalStatus.approved,
      totalXp: 0,
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  void updateLanguage(String lang) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(preferredLanguage: lang);
      // A language choice is presentation state, not an authentication
      // change. Emitting here rebuilt GoRouter and reset the active reader
      // route to its initial home location.
    }
  }

  @override
  void addXp(int xp) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(totalXp: _currentUser!.totalXp + xp);
      _controller.add(_currentUser);
    }
  }
}
