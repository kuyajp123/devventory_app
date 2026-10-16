import 'package:firebase_auth/firebase_auth.dart';
import 'package:devventory_app/features/auth/auth_repository.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

/// Firebase owns native credential persistence. No tokens are retained here.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;
  AccountSession? _session(User? user) => user == null
      ? null
      : AccountSession(
          uid: user.uid,
          email: user.email,
          emailVerified: user.emailVerified,
        );
  @override
  String? get userId => _auth.currentUser?.uid;
  @override
  Stream<AccountSession?> get sessions => _auth.userChanges().map(_session);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(error.code);
    }
  }

  @override
  Future<void> signIn(String email, String password) => _guard(() async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  });
  @override
  Future<void> signOut() => _guard(_auth.signOut);
  @override
  Future<AccountSession?> reload() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    if (user.uid != userId) throw const AuthFailure('no-current-user');
    return _session(_auth.currentUser);
  });
  @override
  Future<void> sendVerification() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('no-current-user');
    await user.sendEmailVerification();
  });
  @override
  Future<void> resetPassword(String email) async {
    try {
      await _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
    } on AuthFailure catch (error) {
      // Same UI outcome whether an email exists; do not reveal account membership.
      if (error.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } on FirebaseAuthException catch (error) {
      final auth = AuthFailure(error.code);
      if (auth.requiresSignIn) {
        throw const ApiFailure(ApiFailureKind.unauthorized);
      }
      if (error.code == 'network-request-failed') {
        throw const ApiFailure(ApiFailureKind.offline);
      }
      throw const ApiFailure(ApiFailureKind.unavailable);
    }
  }
}
