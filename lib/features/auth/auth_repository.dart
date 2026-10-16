import 'package:devventory_app/shared/network/session_token_provider.dart';

class AccountSession {
  const AccountSession({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });
  final String uid;
  final String? email;
  final bool emailVerified;
}

abstract interface class AuthRepository implements SessionTokenProvider {
  Stream<AccountSession?> get sessions;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<AccountSession?> reload();
  Future<void> sendVerification();
  Future<void> resetPassword(String email);
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);
  final String code;
  bool get requiresSignIn => const {
    'user-disabled',
    'user-not-found',
    'user-token-expired',
    'invalid-user-token',
    'no-current-user',
  }.contains(code);

  String get message => switch (code) {
    'invalid-email' => 'Enter a valid email address.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'The email or password is incorrect.',
    'user-disabled' => 'This account is disabled. Contact support or use another desktop account.',
    'network-request-failed' =>
      'Cannot reach the sign-in service. Check your connection and try again.',
    'too-many-requests' =>
      'Too many attempts. Please wait before trying again.',
    'operation-not-allowed' || 'app-not-authorized' || 'invalid-api-key' => 'Sign-in is not available for this build. Check the Firebase app configuration.',
    'user-token-expired' ||
    'invalid-user-token' ||
    'no-current-user' => 'Your session has expired. Sign in again.',
    _ => 'Something went wrong. Please try again.',
  };
}
