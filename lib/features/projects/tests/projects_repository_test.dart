// Colocated tests are dev-only.
// ignore_for_file: depend_on_referenced_packages
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/features/projects/projects_repository.dart';
import 'package:devventory_app/shared/network/api_client.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/network/tests/api_client_test.dart'
    show Tokens, Adapter, reply;

import 'project_test.dart' show projectFixture;

void main() {
  test(
    'follows opaque cursors without a root snapshot and decodes all projects',
    () async {
      final a = projectFixture(), b = projectFixture();
      b['id'] = b['data']['id'] = '77777777-7777-4777-8777-777777777777';
      b['snapshotId'] = '88888888-8888-4888-8888-888888888888';
      final adapter = Adapter(
        (request) => reply(200, {
          'protocolVersion': 1,
          'items': [request.queryParameters['cursor'] == null ? a : b],
          'nextCursor': request.queryParameters['cursor'] == null
              ? 'opaque+/='
              : null,
        }),
      );
      final api = ApiClient(
        tokens: Tokens(),
        dio: Dio()..httpClientAdapter = adapter,
      );
      addTearDown(api.close);
      final projects = await CloudProjectsRepository(api).fetchAll();
      expect(projects, hasLength(2));
      expect(projects[0].snapshotId, isNot(projects[1].snapshotId));
      expect(adapter.requests.last.queryParameters, {
        'limit': 100,
        'cursor': 'opaque+/=',
      });
    },
  );
  test('empty list is a complete successful fetch', () async {
    final api = ApiClient(
      tokens: Tokens(),
      dio: Dio()
        ..httpClientAdapter = Adapter(
          (_) => reply(200, {
            'protocolVersion': 1,
            'items': [],
            'nextCursor': null,
          }),
        ),
    );
    addTearDown(api.close);
    expect(await CloudProjectsRepository(api).fetchAll(), isEmpty);
  });
  for (final defect in [
    'version',
    'cycle',
    'duplicate',
    'badRecord',
    'secondPageFails',
  ]) {
    test('does not return a partial collection for $defect', () async {
      var page = 0;
      final api = ApiClient(
        tokens: Tokens(),
        dio: Dio()
          ..httpClientAdapter = Adapter((_) {
            page++;
            if (page == 2 && defect == 'secondPageFails') return reply(503);
            final record = projectFixture();
            if (defect == 'badRecord') record['data']['name'] = 5;
            return reply(200, {
              'protocolVersion': defect == 'version' ? 2 : 1,
              'items': defect == 'cycle' ? [] : [record],
              'nextCursor': page == 1 || defect == 'cycle' ? 'same' : null,
            });
          }),
      );
      addTearDown(api.close);
      await expectLater(
        CloudProjectsRepository(api).fetchAll(),
        throwsA(isA<ApiFailure>()),
      );
      expect(page, lessThanOrEqualTo(2));
    });
  }
}
