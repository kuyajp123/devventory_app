import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/projects/index.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';
import 'package:devventory_app/shared/network/api_client.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

import 'support/synthetic_cloud.dart';

const _project = 'demo-devventory-mobile';
const _email = 'phase3-synthetic@example.test';

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 120 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsOneWidget);
  await tester.pumpAndSettle();
}

Future<void> _verify(FirebaseAuth sdk) async {
  await sdk.currentUser!.sendEmailVerification();
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('http://10.0.2.2:9099/emulator/v1/projects/$_project/oobCodes'),
    );
    final response = await request.close();
    expect(response.statusCode, 200);
    final body = jsonDecode(await utf8.decoder.bind(response).join()) as Map;
    final code = (body['oobCodes'] as List).cast<Map>().lastWhere(
      (code) =>
          code['email'] == _email && code['requestType'] == 'VERIFY_EMAIL',
    );
    await sdk.applyActionCode(code['oobCode'] as String);
    await sdk.currentUser!.reload();
    await sdk.currentUser!.getIdToken(true);
  } finally {
    client.close(force: true);
  }
}

Future<void> _browse(WidgetTester tester) async {
  // Native SQLite/network completion is not implied by an idle frame scheduler.
  await _until(tester, find.text('Browse projects'));
  await tester.ensureVisible(find.text('Browse projects'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Browse projects'));
  await tester.pumpAndSettle();
}

Future<void> _detail(WidgetTester tester, String name) async {
  await tester.scrollUntilVisible(
    find.text(name),
    500,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 150,
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const probe = String.fromEnvironment('SESSION_PROBE', defaultValue: 'seed');
  // Opt-in pause for adb visual captures; normal acceptance has no artificial wait.
  const preview = bool.fromEnvironment('VISUAL_PREVIEW');
  testWidgets('native projects and offline storage ($probe)', (tester) async {
    final app = await Firebase.initializeApp(
      name: 'phase3-emulator',
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: '1:1234567890:android:1234567890abcdef',
        messagingSenderId: '1234567890',
        projectId: _project,
      ),
    );
    final sdk = FirebaseAuth.instanceFor(app: app);
    await sdk.useAuthEmulator('10.0.2.2', 9099);
    final auth = FirebaseAuthRepository(sdk);
    final cloud = SyntheticCloud()..offline = probe != 'seed';
    final dio = Dio()..httpClientAdapter = cloud;
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Diagnostic categories only: never headers, request bodies or raw errors.
          debugPrint(
            'Synthetic transport failure: ${error.type.name}/${error.error.runtimeType}',
          );
          handler.next(error);
        },
      ),
    );
    final api = ApiClient(
      tokens: auth,
      origin: 'https://synthetic.invalid',
      dio: dio,
    );
    final path = p.join(await getDatabasesPath(), 'devventory-phase3-probe.db');
    final cache = MetadataCache(path: path);
    if (probe == 'seed') {
      await cache.clear(); // Only this test's private database.
      await sdk.signOut();
      try {
        await sdk.createUserWithEmailAndPassword(
          email: _email,
          password: 'emulator-only-password',
        );
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        // Repeated seeds reuse only this known synthetic emulator identity.
        await sdk.signInWithEmailAndPassword(
          email: _email,
          password: 'emulator-only-password',
        );
      }
      if (!sdk.currentUser!.emailVerified) await _verify(sdk);
      try {
        expect((await auth.idToken())?.isNotEmpty, true);
        debugPrint('Native demo token ready');
        await api.get('/v1/workspaces');
        debugPrint('Native synthetic workspace read ready');
      } on ApiFailure catch (error) {
        fail('Native read preflight failed: ${error.kind.name}');
      }
    } else if (probe == 'signed-out') {
      expect(await auth.sessions.first, isNull);
      // Inspect before startup cleanup: the previous sign-out itself erased data.
      final db = await openDatabase(path, readOnly: true);
      expect(await db.query('cache_scopes'), isEmpty);
      expect((await db.query('cache_owner')).single['uid'], isNull);
      await db.close();
    } else {
      expect(probe, 'restore');
      expect((await auth.sessions.first)?.email, _email);
    }
    try {
      await tester.pumpWidget(
        DevventoryApp(
          auth: auth,
          cache: cache,
          workspaces: CloudWorkspaceRepository(api),
          projects: CloudProjectsRepository(api),
        ),
      );
      await tester.pumpAndSettle();
      if (probe == 'signed-out') {
        await _until(tester, find.widgetWithText(FilledButton, 'Sign in'));
        expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
        expect(cloud.workspaceReads, 0);
        return;
      }
      await _browse(tester);
      await _until(tester, find.text('101 published projects'));
      expect(find.text('101 published projects'), findsOneWidget);
      if (probe == 'seed') {
        expect(cloud.projectPages, 2);
        if (preview) {
          debugPrint('PHASE3_LIST_READY');
          await Future<void>.delayed(const Duration(seconds: 15));
        }
        await _detail(tester, 'Synthetic project 001');
        await tester.scrollUntilVisible(
          find.text('Mobile downloaded'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Desktop observed'), findsOneWidget);
        expect(find.text('Cloud received'), findsOneWidget);
        if (preview) {
          debugPrint('PHASE3_DETAIL_READY');
          await Future<void>.delayed(const Duration(seconds: 15));
        }
        // Leave both the real SDK session and complete native SQLite list intact.
      } else {
        expect(cloud.projectPages, 0);
        if (preview) {
          debugPrint('PHASE3_OFFLINE_LIST_READY');
          await Future<void>.delayed(const Duration(seconds: 15));
        }
        // This detail was never opened before the full process restart.
        await _detail(tester, 'Synthetic project 101');
        cloud
          ..offline = false
          ..edited = true;
        await tester.tap(find.byTooltip('Refresh projects'));
        await _until(tester, find.text('Project no longer published'));
        expect(cloud.projectPages, 1);
        expect(find.text('Project no longer published'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Choose project'));
        await tester.pumpAndSettle();
        await _detail(tester, 'Updated synthetic project');
        await tester.tap(find.byKey(const Key('account-tab')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign out'));
        await _until(tester, find.widgetWithText(FilledButton, 'Sign in'));
        expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
        expect(sdk.currentUser, isNull);
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      api.close();
      await cache.close();
    }
  });
}
