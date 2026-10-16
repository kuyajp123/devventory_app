// Colocated tests are dev-only.
// ignore_for_file: depend_on_referenced_packages
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/features/workspace/workspace.dart';
import 'package:devventory_app/features/workspace/workspace_repository.dart';
import 'package:devventory_app/features/workspace/workspace_controller.dart';
import 'package:devventory_app/shared/cache/tests/test_cache.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

class OfflineWorkspaceRepository implements WorkspaceRepository {
  Workspace result = const Workspace(
    id: '11111111-1111-4111-8111-111111111111',
    publisherId: '22222222-2222-4222-8222-222222222222',
  );
  ApiFailure? failure;
  @override
  Future<Workspace> discover({CancelToken? cancelToken}) async {
    if (failure != null) throw failure!;
    return result;
  }
}

class FailingWorkspaceCache implements CacheAccount {
  FailingWorkspaceCache(this.account);
  final CacheAccount account;
  bool fail = false;
  @override
  String get uid => account.uid;
  @override
  bool get valid => account.valid;
  @override
  Future<Map<String, dynamic>?> readWorkspace() => account.readWorkspace();
  @override
  CacheScope scope(String workspaceId) => account.scope(workspaceId);
  @override
  Future<void> saveWorkspace(String? id, Map<String, dynamic> document) =>
      account.saveWorkspace(id, fail ? {'bad': Object()} : document);
}

void main() {
  test(
    'a known workspace change hides old content even when saving fails',
    () async {
      final cache = testCache();
      final account = (await cache.activate('one'))!;
      final failing = FailingWorkspaceCache(account);
      final repository = OfflineWorkspaceRepository();
      final controller = WorkspaceController(repository, cache: failing);
      addTearDown(controller.dispose);
      await controller.initialize();
      final old = account.scope(controller.workspace!.id!);
      failing.fail = true;
      repository.result = const Workspace(
        id: '33333333-3333-4333-8333-333333333333',
        publisherId: '22222222-2222-4222-8222-222222222222',
      );
      await controller.refresh();
      expect(controller.workspace, isNull);
      expect(controller.cacheNotice, isNotNull);
      expect(old.valid, false);
      expect(account.scope(old.workspaceId).valid, false);
      failing.fail = false;
      await controller.refresh();
      expect(controller.workspace?.id, repository.result.id);
      expect(controller.cacheNotice, isNull);
    },
  );
  test('workspace discovery survives offline restart and denial invalidates cached scopes', () async {
    final cache = testCache();
    final account = (await cache.activate('one'))!;
    final repository = OfflineWorkspaceRepository();
    final online = WorkspaceController(repository, cache: account);
    await online.initialize();
    final fetchedAt = online.fetchedAt;
    online.dispose();
    repository.failure = const ApiFailure(ApiFailureKind.offline);
    final offline = WorkspaceController(repository, cache: account);
    await offline.initialize();
    expect(offline.workspace?.hasPublisher, isTrue);
    expect(offline.fetchedAt, fetchedAt);
    expect(offline.usingSaved, isTrue);
    final scope = account.scope(offline.workspace!.id!);
    await scope.replace('projects', {'private': true});
    repository.failure = const ApiFailure(ApiFailureKind.forbidden);
    await offline.refresh();
    expect(offline.workspace, isNull);
    expect(scope.valid, isFalse);
    expect(
      (await account.readWorkspace())!['workspace']['workspaceId'],
      isNull,
    );
    offline.dispose();
  });
  test(
    'authoritative workspace change removes the prior project scope',
    () async {
      final cache = testCache();
      final account = (await cache.activate('one'))!;
      final repository = OfflineWorkspaceRepository();
      final controller = WorkspaceController(repository, cache: account);
      addTearDown(controller.dispose);
      await controller.initialize();
      final old = account.scope(controller.workspace!.id!);
      await old.replace('projects', {'old': true});
      repository.result = const Workspace(
        id: '33333333-3333-4333-8333-333333333333',
        publisherId: '22222222-2222-4222-8222-222222222222',
      );
      await controller.refresh();
      expect(old.valid, isFalse);
      expect(
        await account.scope(controller.workspace!.id!).read('projects'),
        isNull,
      );
    },
  );
}
