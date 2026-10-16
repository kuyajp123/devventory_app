import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class CacheRevoked implements Exception {
  const CacheRevoked();
}

/// Private metadata scopes. No credentials belong in this database.
class MetadataCache {
  MetadataCache({DatabaseFactory? factory, this.path})
    : _factory = factory ?? databaseFactory;
  final DatabaseFactory _factory;
  final String? path;
  Future<Database>? _opening;
  int _revision = 0, _workspaceRevision = 0;
  String? _uid, _workspaceId;

  Future<Database> _open() async {
    try {
      return await _factory.openDatabase(
        path ??
            p.join(
              await _factory.getDatabasesPath(),
              'devventory-metadata-v1.db',
            ),
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onConfigure: (db) async {
            // This PRAGMA returns a row; Android rejects it through execute().
            await db.rawQuery('PRAGMA secure_delete = ON');
          },
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE cache_owner (slot INTEGER PRIMARY KEY CHECK(slot=1), uid TEXT, workspace TEXT)',
            );
            await db.execute(
              'CREATE TABLE cache_scopes (workspace TEXT NOT NULL, kind TEXT NOT NULL, document TEXT NOT NULL, PRIMARY KEY(workspace,kind))',
            );
          },
        ),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> get _db => _opening ??= _open();

  /// Revocation happens before the first await, not after disk cleanup finishes.
  Future<CacheAccount?> activate(String? uid) async {
    final revision = ++_revision;
    _workspaceRevision++;
    _uid = uid;
    _workspaceId = null;
    void check() {
      if (revision != _revision) throw const CacheRevoked();
    }

    final db = await _db;
    check();
    final workspace = await db.transaction((txn) async {
      check();
      final owner = (await txn.query('cache_owner')).firstOrNull;
      if (uid == null || owner?['uid'] != uid) {
        await txn.delete('cache_scopes');
        await txn.insert('cache_owner', {
          'slot': 1,
          'uid': uid,
          'workspace': null,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        check();
        return null;
      }
      check();
      return owner?['workspace'] as String?;
    });
    check();
    _workspaceId = workspace;
    return uid == null ? null : CacheAccount._(this, uid, revision);
  }

  Future<void> clear() async {
    await activate(null);
  }

  Future<void> close() async {
    _revision++;
    final pending = _opening;
    _opening = null;
    if (pending != null) await (await pending).close();
  }

  Future<Map<String, dynamic>?> _read(
    String workspace,
    String kind,
    void Function() check,
  ) async {
    check();
    final db = await _db;
    check();
    final rows = await db.query(
      'cache_scopes',
      where: 'workspace=? AND kind=?',
      whereArgs: [workspace, kind],
    );
    check();
    if (rows.isEmpty) return null;
    final value = jsonDecode(rows.single['document'] as String);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid saved scope');
    }
    return value;
  }

  Future<void> _replace(
    String workspace,
    String kind,
    Map<String, dynamic> document,
    void Function() check,
  ) async {
    check();
    final encoded = jsonEncode(document);
    final db = await _db;
    check();
    // Only transaction handles are used within a transaction (sqflite contract).
    await db.transaction((txn) async {
      check();
      await txn.insert('cache_scopes', {
        'workspace': workspace,
        'kind': kind,
        'document': encoded,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      check(); // Throwing rolls back an obsolete write, including during sign-out.
    });
    check();
  }
}

class CacheAccount {
  CacheAccount._(this._cache, this.uid, this._revision);
  final MetadataCache _cache;
  final String uid;
  final int _revision;
  bool get valid => _cache._revision == _revision && _cache._uid == uid;
  void _check() {
    if (!valid) throw const CacheRevoked();
  }

  Future<Map<String, dynamic>?> readWorkspace() =>
      _cache._read('', 'workspace', _check);

  Future<void> saveWorkspace(String? id, Map<String, dynamic> document) async {
    _check();
    final previous = _cache._workspaceId;
    final changed = previous != id;
    if (changed) {
      _cache._workspaceRevision++;
      _cache._workspaceId = null;
    }
    final workspaceRevision = _cache._workspaceRevision;
    void check() {
      _check();
      if (workspaceRevision != _cache._workspaceRevision) {
        throw const CacheRevoked();
      }
    }

    final encoded = jsonEncode(document), db = await _cache._db;
    await db.transaction((txn) async {
      check();
      if (changed) await txn.delete('cache_scopes');
      await txn.update(
        'cache_owner',
        {'workspace': id},
        where: 'slot=? AND uid=?',
        whereArgs: [1, uid],
      );
      await txn.insert('cache_scopes', {
        'workspace': '',
        'kind': 'workspace',
        'document': encoded,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      check();
    });
    check();
    _cache._workspaceId = id;
  }

  CacheScope scope(String workspaceId) =>
      CacheScope._(this, workspaceId, _cache._workspaceRevision);
}

class CacheScope {
  CacheScope._(this._account, this.workspaceId, this._revision);
  final CacheAccount _account;
  final String workspaceId;
  final int _revision;
  bool get valid =>
      _account.valid &&
      _revision == _account._cache._workspaceRevision &&
      workspaceId == _account._cache._workspaceId;
  void _check() {
    if (!valid) throw const CacheRevoked();
  }

  Future<Map<String, dynamic>?> read(String kind) =>
      _account._cache._read(workspaceId, kind, _check);
  Future<void> replace(String kind, Map<String, dynamic> document) =>
      _account._cache._replace(workspaceId, kind, document, _check);
}
