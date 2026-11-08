import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}

AuthRepositoryException mapFirebaseAuthException(FirebaseAuthException error) {
  final message = switch (error.code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'email-already-in-use' => 'An account already exists for this email.',
    'weak-password' => 'Choose a stronger password.',
    'user-disabled' => 'This account is disabled.',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'network-request-failed' => 'Could not connect. Check your connection.',
    _ => 'Authentication failed. Please try again.',
  };
  return AuthRepositoryException(code: error.code, message: message);
}
