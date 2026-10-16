import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:devventory_app/features/auth/auth_repository.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _subscription = _repository.sessions.listen(
      _accept,
      onError: (Object _) {
        restoring = false;
        error = 'Could not restore your session. Please try again.';
        _emit();
      },
    );
  }
  final AuthRepository _repository;
  final DateTime Function() _now;
  late final StreamSubscription<AccountSession?> _subscription;
  AccountSession? session;
  bool restoring = true;
  bool busy = false;
  bool signingOut = false;
  bool _serverNeedsVerification = false;
  bool _disposed = false;
  String? _blockedUid;
  int _accountRevision = 0;
  String? error;
  String? notice;
  DateTime? verificationRetryAt;
  bool get needsVerification =>
      session != null && (!session!.emailVerified || _serverNeedsVerification);

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _accept(AccountSession? value) {
    if (_disposed) return;
    if (value != null && value.uid == _blockedUid) return;
    if (value?.uid != session?.uid) {
      _accountRevision++;
      error = null;
      notice = null;
      verificationRetryAt = null;
      _serverNeedsVerification = false;
    }
    session = value;
    restoring = false;
    _emit();
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool accountScoped = false,
  }) async {
    if (busy || _disposed) return;
    final revision = _accountRevision;
    busy = true;
    error = null;
    notice = null;
    _emit();
    try {
      await action();
    } on AuthFailure catch (failure) {
      if (_disposed || (accountScoped && revision != _accountRevision)) return;
      if (failure.requiresSignIn && session != null && !signingOut) {
        await _rejectSession();
      }
      error = failure.message;
    } on ApiFailure catch (failure) {
      if (_disposed || (accountScoped && revision != _accountRevision)) return;
      if (failure.kind == ApiFailureKind.unauthorized) await _rejectSession();
      error = failure.message;
    } catch (_) {
      if (_disposed || (accountScoped && revision != _accountRevision)) return;
      error = 'Something went wrong. Please try again.';
    } finally {
      busy = false;
      signingOut = false;
      _emit();
    }
  }

  Future<void> _rejectSession() async {
    _blockedUid = session?.uid ?? _repository.userId;
    session = null;
    _accountRevision++;
    try {
      await _repository.signOut();
    } catch (_) {
      /* Keep the rejected session gated. */
    }
  }

  Future<void> signIn(String email, String password) => _run(() async {
    await _repository.signIn(email, password);
    // Only successful authentication may unblock a locally rejected identity.
    // Re-read the SDK's initial event in case its earlier event was gated.
    _blockedUid = null;
    _accept(await _repository.sessions.first);
  });

  Future<void> signOut() async {
    if (busy || _disposed) return;
    signingOut =
        true; // Hide/cancel the workspace before SDK sign-out completes.
    await _run(() async {
      await _repository.signOut();
    });
  }

  Future<void> refreshSession() async {
    if (busy || _disposed) return;
    final revision = _accountRevision;
    // Keep the verification screen mounted while reload emits an updated User.
    if (needsVerification) _serverNeedsVerification = true;
    await _run(() async {
      final refreshed = await _repository.reload();
      if (_disposed || revision != _accountRevision) return;
      if (refreshed != null && refreshed.emailVerified) {
        // reload() updates the User, but the cloud needs the new verified ID token.
        final token = await _repository.idToken(forceRefresh: true);
        if (_disposed || revision != _accountRevision) return;
        if (token == null) throw const ApiFailure(ApiFailureKind.unauthorized);
        _serverNeedsVerification = false;
      }
      _accept(refreshed);
      if (refreshed != null && !refreshed.emailVerified) {
        notice = 'Your email is not verified yet. Open the link in your inbox, then check again.';
      }
    }, accountScoped: true);
  }

  void requireVerification() {
    _serverNeedsVerification = true;
    _emit();
  }

  Future<void> resendVerification() => _run(() async {
    if (verificationRetryAt != null && _now().isBefore(verificationRetryAt!)) {
      notice = 'Please wait before sending another verification email.';
      return;
    }
    await _repository.sendVerification();
    verificationRetryAt = _now().add(const Duration(seconds: 60));
    notice = 'Verification email sent. Check your inbox and spam folder.';
  });

  Future<void> resetPassword(String email) => _run(() async {
    await _repository.resetPassword(email);
    notice = 'If an account exists for that email, a password reset link has been sent.';
  });

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
