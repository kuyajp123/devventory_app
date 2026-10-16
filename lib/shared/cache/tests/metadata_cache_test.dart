// Colocated tests are dev-only.
// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';

void main() {
  sqfliteFfiInit();
  MetadataCache cacheAt(String path) =>
      MetadataCache(factory: databaseFactoryFfiNoIsolate, path: path);
  test('complete scopes survive a database close and offline reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'devventory-cache-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/metadata.db';
    final first = cacheAt(path);
    final account = (await first.activate('one'))!;
    await account.saveWorkspace('workspace', {'workspaceId': 'workspace'});
    await account.scope('workspace').replace('projects', {
      'complete': true,
      'items': [1, 2],
    });
    await first.close();
    final reopened = cacheAt(path);
    final restored = (await reopened.activate('one'))!;
    expect(await restored.readWorkspace(), {'workspaceId': 'workspace'});
    expect(await restored.scope('workspace').read('projects'), {
      'complete': true,
      'items': [1, 2],
    });
    await reopened.close();
  });
  test(
    'sign-out and account changes revoke old scopes and delete saved content',
    () async {
      final cache = cacheAt(inMemoryDatabasePath);
      addTearDown(cache.close);
      final one = (await cache.activate('one'))!;
      await one.saveWorkspace('workspace', {});
      final old = one.scope('workspace');
      await old.replace('projects', {'private': 'one'});
      final next = cache.activate('two');
      expect(old.valid, isFalse);
      final two = (await next)!;
      expect(await two.readWorkspace(), isNull);
      await expectLater(old.read('projects'), throwsA(isA<CacheRevoked>()));
      await cache.clear();
      final again = (await cache.activate('one'))!;
      expect(await again.readWorkspace(), isNull);
    },
  );
  test(
    'workspace changes remove old records and reject a late queued write',
    () async {
      final cache = cacheAt(inMemoryDatabasePath);
      addTearDown(cache.close);
      final account = (await cache.activate('one'))!;
      await account.saveWorkspace('old', {});
      final old = account.scope('old');
      await old.replace('projects', {
        'items': ['old'],
      });
      final change = account.saveWorkspace('new', {'workspaceId': 'new'});
      expect(old.valid, isFalse);
      await expectLater(
        old.replace('projects', {
          'items': ['late'],
        }),
        throwsA(isA<CacheRevoked>()),
      );
      await change;
      expect(await account.scope('new').read('projects'), isNull);
      await account.saveWorkspace('old', {});
      expect(await account.scope('old').read('projects'), isNull);
    },
  );
  test(
    'replacement is atomic and clearing an in-flight write cannot resurrect it',
    () async {
      final cache = cacheAt(inMemoryDatabasePath);
      addTearDown(cache.close);
      final account = (await cache.activate('one'))!;
      await account.saveWorkspace('workspace', {});
      final scope = account.scope('workspace');
      await scope.replace('projects', {
        'items': ['complete'],
      });
      await expectLater(
        scope.replace('projects', {'bad': Object()}),
        throwsA(isA<Object>()),
      );
      expect(await scope.read('projects'), {
        'items': ['complete'],
      });
      final write = expectLater(
        scope.replace('projects', {
          'items': ['late'],
        }),
        throwsA(isA<CacheRevoked>()),
      );
      await cache.clear();
      await write;
      final newAccount = (await cache.activate('one'))!;
      expect(await newAccount.readWorkspace(), isNull);
    },
  );
  test(
    'failed workspace replacement cannot issue new leases for the old scope',
    () async {
      final cache = cacheAt(inMemoryDatabasePath);
      addTearDown(cache.close);
      final account = (await cache.activate('one'))!;
      await account.saveWorkspace('old', {});
      final old = account.scope('old');
      await old.replace('projects', {'complete': true});
      // Encoding fails before SQLite, but discovering a change already revoked access.
      await expectLater(
        account.saveWorkspace('new', {'bad': Object()}),
        throwsA(isA<Object>()),
      );
      expect(old.valid, false);
      expect(account.scope('old').valid, false);
      expect(account.scope('new').valid, false);
      await account.saveWorkspace('new', {});
      expect(await account.scope('new').read('projects'), isNull);
    },
  );
}
