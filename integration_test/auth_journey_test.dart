import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devventory_app/app/devventory_app.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/workspace/index.dart';

const _project = 'demo-devventory-mobile';
const _email = 'phase2-synthetic@example.test';
const _password = 'emulator-only-password';

class _Workspaces implements WorkspaceRepository {
  int reads = 0;
  @override
  Future<Workspace> discover({CancelToken? cancelToken}) async {
    reads++;
    return const Workspace(
      id: '11111111-1111-4111-8111-111111111111',
      publisherId: '22222222-2222-4222-8222-222222222222',
    );
  }
}

// Emulator-only REST seam: never uses a production origin or credentials.
Future<List<dynamic>> _oobCodes() async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('http://10.0.2.2:9099/emulator/v1/projects/$_project/oobCodes'),
    );
    final response = await request.close();
    expect(response.statusCode, 200);
    final body = jsonDecode(await utf8.decoder.bind(response).join()) as Map;
    return body['oobCodes'] as List;
  } finally {
    client.close(force: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const probe = String.fromEnvironment('SESSION_PROBE', defaultValue: 'seed');
  testWidgets('native Firebase auth journey ($probe)', (tester) async {
    final app = await Firebase.initializeApp(
      name: 'phase2-emulator',
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
    final workspaces = _Workspaces();

    if (probe == 'seed') {
      await sdk.signOut();
      // User creation exists only in this emulator test, never in product code.
      await sdk.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      await sdk.signOut();
      await tester.pumpWidget(
        DevventoryApp(auth: auth, workspaces: workspaces),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email')), _email);
      await tester.enterText(find.byKey(const Key('password')), _password);
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Verify your email'), findsOneWidget);
      expect(workspaces.reads, 0);
      await tester.ensureVisible(find.text('Resend verification email'));
      await tester.tap(find.text('Resend verification email'));
      await tester.pumpAndSettle();
      final codes = await _oobCodes();
      final verify = codes.cast<Map>().lastWhere(
        (code) =>
            code['email'] == _email && code['requestType'] == 'VERIFY_EMAIL',
      );
      await sdk.applyActionCode(verify['oobCode'] as String);
      await tester.ensureVisible(find.text("I've verified my email"));
      await tester.tap(find.text("I've verified my email"));
      await tester.pumpAndSettle();
      expect(find.text('Workspace connected'), findsOneWidget);
      expect(
        (await sdk.currentUser!.getIdTokenResult(true))
            .claims?['email_verified'],
        true,
      );
      await auth.resetPassword(_email);
      expect(
        (await _oobCodes()).cast<Map>().any(
          (code) =>
              code['email'] == _email &&
              code['requestType'] == 'PASSWORD_RESET',
        ),
        isTrue,
      );
      // Leave the verified SDK session intact for the next process/restart probe.
    } else if (probe == 'restore') {
      final restored = await auth.sessions.first;
      expect(restored?.email, _email);
      expect(restored?.emailVerified, isTrue);
      await tester.pumpWidget(
        DevventoryApp(auth: auth, workspaces: workspaces),
      );
      await tester.pumpAndSettle();
      expect(find.text('Workspace connected'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(sdk.currentUser, isNull);
    } else if (probe == 'signed-out') {
      expect(await auth.sessions.first, isNull);
      await tester.pumpWidget(
        DevventoryApp(auth: auth, workspaces: workspaces),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(workspaces.reads, 0);
    } else {
      fail('Unknown session probe');
    }
    await tester.pumpWidget(const SizedBox());
  });
}
