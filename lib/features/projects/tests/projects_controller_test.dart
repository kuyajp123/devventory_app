// Colocated tests are dev-only.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/features/projects/project.dart';
import 'package:devventory_app/features/projects/projects_controller.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/cache/tests/test_cache.dart';

import 'fake_projects_repository.dart';
import 'project_test.dart' show projectFixture;

void main() {
  test('rate limits disable retry until the deadline without automatically polling', () async {
    final cache = testCache();
    final account = (await cache.activate('one'))!;
    await account.saveWorkspace('w', {});
    final repo = FakeProjectsRepository()
      ..failure = ApiFailure(
        ApiFailureKind.rateLimited,
        retryAt: DateTime.now().add(const Duration(milliseconds: 200)),
      );
    final controller = ProjectsController(
      repo,
      account.scope('w'),
      onAccessFailure: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.canRefresh, false);
    await controller.refresh();
    expect(repo.reads, 1);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(controller.canRefresh, true);
    expect(repo.reads, 1);
    repo.failure = null;
    await controller.refresh();
    expect(repo.reads, 2);
    expect(controller.projects, isEmpty);
  });
  test(
    'download, offline reload, and complete refresh apply edits and deletion',
    () async {
      final cache = testCache();
      final account = (await cache.activate('one'))!;
      await account.saveWorkspace('workspace', {});
      final repo = FakeProjectsRepository()
        ..records = [Project.fromJson(projectFixture())];
      final first = ProjectsController(
        repo,
        account.scope('workspace'),
        onAccessFailure: (_) async {},
      );
      await first.initialize();
      expect(first.projects, hasLength(1));
      expect(first.saved, isTrue);
      final fetched = first.fetchedAt;
      first.dispose();
      repo.failure = const ApiFailure(ApiFailureKind.offline);
      final offline = ProjectsController(
        repo,
        account.scope('workspace'),
        onAccessFailure: (_) async {},
      );
      await offline.initialize();
      expect(offline.projects, hasLength(1));
      expect(offline.fetchedAt, fetched);
      expect(offline.failure?.kind, ApiFailureKind.offline);
      repo.failure = null;
      final edited = projectFixture();
      edited['data']['name'] = 'Desktop edit';
      repo.records = [Project.fromJson(edited)];
      await offline.refresh();
      expect(offline.projects!.single.name, 'Desktop edit');
      repo.records = [];
      await offline.refresh();
      expect(offline.projects, isEmpty);
      offline.dispose();
      final empty = ProjectsController(
        repo,
        account.scope('workspace'),
        onAccessFailure: (_) async {},
      );
      await empty.initialize();
      expect(empty.projects, isEmpty);
      empty.dispose();
    },
  );
  test(
    'failed refresh retains the last complete cache and original download time',
    () async {
      final cache = testCache();
      final account = (await cache.activate('one'))!;
      await account.saveWorkspace('w', {});
      final repo = FakeProjectsRepository()
        ..records = [Project.fromJson(projectFixture())];
      final controller = ProjectsController(
        repo,
        account.scope('w'),
        onAccessFailure: (_) async {},
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final before = controller.fetchedAt;
      repo.failure = const ApiFailure(ApiFailureKind.invalidResponse);
      await controller.refresh();
      expect(controller.projects, hasLength(1));
      expect(controller.fetchedAt, before);
      expect(controller.failure?.kind, ApiFailureKind.invalidResponse);
    },
  );
  test(
    'disposal cancels a late result, which cannot repopulate after sign-out',
    () async {
      final cache = testCache();
      final account = (await cache.activate('one'))!;
      await account.saveWorkspace('w', {});
      final pending = Completer<List<Project>>();
      final repo = FakeProjectsRepository()..pending = pending.future;
      final controller = ProjectsController(
        repo,
        account.scope('w'),
        onAccessFailure: (_) async {},
      );
      final loading = controller.initialize();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      expect(repo.lastToken?.isCancelled, isTrue);
      await cache.clear();
      pending.complete([Project.fromJson(projectFixture())]);
      await loading;
      final other = (await cache.activate('two'))!;
      expect(await other.readWorkspace(), isNull);
    },
  );
  test('access denial hides content and delegates scope invalidation before recovery', () async {
    final cache = testCache();
    final account = (await cache.activate('one'))!;
    await account.saveWorkspace('w', {});
    final scope = account.scope('w');
    final repo = FakeProjectsRepository()
      ..records = [Project.fromJson(projectFixture())];
    final controller = ProjectsController(
      repo,
      scope,
      onAccessFailure: (_) => account.saveWorkspace(null, {}),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    repo.failure = const ApiFailure(ApiFailureKind.forbidden);
    await controller.refresh();
    expect(controller.projects, isNull);
    expect(scope.valid, isFalse);
  });
  test('unfetched content is distinct from an empty saved list and corrupt cache is not trusted', () async {
    final cache = testCache();
    final account = (await cache.activate('one'))!;
    await account.saveWorkspace('w', {});
    final scope = account.scope('w');
    await scope.replace('projects', {'version': 99, 'items': []});
    final repo = FakeProjectsRepository()
      ..failure = const ApiFailure(ApiFailureKind.offline);
    final controller = ProjectsController(
      repo,
      scope,
      onAccessFailure: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.projects, isNull);
    expect(controller.fetchedAt, isNull);
    expect(controller.cacheNotice, isNotNull);
  });
}
