// Colocated tests are dev-only and are never imported by the application.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/features/auth/auth_repository.dart';
import 'package:devventory_app/features/auth/auth_controller.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

import 'fake_auth_repository.dart';

void main() {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'failed reauthentication cannot unblock an old cached SDK session',
    () async {
      const session = AccountSession(
        uid: 'user-one',
        email: 'one@example.test',
        emailVerified: true,
      );
      final repo = FakeAuthRepository(session);
      final controller = AuthController(repo);
      await settle();
      repo.tokenFailure = const ApiFailure(ApiFailureKind.unauthorized);
      await controller.refreshSession();
      repo.failure = const AuthFailure('invalid-credential');
      await controller.signIn('one@example.test', 'wrong-password');
      repo.emit(session);
      await settle();
      expect(controller.session, isNull);
      repo.failure = null;
      repo.tokenFailure = null;
      await controller.signIn('one@example.test', 'correct-emulator-password');
      expect(controller.session?.uid, 'user-one');
      controller.dispose();
      await repo.dispose();
    },
  );

  test(
    'verification stays gated until the new token finishes refreshing',
    () async {
      final token = Completer<String?>();
      final repo =
          FakeAuthRepository(
              const AccountSession(
                uid: 'one',
                email: 'one@example.test',
                emailVerified: false,
              ),
            )
            ..verifiedOnReload = true
            ..tokenResult = token;
      final controller = AuthController(repo);
      await settle();
      final refresh = controller.refreshSession();
      await settle();
      expect(controller.session?.emailVerified, isTrue);
      expect(controller.needsVerification, isTrue);
      token.complete('refreshed');
      await refresh;
      expect(controller.needsVerification, isFalse);
      controller.dispose();
      await repo.dispose();
    },
  );

  test('late session reload never restores a previous account', () async {
    const one = AccountSession(
      uid: 'one',
      email: 'one@example.test',
      emailVerified: true,
    );
    const two = AccountSession(
      uid: 'two',
      email: 'two@example.test',
      emailVerified: true,
    );
    final pending = Completer<AccountSession?>();
    final repo = FakeAuthRepository(one)..reloadAction = () => pending.future;
    final controller = AuthController(repo);
    await settle();
    final refresh = controller.refreshSession();
    repo.emit(two);
    await settle();
    pending.complete(one);
    await refresh;
    expect(controller.session?.uid, 'two');
    controller.dispose();
    await repo.dispose();
  });

  test(
    'a rejected refreshed token gates the session until explicit sign-in',
    () async {
      const session = AccountSession(
        uid: 'one',
        email: 'synthetic@example.test',
        emailVerified: true,
      );
      final repo = FakeAuthRepository(session);
      final controller = AuthController(repo);
      await settle();
      repo.tokenFailure = const ApiFailure(ApiFailureKind.unauthorized);
      await controller.refreshSession();
      expect(controller.session, isNull);
      // Even a late cached SDK event cannot restore a locally rejected session.
      repo.emit(session);
      await settle();
      expect(controller.session, isNull);
      expect(controller.error, contains('Sign in again'));
      controller.dispose();
      await repo.dispose();
    },
  );

  test(
    'restores a session without requesting a password or sending email',
    () async {
      final repo = FakeAuthRepository(
        const AccountSession(
          uid: 'one',
          email: 'synthetic@example.test',
          emailVerified: true,
        ),
      );
      final controller = AuthController(repo);
      expect(controller.restoring, isTrue);
      await settle();
      expect(controller.session?.uid, 'one');
      expect(controller.restoring, isFalse);
      expect(repo.sentVerification, 0);
      expect(repo.sentReset, 0);
      controller.dispose();
      await repo.dispose();
    },
  );

  test(
    'verification reload refreshes token before admitting the workspace',
    () async {
      final repo = FakeAuthRepository();
      final controller = AuthController(repo);
      await settle();
      await controller.signIn('synthetic@example.test', 'not-real');
      expect(controller.needsVerification, isTrue);
      repo.verifiedOnReload = true;
      await controller.refreshSession();
      expect(controller.needsVerification, isFalse);
      expect(repo.forcedRefreshes, 1);
      controller.dispose();
      await repo.dispose();
    },
  );

  test(
    'temporary failures preserve session and sign-out failure is recoverable',
    () async {
      final repo = FakeAuthRepository(
        const AccountSession(
          uid: 'one',
          email: 'synthetic@example.test',
          emailVerified: true,
        ),
      );
      final controller = AuthController(repo);
      await settle();
      repo.failure = const AuthFailure('network-request-failed');
      await controller.refreshSession();
      expect(controller.session?.uid, 'one');
      expect(controller.error, isNotNull);
      await controller.signOut();
      expect(controller.session?.uid, 'one');
      expect(controller.signingOut, isFalse);
      repo.failure = null;
      await controller.signOut();
      expect(controller.session, isNull);
      controller.dispose();
      await repo.dispose();
    },
  );

  test(
    'reset is generic and verification resend is locally throttled',
    () async {
      final repo = FakeAuthRepository(
        const AccountSession(
          uid: 'one',
          email: 'synthetic@example.test',
          emailVerified: false,
        ),
      );
      final controller = AuthController(repo);
      await settle();
      await controller.resetPassword('synthetic@example.test');
      expect(controller.notice, contains('If an account'));
      await controller.resendVerification();
      await controller.resendVerification();
      expect(repo.sentVerification, 1);
      controller.dispose();
      await repo.dispose();
    },
  );
}
