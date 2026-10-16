import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/auth/tests/fake_auth_repository.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/shared/network/api_client.dart';
import 'package:devventory_app/shared/network/tests/api_client_test.dart'
    show Tokens;
import 'package:devventory_app/shared/cache/tests/test_cache.dart';

import '../integration_test/support/synthetic_cloud.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    // Dio decodes larger pages in a real isolate, outside the fake widget clock.
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(finder, findsOneWidget);
  await tester.pumpAndSettle();
}

void main() {
  testCachedWidgets(
    'synthetic transport remains usable from asynchronous widget callbacks',
    (tester) async {
      final auth = FakeAuthRepository(
        const AccountSession(
          uid: 'one',
          email: 'one@example.test',
          emailVerified: true,
        ),
      );
      final cloud = SyntheticCloud();
      final api = ApiClient(
        tokens: auth,
        origin: 'https://synthetic.invalid',
        dio: Dio()..httpClientAdapter = cloud,
      );
      addTearDown(api.close);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        DevventoryApp(
          auth: auth,
          cache: testCache(),
          workspaces: CloudWorkspaceRepository(api),
          projects: CloudProjectsRepository(api),
        ),
      );
      // Home is visible before the full paginated download completes. Wait for
      // its real-data chart, yielding to Dio's JSON isolate while it is pending.
      await waitFor(tester, find.byType(PieChart));
      await tester.ensureVisible(find.text('Browse projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Browse projects'));
      await waitFor(tester, find.text('101 published projects'));
      expect(find.text('101 published projects'), findsOneWidget);
      expect(cloud.projectPages, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('native journey synthetic transport exercises real workspace and project repositories', () async {
    final cloud = SyntheticCloud();
    final api = ApiClient(
      tokens: Tokens(),
      origin: 'https://synthetic.invalid',
      dio: Dio()..httpClientAdapter = cloud,
    );
    addTearDown(api.close);
    expect((await CloudWorkspaceRepository(api).discover()).hasPublisher, true);
    expect(await CloudProjectsRepository(api).fetchAll(), hasLength(101));
    expect(cloud.workspaceReads, 1);
    expect(cloud.projectPages, 2);
  });
}
