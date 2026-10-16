// Colocated tests are dev-only and are never imported by the application.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/features/workspace/workspace.dart';

void main() {
  test('decodes the three canonical workspace discovery states', () {
    final fixture = jsonDecode(
      File('test/contracts/fixtures/read-v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final states = (fixture['workspaces'] as List)
        .map((value) => Workspace.fromJson(value))
        .toList();
    expect(states[0].hasPublisher, isFalse);
    expect(states[0].id, isNull);
    expect(states[1].id, isNotNull);
    expect(states[1].hasPublisher, isFalse);
    expect(states[2].hasPublisher, isTrue);
  });

  test('rejects incompatible protocols and inconsistent identities', () {
    for (final invalid in [
      {'protocolVersion': 2, 'workspaceId': null, 'deviceId': null},
      {'protocolVersion': 1, 'workspaceId': 'invalid', 'deviceId': null},
      {'protocolVersion': 1},
      {
        'protocolVersion': 1,
        'workspaceId': null,
        'deviceId': '22222222-2222-4222-8222-222222222222',
      },
    ]) {
      expect(() => Workspace.fromJson(invalid), throwsFormatException);
    }
  });
}
