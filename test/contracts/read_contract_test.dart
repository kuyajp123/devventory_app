import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/contracts/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final reads = fixture('read-v1.json');
  final quotas = fixture('quota-status-v1.json');

  test('Dart decodes every producer-owned v1 metadata kind', () {
    expect(reads['fixtureVersion'], 1);
    final kinds = <String>{};
    for (final entry in reads['pages'] as List<dynamic>) {
      final page = entry['response'] as Map<String, dynamic>;
      expect(page['protocolVersion'], 1);
      expect(page['nextCursor'], anyOf(isNull, isA<String>()));
      for (final item in page['items'] as List<dynamic>) {
        final record = item as Map<String, dynamic>;
        kinds.add(record['kind'] as String);
        expect(record['id'], isA<String>());
        expect(record['data'], isA<Map<String, dynamic>>());
        expect(record['snapshotId'], isA<String>());
        expect(DateTime.parse(record['receivedAt'] as String).isUtc, isTrue);
        expect(DateTime.parse(record['observedAt'] as String).isUtc, isTrue);
      }
    }
    expect(kinds, {
      'project',
      'environment',
      'source',
      'key',
      'cell',
      'occurrence',
      'rule',
      'ruleTarget',
      'issue',
      'validation',
      'agentAccount',
      'quota',
    });
  });

  test(
    'workspace discovery preserves absent workspace and publisher states',
    () {
      final workspaces = reads['workspaces'] as List<dynamic>;
      expect(workspaces[0]['workspaceId'], isNull);
      expect(workspaces[1]['workspaceId'], isA<String>());
      expect(workspaces[1]['deviceId'], isNull);
      expect(workspaces[2]['deviceId'], isA<String>());
    },
  );

  test(
    'wire data preserves composite IDs, null usage, and timezone offsets',
    () {
      final records = (reads['pages'] as List<dynamic>).expand(
        (dynamic page) => page['response']['items'] as List<dynamic>,
      );
      final cell = records.firstWhere((dynamic item) => item['kind'] == 'cell');
      expect(cell['id'], 'API_URL:66666666-6666-4666-8666-666666666666');
      final quota = records.firstWhere(
        (dynamic item) => item['kind'] == 'quota',
      );
      expect(quota['data']['remainingPercent'], isNull);
      expect(quota['data']['usageIsStale'], isTrue);
      expect(quota['data']['reminders']['resetDay'], isTrue);
      expect(
        DateTime.parse(quota['data']['resetAt'] as String),
        DateTime.utc(2026, 10, 17),
      );
    },
  );

  test(
    'quota parity cases decode without losing numeric precision or nulls',
    () {
      expect(quotas['fixtureVersion'], 1);
      final cases = quotas['statusCases'] as List<dynamic>;
      for (final dynamic entry in cases) {
        final windows = entry['quotas'] as List<dynamic>;
        expect(entry['expectedQuotaStatuses'], hasLength(windows.length));
        for (final dynamic quota in windows) {
          expect(quota['remainingPercent'], anyOf(isNull, isA<num>()));
          expect(DateTime.tryParse(quota['resetAt'] as String), isNotNull);
        }
      }
      final boundary = cases.firstWhere(
        (dynamic entry) => entry['name'] == 'above limited threshold',
      );
      expect(boundary['quotas'][0]['remainingPercent'], 20.01);
      for (final dynamic entry in quotas['timingCases'] as List<dynamic>) {
        expect(DateTime.tryParse(entry['now'] as String), isNotNull);
        expect(DateTime.tryParse(entry['resetAt'] as String), isNotNull);
        expect(entry['timezone'], isA<String>());
      }
    },
  );
}
