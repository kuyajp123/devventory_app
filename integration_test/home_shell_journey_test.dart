import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/auth/tests/fake_auth_repository.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/projects/tests/fake_projects_repository.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart' show inMemoryDatabasePath;

import 'support/synthetic_cloud.dart';

class _Workspaces implements WorkspaceRepository {
  @override
  Future<Workspace> discover({CancelToken? cancelToken}) async =>
      const Workspace(id: 'demo-home-workspace', publisherId: 'demo-desktop');
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native dashboard, partial drawer, selection, refresh, tabs and sign-out',
    (tester) async {
      const preview = bool.fromEnvironment('VISUAL_PREVIEW');
      final auth = FakeAuthRepository(
        const AccountSession(
          uid: 'synthetic-home',
          email: 'synthetic@example.test',
          emailVerified: true,
        ),
      );
      final cache = MetadataCache(path: inMemoryDatabasePath);
      final cloud = SyntheticCloud();
      final repo = FakeProjectsRepository()
        ..records = [
          for (var i = 1; i <= 12; i++)
            Project.fromJson(
              cloud.project(i)
                ..['data']['projectType'] = ProjectType.values[i % 4].name,
            ),
        ];
      try {
        await tester.pumpWidget(
          DevventoryApp(
            auth: auth,
            workspaces: _Workspaces(),
            projects: repo,
            cache: cache,
          ),
        );
        await _until(tester, find.byType(PieChart));
        expect(find.text('Dashboard'), findsOneWidget);
        if (preview) {
          debugPrint('HOME_PREVIEW_READY');
          await Future<void>.delayed(const Duration(seconds: 15));
        }
        await tester.tap(find.byTooltip('Choose project'));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(Drawer)).left, greaterThan(0));
        if (preview) {
          debugPrint('DRAWER_PREVIEW_READY');
          await Future<void>.delayed(const Duration(seconds: 15));
        }
        await tester.enterText(find.byKey(const Key('project-search')), '012');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Synthetic project 012'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('View project details'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('View project details'));
        await tester.pumpAndSettle();
        expect(find.text('About this project'), findsOneWidget);
        repo.failure = const ApiFailure(ApiFailureKind.offline);
        await tester.tap(find.byTooltip('Refresh projects'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Offline.'), findsOneWidget);
        await tester.tap(find.byKey(const Key('usage-tab')));
        await tester.pumpAndSettle();
        expect(find.text('Agent usage is on its way'), findsOneWidget);
        await tester.tap(find.byKey(const Key('account-tab')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign out'));
        await _until(tester, find.widgetWithText(FilledButton, 'Sign in'));
        expect(auth.account, isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await cache.close();
        await auth.dispose();
      }
    },
  );
}
