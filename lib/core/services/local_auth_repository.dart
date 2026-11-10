import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  final _uuid = const Uuid();
  final Map<String, UserModel> _accountsByEmail = {};
  late final Future<void> _ready;

  LocalAuthRepository() {
    // Default guest/demo user ready for local MVP exploration
    _currentUser = UserModel(
      uid: 'demo_learner_1',
      email: 'learner@basalino.ph',
      nickname: 'BasalinoLearner',
      preferredLanguage: 'en',
      approvalStatus: ApprovalStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    _ready = _initialize();
  }

  @override
  Stream<UserModel?> get authStateChanges async* {
    await _ready;
    yield _currentUser;
    yield* _controller.stream;
  }

  static const _accountsKey = 'basalino.localAccounts.v1';

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<void> _initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final savedAccounts = preferences.getString(_accountsKey);
    if (savedAccounts != null) {
      final decoded = jsonDecode(savedAccounts);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Saved local accounts are invalid.');
      }
      for (final entry in decoded.entries) {
        if (entry.value is! Map) {
          throw const FormatException('Saved local account is invalid.');
        }
        final account = Map<String, dynamic>.from(entry.value as Map);
        final email = account['email'];
        final uid = account['uid'];
        if (email is! String || uid is! String || uid.isEmpty) {
          throw const FormatException(
            'Saved local account is missing its identity.',
          );
        }
        _accountsByEmail[_normalizeEmail(entry.key)] = UserModel(
          uid: uid,
          email: email,
          nickname: account['nickname'] as String? ?? email.split('@').first,
          preferredLanguage: account['preferredLanguage'] as String? ?? 'en',
          approvalStatus: ApprovalStatus.approved,
          createdAt:
              DateTime.tryParse(account['createdAt'] as String? ?? '') ??
              DateTime.now(),
        );
      }
    }

    final demoEmail = _normalizeEmail(_currentUser!.email);
    _accountsByEmail.putIfAbsent(demoEmail, () => _currentUser!);
    await _saveAccounts();
  }

  Future<void> _saveAccounts() async {
    final preferences = await SharedPreferences.getInstance();
    final accounts = <String, dynamic>{};
    for (final entry in _accountsByEmail.entries) {
      final account = entry.value;
      accounts[entry.key] = {
        'email': account.email,
        'uid': account.uid,
        'nickname': account.nickname,
        'preferredLanguage': account.preferredLanguage,
        'createdAt': account.createdAt.toIso8601String(),
      };
    }
    final saved = await preferences.setString(
      _accountsKey,
      jsonEncode(accounts),
    );
    if (!saved) {
      throw StateError('Could not save local learner accounts.');
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _ready;
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _accountsByEmail[_normalizeEmail(email)];
    if (user == null) {
      throw StateError('No local account exists for this email.');
    }
    _currentUser = user;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await _ready;
    await Future.delayed(const Duration(milliseconds: 300));
    final normalizedEmail = _normalizeEmail(email);
    if (_accountsByEmail.containsKey(normalizedEmail)) {
      throw StateError('A local account already exists for this email.');
    }
    final user = UserModel(
      uid: _uuid.v4(),
      email: email,
      nickname: nickname,
      preferredLanguage: 'en',
      approvalStatus: ApprovalStatus.approved,
      createdAt: DateTime.now(),
    );
    _accountsByEmail[normalizedEmail] = user;
    await _saveAccounts();
    _currentUser = user;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await _ready;
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await _ready;
    return _currentUser;
  }

}
