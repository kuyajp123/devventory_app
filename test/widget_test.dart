import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/app/bootstrap_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/auth/tests/fake_auth_repository.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

class FakeWorkspaceRepository implements WorkspaceRepository {
  FakeWorkspaceRepository({
    this.workspace = const Workspace(id: null, publisherId: null),
    this.failure,
  });
  Workspace workspace;
  ApiFailure? failure;
  int requests = 0;
  @override
  Future<Workspace> discover({CancelToken? cancelToken}) async {
    requests++;
    if (failure != null) throw failure!;
    return workspace;
  }
}

class PendingWorkspaces implements WorkspaceRepository {
  final results = <Completer<Workspace>>[];
  final tokens = <CancelToken?>[];
  @override
  Future<Workspace> discover({CancelToken? cancelToken}) {
    tokens.add(cancelToken);
    final pending = Completer<Workspace>();
    results.add(pending);
    return pending.future;
  }
}

void main() {
  testWidgets('missing flavor has a recoverable startup screen', (
    tester,
  ) async {
    await tester.pumpWidget(const BootstrapApp());
    await tester.pumpAndSettle();
    expect(find.text('Setup needs attention'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Setup needs attention'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing accounts cancels discovery and ignores old results', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AccountSession(
        uid: 'one',
        email: 'one@example.test',
        emailVerified: true,
      ),
    );
    final workspace = PendingWorkspaces();
    await tester.pumpWidget(DevventoryApp(auth: auth, workspaces: workspace));
    await tester.pump();
    await tester.pump();
    expect(workspace.results, hasLength(1));
    auth.emit(
      const AccountSession(
        uid: 'two',
        email: 'two@example.test',
        emailVerified: true,
      ),
    );
    await tester.pump();
    expect(workspace.tokens.first?.isCancelled, isTrue);
    expect(workspace.results, hasLength(2));
    workspace.results.first.complete(
      const Workspace(id: 'one', publisherId: 'publisher'),
    );
    await tester.pump();
    expect(find.text('Workspace connected'), findsNothing);
    expect(find.text('one@example.test'), findsNothing);
    workspace.results.last.complete(
      const Workspace(id: null, publisherId: null),
    );
    await tester.pumpAndSettle();
    expect(find.text('Finish setup on desktop'), findsOneWidget);
    expect(find.text('two@example.test'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.dispose();
  });
  testWidgets(
    'sign-in validates input, verifies email, discovers workspace and signs out',
    (tester) async {
      final auth = FakeAuthRepository();
      final workspace = FakeWorkspaceRepository(
        workspace: const Workspace(id: 'one', publisherId: 'publisher'),
      );
      await tester.pumpWidget(DevventoryApp(auth: auth, workspaces: workspace));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('email')),
        'synthetic@example.test',
      );
      await tester.enterText(
        find.byKey(const Key('password')),
        'synthetic-password',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Verify your email'), findsOneWidget);
      expect(workspace.requests, 0);
      auth.verifiedOnReload = true;
      await tester.ensureVisible(find.text("I've verified my email"));
      await tester.tap(find.text("I've verified my email"));
      await tester.pumpAndSettle();
      expect(find.text('Workspace connected'), findsOneWidget);
      expect(workspace.requests, 1);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await auth.dispose();
    },
  );

  testWidgets('reset has a generic success notice and no account creation', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      DevventoryApp(auth: auth, workspaces: FakeWorkspaceRepository()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reset-email')),
      'synthetic@example.test',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('If an account exists'), findsWidgets);
    expect(auth.sentReset, 1);
    expect(find.text('Create account'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await auth.dispose();
  });

  for (final workspace in [
    const Workspace(id: null, publisherId: null),
    const Workspace(id: 'one', publisherId: null),
  ]) {
    testWidgets(
      'missing workspace or publisher guides users back to desktop: ${workspace.id}',
      (tester) async {
        final auth = FakeAuthRepository(
          const AccountSession(
            uid: 'one',
            email: 'synthetic@example.test',
            emailVerified: true,
          ),
        );
        await tester.pumpWidget(
          DevventoryApp(
            auth: auth,
            workspaces: FakeWorkspaceRepository(workspace: workspace),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Finish setup on desktop'), findsOneWidget);
        expect(find.text('Check again'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await auth.dispose();
      },
    );
  }

  testWidgets('offline and expired session have different recovery actions', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AccountSession(
        uid: 'one',
        email: 'synthetic@example.test',
        emailVerified: true,
      ),
    );
    final workspace = FakeWorkspaceRepository(
      failure: const ApiFailure(ApiFailureKind.offline),
    );
    await tester.pumpWidget(DevventoryApp(auth: auth, workspaces: workspace));
    await tester.pumpAndSettle();
    expect(find.text('Connection unavailable'), findsOneWidget);
    workspace.failure = const ApiFailure(ApiFailureKind.unauthorized);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in again'), findsOneWidget);
    await tester.tap(find.text('Sign in again'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.dispose();
  });

  testWidgets('sign-in fits a narrow screen and large text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      DevventoryApp(
        auth: auth,
        workspaces: FakeWorkspaceRepository(),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Forgot password?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await auth.dispose();
  });
}
