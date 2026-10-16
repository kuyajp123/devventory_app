import 'dart:async';

import 'package:devventory_app/features/auth/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([this.account]);
  AccountSession? account;
  final changes = StreamController<AccountSession?>.broadcast(sync: true);
  AuthFailure? failure;
  Object? tokenFailure;
  Completer<String?>? tokenResult;
  Future<AccountSession?> Function()? reloadAction;
  bool verifiedOnReload = false;
  int forcedRefreshes = 0;
  int sentVerification = 0;
  int sentReset = 0;
  @override
  String? get userId => account?.uid;
  @override
  Stream<AccountSession?> get sessions async* {
    yield account;
    yield* changes.stream;
  }

  void emit(AccountSession? value) {
    account = value;
    changes.add(value);
  }

  void check() {
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signIn(String email, String password) async {
    check();
    emit(AccountSession(uid: 'user-one', email: email, emailVerified: false));
  }

  @override
  Future<void> signOut() async {
    check();
    emit(null);
  }

  @override
  Future<AccountSession?> reload() async {
    check();
    if (reloadAction != null) return reloadAction!();
    if (account != null && verifiedOnReload) {
      emit(
        AccountSession(
          uid: account!.uid,
          email: account!.email,
          emailVerified: true,
        ),
      );
    }
    return account;
  }

  @override
  Future<void> sendVerification() async {
    check();
    sentVerification++;
  }

  @override
  Future<void> resetPassword(String email) async {
    check();
    sentReset++;
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    check();
    if (tokenFailure != null) throw tokenFailure!;
    if (forceRefresh) forcedRefreshes++;
    if (tokenResult != null) return tokenResult!.future;
    return account == null ? null : 'test-only-token';
  }

  Future<void> dispose() => changes.close();
}
