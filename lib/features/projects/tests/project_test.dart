// Colocated tests are dev-only.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/features/projects/project.dart';

Map<String, dynamic> projectFixture() {
  final fixture = jsonDecode(
    File('test/contracts/fixtures/read-v1.json').readAsStringSync(),
  ) as Map;
  return Map<String, dynamic>.from(
    (fixture['pages'] as List).firstWhere(
          (dynamic page) => page['path'] == '/v1/projects',
        )['response']['items'][0]
        as Map,
  );
}

void main() {
  test('typed project decodes the canonical record and round trips only allowlisted fields', () {
    final wire = projectFixture();
    final project = Project.fromJson(wire);
    expect(project.name, 'Companion fixture');
    expect(project.description, isNull);
    expect(project.projectType, ProjectType.mobile);
    expect(project.observedAt, DateTime.utc(2026, 10, 15, 1));
    expect(Project.fromJson(project.toJson()).toJson(), project.toJson());
    expect(
      project.toJson()['data'].keys,
      unorderedEquals([
        'id',
        'name',
        'description',
        'projectType',
        'createdAt',
        'updatedAt',
      ]),
    );
  });
  for (final field in ['name', 'projectType', 'createdAt', 'id']) {
    test('rejects invalid project $field', () {
      final wire = projectFixture();
      wire['data'][field] = '';
      expect(() => Project.fromJson(wire), throwsFormatException);
    });
  }
  test('rejects mismatched IDs, non-project records and timestamps without an offset', () {
    for (final mutation in [
      (Map<String, dynamic> wire) => wire['id'] = 'wrong',
      (Map<String, dynamic> wire) => wire['kind'] = 'quota',
      (Map<String, dynamic> wire) => wire['observedAt'] = '2026-10-15T01:00:00',
    ]) {
      final wire = projectFixture();
      mutation(wire);
      expect(() => Project.fromJson(wire), throwsFormatException);
    }
  });
  test(
    'rejects normalized invalid calendar dates, clock times and offsets',
    () {
      for (final invalid in [
        '2026-02-29T01:00:00Z',
        '2026-10-32T01:00:00Z',
        '2026-13-01T01:00:00Z',
        '2026-10-15T24:00:00Z',
        '2026-10-15T01:60:00Z',
        '2026-10-15T01:00:60Z',
        '2026-10-15T01:00:00+24:00',
        '2026-10-15T01:00:00+08:60',
      ]) {
        expect(
          () => projectTime(invalid),
          throwsFormatException,
          reason: invalid,
        );
      }
      expect(
        projectTime('2024-02-29T09:00:00.123+08:00'),
        DateTime.utc(2024, 2, 29, 1, 0, 0, 123),
      );
    },
  );
}
