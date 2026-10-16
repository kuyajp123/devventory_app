import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/auth/tests/fake_auth_repository.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/projects/tests/fake_projects_repository.dart';
import 'package:devventory_app/features/projects/tests/project_test.dart'
    show projectFixture;
import 'package:devventory_app/features/workspace/tests/workspace_offline_test.dart'
    show OfflineWorkspaceRepository;
import 'package:devventory_app/shared/cache/tests/test_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testCachedWidgets(
    'signed-in startup opens Home; project drawer keeps dashboard visible',
    (tester) async {
      final auth = FakeAuthRepository(
        const AccountSession(
          uid: 'one',
          email: 'one@example.test',
          emailVerified: true,
        ),
      );
      addTearDown(auth.dispose);
      final repo = FakeProjectsRepository()
        ..records = [Project.fromJson(projectFixture())];
      await tester.pumpWidget(
        DevventoryApp(
          auth: auth,
          workspaces: OfflineWorkspaceRepository(),
          projects: repo,
          cache: testCache(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byKey(const Key('home-tab')), findsOneWidget);
      expect(repo.reads, 1);
      await tester.tap(find.byTooltip('Choose project'));
      await tester.pumpAndSettle();
      final drawer = find.byType(Drawer);
      final rect = tester.getRect(drawer);
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(rect.right, screenWidth);
      expect(rect.left, greaterThan(0));
      expect(rect.width, lessThan(screenWidth * .8));
      expect(find.text('Dashboard'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('project-search')),
        'not found',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching projects'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('project-search')),
        'Companion',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Companion fixture'));
      await tester.pumpAndSettle();
      expect(find.text('Selected project'), findsOneWidget);
      expect(repo.reads, 1);
      await tester.tap(find.byKey(const Key('usage-tab')));
      await tester.pumpAndSettle();
      expect(find.text('Agent usage is on its way'), findsOneWidget);
      await tester.tap(find.byKey(const Key('home-tab')));
      await tester.pumpAndSettle();
      expect(find.text('Companion fixture'), findsOneWidget);
      await tester.tap(find.byTooltip('Choose project'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold).last).isEndDrawerOpen,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('account-tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(find.byKey(const Key('home-tab')), findsNothing);
    },
  );
  for (final size in [
    const Size(320, 740),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1440, 900),
  ]) {
    testCachedWidgets(
      'drawer search, dismissal, and tabs are accessible at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = FakeAuthRepository(
          const AccountSession(
            uid: 'one',
            email: 'one@example.test',
            emailVerified: true,
          ),
        );
        addTearDown(auth.dispose);
        final wire = projectFixture();
        wire['data']['name'] = 'A deliberately long published project title that must remain readable';
        await tester.pumpWidget(
          DevventoryApp(
            auth: auth,
            workspaces: OfflineWorkspaceRepository(),
            projects: FakeProjectsRepository()
              ..records = [Project.fromJson(wire)],
            cache: testCache(),
            textScaler: TextScaler.linear(size.width == 320 ? 2 : 1),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Choose project'));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await tester.enterText(
          find.byKey(const Key('project-search')),
          'long published',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(wire['data']['name']),
          180,
          scrollable: find
              .descendant(
                of: find.byType(Drawer),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.tap(find.byTooltip('Close projects'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Choose project'));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(8, 180));
        await tester.pumpAndSettle();
        expect(
          tester
              .state<ScaffoldState>(find.byType(Scaffold).last)
              .isEndDrawerOpen,
          isFalse,
        );
        await tester.tap(find.byTooltip('Choose project'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          tester
              .state<ScaffoldState>(find.byType(Scaffold).last)
              .isEndDrawerOpen,
          isFalse,
        );
        await tester.tap(find.byKey(const Key('tracker-tab')));
        await tester.pumpAndSettle();
        expect(find.text('Your environments, in focus'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      contrast: true,
    );
  }
  testCachedWidgets(
    'offline dashboard distinguishes no download from a successful empty download',
    (tester) async {
      final auth = FakeAuthRepository(
        const AccountSession(
          uid: 'one',
          email: 'one@example.test',
          emailVerified: true,
        ),
      );
      addTearDown(auth.dispose);
      final repo = FakeProjectsRepository()
        ..failure = const ApiFailure(ApiFailureKind.offline);
      await tester.pumpWidget(
        DevventoryApp(
          auth: auth,
          workspaces: OfflineWorkspaceRepository(),
          projects: repo,
          cache: testCache(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Projects not downloaded'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(PieChart), findsNothing);
      repo.failure = null;
      await tester.tap(find.byTooltip('Refresh projects'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your chart will appear after you publish a project.'),
        findsOneWidget,
      );
      expect(find.text('Projects not downloaded'), findsNothing);
    },
  );
  testCachedWidgets('an account change revokes an open project drawer', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AccountSession(
        uid: 'one',
        email: 'one@example.test',
        emailVerified: true,
      ),
    );
    addTearDown(auth.dispose);
    final repo = FakeProjectsRepository()
      ..records = [Project.fromJson(projectFixture())];
    await tester.pumpWidget(
      DevventoryApp(
        auth: auth,
        workspaces: OfflineWorkspaceRepository(),
        projects: repo,
        cache: testCache(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose project'));
    await tester.pumpAndSettle();
    expect(find.text('Companion fixture'), findsOneWidget);
    repo.records = [];
    auth.emit(
      const AccountSession(
        uid: 'two',
        email: 'two@example.test',
        emailVerified: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Companion fixture'), findsNothing);
    expect(
      tester.state<ScaffoldState>(find.byType(Scaffold).last).isEndDrawerOpen,
      isFalse,
    );
    expect(find.text('Dashboard'), findsOneWidget);
  });
  testCachedWidgets(
    'failed sign-out is visible on the default dashboard and can be retried',
    (tester) async {
      final auth = FakeAuthRepository(
        const AccountSession(
          uid: 'one',
          email: 'one@example.test',
          emailVerified: true,
        ),
      );
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        DevventoryApp(
          auth: auth,
          workspaces: OfflineWorkspaceRepository(),
          projects: FakeProjectsRepository(),
          cache: testCache(),
        ),
      );
      await tester.pumpAndSettle();
      auth.failure = const AuthFailure('network-request-failed');
      await tester.tap(find.byKey(const Key('account-tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(auth.account, isNotNull);
      expect(find.text('Dashboard'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('connection'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('connection'), findsWidgets);
      auth.failure = null;
      await tester.tap(find.byKey(const Key('account-tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    },
  );
}
