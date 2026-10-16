import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/auth/tests/fake_auth_repository.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/projects/tests/project_test.dart'
    show projectFixture;
import 'package:devventory_app/features/projects/tests/fake_projects_repository.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/features/workspace/tests/workspace_offline_test.dart'
    show OfflineWorkspaceRepository;
import 'package:devventory_app/shared/cache/tests/test_cache.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

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

Future<void> browse(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Browse projects'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Browse projects'));
  await tester.pumpAndSettle();
}

Future<void> detail(WidgetTester tester, String name) async {
  await tester.scrollUntilVisible(
    find.text(name),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('View project details'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('View project details'));
  await tester.pumpAndSettle();
  expect(find.text('About this project'), findsOneWidget);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testCachedWidgets(
    'account switch and sign-out remove a nested project detail and its saved scope',
    (tester) async {
      final auth = FakeAuthRepository(one);
      final cache = testCache();
      final workspaces = OfflineWorkspaceRepository();
      final projects = FakeProjectsRepository()
        ..records = [Project.fromJson(projectFixture())];
      await tester.pumpWidget(
        DevventoryApp(
          auth: auth,
          workspaces: workspaces,
          projects: projects,
          cache: cache,
        ),
      );
      await tester.pumpAndSettle();
      await browse(tester);
      await detail(tester, 'Companion fixture');
      final request = projects.lastToken;
      final second = projectFixture();
      second['data']['name'] = 'Second account project';
      projects.records = [Project.fromJson(second)];
      auth.emit(two);
      await tester.pumpAndSettle();
      expect(request?.isCancelled, isTrue);
      expect(find.text('Companion fixture'), findsNothing);
      expect(find.text('About this project'), findsNothing);
      await browse(tester);
      await detail(tester, 'Second account project');
      await tester.tap(find.byKey(const Key('account-tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(auth.account, isNull);
      expect(find.text('Second account project'), findsNothing);
      workspaces.failure = const ApiFailure(ApiFailureKind.offline);
      projects.failure = const ApiFailure(ApiFailureKind.offline);
      auth.emit(two);
      await tester.pumpAndSettle();
      expect(find.text('Browse projects'), findsNothing);
      expect(find.text('Connection unavailable'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await auth.dispose();
    },
  );
  testCachedWidgets(
    'resume refresh changes workspace without leaving old detail routes accessible',
    (tester) async {
      final auth = FakeAuthRepository(one);
      final cache = testCache();
      final workspaces = OfflineWorkspaceRepository();
      final projects = FakeProjectsRepository()
        ..records = [Project.fromJson(projectFixture())];
      await tester.pumpWidget(
        DevventoryApp(
          auth: auth,
          workspaces: workspaces,
          projects: projects,
          cache: cache,
        ),
      );
      await tester.pumpAndSettle();
      await browse(tester);
      await detail(tester, 'Companion fixture');
      workspaces.result = const Workspace(
        id: '33333333-3333-4333-8333-333333333333',
        publisherId: '22222222-2222-4222-8222-222222222222',
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('About this project'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
      // The old refresh is stopped; the new workspace gets its own download.
      expect(projects.reads, 2);
      await tester.pumpWidget(const SizedBox());
      await auth.dispose();
    },
  );
  testCachedWidgets(
    'project authorization denial removes cached access instead of showing stale details',
    (tester) async {
      final auth = FakeAuthRepository(one);
      final cache = testCache();
      final workspaces = OfflineWorkspaceRepository();
      final projects = FakeProjectsRepository()
        ..records = [Project.fromJson(projectFixture())];
      await tester.pumpWidget(
        DevventoryApp(
          auth: auth,
          workspaces: workspaces,
          projects: projects,
          cache: cache,
        ),
      );
      await tester.pumpAndSettle();
      await browse(tester);
      await detail(tester, 'Companion fixture');
      projects.failure = const ApiFailure(ApiFailureKind.forbidden);
      await tester.tap(find.byTooltip('Refresh projects'));
      await tester.pumpAndSettle();
      expect(find.text('About this project'), findsNothing);
      expect(find.text('Companion fixture'), findsNothing);
      expect(find.text('Browse projects'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await auth.dispose();
    },
  );
}
