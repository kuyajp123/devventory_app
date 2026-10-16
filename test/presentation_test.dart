import 'package:devventory_app/shared/cache/tests/test_cache.dart';
import 'package:devventory_app/features/projects/tests/fake_projects_repository.dart';
import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/auth/tests/fake_auth_repository.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/shared/presentation/venty_mascot.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Workspaces implements WorkspaceRepository {
  @override
  Future<Workspace> discover({CancelToken? cancelToken}) async =>
      const Workspace(id: 'workspace', publisherId: 'desktop');
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final size in [
    const Size(320, 740),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1440, 900),
  ]) {
    for (final state in ['signed-out', 'verification', 'workspace']) {
      testCachedWidgets('$state fits $size with accessible actions', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = FakeAuthRepository(
          state == 'signed-out'
              ? null
              : AccountSession(
                  uid: 'synthetic',
                  email: 'a-long-synthetic-email-address@example.test',
                  emailVerified: state == 'workspace',
                ),
        );
        await tester.pumpWidget(
          DevventoryApp(
            cache: testCache(),
            projects: FakeProjectsRepository(),
            auth: auth,
            workspaces: _Workspaces(),
            textScaler: TextScaler.linear(size.width == 320 ? 2 : 1),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(VentyMascot),
          state == 'workspace' && size.width == 320
              ? findsNothing
              : findsOneWidget,
        );
        final action = find.widgetWithText(FilledButton, switch (state) {
          'signed-out' => 'Sign in',
          'verification' => "I've verified my email",
          _ => 'Browse projects',
        });
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        expect(tester.takeException(), isNull);
        await auth.dispose();
      }, contrast: true);
    }
  }

  testCachedWidgets(
    'password reset remains scrollable with large text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuthRepository();
      await tester.pumpWidget(
        DevventoryApp(
          cache: testCache(),
          projects: FakeProjectsRepository(),
          auth: auth,
          workspaces: _Workspaces(),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Forgot password?'));
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('reset-email')));
      await tester.enterText(
        find.byKey(const Key('reset-email')),
        'synthetic@example.test',
      );
      await tester.ensureVisible(find.text('Send reset link'));
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('If an account exists'),
        ),
        findsOneWidget,
      );
      expect(auth.sentReset, 1);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await auth.dispose();
    },
  );
}
