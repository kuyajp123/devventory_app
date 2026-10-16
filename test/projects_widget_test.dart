import 'package:devventory_app/app/app_theme.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/projects/tests/fake_projects_repository.dart';
import 'package:devventory_app/features/projects/tests/project_test.dart'
    show projectFixture;
import 'package:devventory_app/shared/cache/tests/test_cache.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final detail in [false, true]) {
    testCachedWidgets(
      'published project ${detail ? 'detail' : 'list'} has readable contrast',
      (tester) async {
        final cache = testCache();
        final account = (await cache.activate('one'))!;
        await account.saveWorkspace('workspace', {});
        await tester.pumpWidget(
          MaterialApp(
            theme: companionTheme(),
            home: ProjectsPage(
              repository: FakeProjectsRepository()
                ..records = [Project.fromJson(projectFixture())],
              scope: account.scope('workspace'),
              checkWorkspace: () async {},
              onAccessFailure: (_) async {},
              onSignOut: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Companion fixture'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        if (detail) {
          await tester.tap(find.text('Companion fixture'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Desktop observed'));
          await tester.pumpAndSettle();
        }
      },
      contrast: true,
    );
  }
  for (final size in [
    const Size(320, 740),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1440, 900),
  ]) {
    testCachedWidgets(
      'projects list/detail preserve readable metadata at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cache = testCache();
        final account = (await cache.activate('one'))!;
        await account.saveWorkspace('workspace', {});
        final wire = projectFixture();
        wire['data']['description'] =
            'Synthetic project description, not file contents.';
        final repository = FakeProjectsRepository()
          ..records = [Project.fromJson(wire)];
        await tester.pumpWidget(
          MaterialApp(
            theme: companionTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width == 320 ? 2 : 1),
              ),
              child: child!,
            ),
            home: ProjectsPage(
              repository: repository,
              scope: account.scope('workspace'),
              checkWorkspace: () async {},
              onAccessFailure: (_) async {},
              onSignOut: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.text('Companion fixture');
        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.text('About this project'), findsOneWidget);
        await tester.ensureVisible(find.text('Desktop observed'));
        await tester.pumpAndSettle();
        expect(find.text('Cloud received'), findsOneWidget);
        expect(find.text('Mobile downloaded'), findsOneWidget);
        expect(find.textContaining('2026'), findsWidgets);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        expect(tester.takeException(), isNull);
        // Deletion must not leave a stale detail record on screen.
        repository.records = [];
        await tester.tap(find.byTooltip('Refresh projects'));
        await tester.pumpAndSettle();
        expect(find.text('Project no longer published'), findsOneWidget);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('No published projects'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('No published projects'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testCachedWidgets(
    'offline without a downloaded scope is not presented as an empty project list',
    (tester) async {
      final cache = testCache();
      final account = (await cache.activate('one'))!;
      await account.saveWorkspace('workspace', {});
      final repository = FakeProjectsRepository()
        ..failure = const ApiFailure(ApiFailureKind.offline);
      await tester.pumpWidget(
        MaterialApp(
          theme: companionTheme(),
          home: ProjectsPage(
            repository: repository,
            scope: account.scope('workspace'),
            checkWorkspace: () async {},
            onAccessFailure: (_) async {},
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Projects not downloaded'), findsOneWidget);
      expect(find.text('No published projects'), findsNothing);
      expect(find.textContaining('Offline.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
