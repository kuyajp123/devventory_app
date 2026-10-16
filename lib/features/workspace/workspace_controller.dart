import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:devventory_app/features/workspace/workspace.dart';
import 'package:devventory_app/features/workspace/workspace_repository.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspaceController(this._repository, {this.cache});
  final WorkspaceRepository _repository;
  final CacheAccount? cache;
  Workspace? workspace;
  ApiFailure? failure;
  DateTime? fetchedAt;
  bool loading = false;
  bool usingSaved = false;
  String? cacheNotice;
  Future<void>? _pending;
  bool _disposed = false;
  CancelToken? _request;
  Timer? _cooldown;
  bool get canRetry =>
      !loading &&
      (failure?.retryAt == null || !DateTime.now().isBefore(failure!.retryAt!));

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      final document = await cache?.readWorkspace();
      if (_disposed) return;
      if (document != null) {
        if (document['version'] != 1 || document['fetchedAt'] is! String) {
          throw const FormatException('Invalid saved workspace');
        }
        final savedWorkspace = Workspace.fromJson(document['workspace']);
        final time = DateTime.tryParse(document['fetchedAt'] as String);
        if (time == null || !time.isUtc) {
          throw const FormatException('Invalid saved workspace time');
        }
        workspace = savedWorkspace;
        fetchedAt = time;
        usingSaved = true;
      }
    } on CacheRevoked {
      return;
    } catch (_) {
      cacheNotice = 'The saved workspace could not be read. Connect to Cloud Sync and try again.';
    } finally {
      loading = false;
    }
    if (!_disposed) await refresh();
  }

  Future<void> refresh() =>
      _pending ??= _refresh().whenComplete(() => _pending = null);

  Future<void> denyAccess(ApiFailure error) async {
    workspace = null;
    fetchedAt = null;
    usingSaved = false;
    failure = error;
    if (!_disposed) notifyListeners();
    await cache?.saveWorkspace(null, {
      'version': 1,
      'workspace': const Workspace(id: null, publisherId: null).toJson(),
      'fetchedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _refresh() async {
    if (_disposed || !canRetry) return;
    loading = true;
    failure = null;
    usingSaved = workspace != null;
    _request = CancelToken();
    notifyListeners();
    try {
      final result = await _repository.discover(cancelToken: _request);
      if (_disposed) return;
      if (workspace != null && result.id != workspace!.id) {
        // A newly discovered owner scope must hide old routes even if disk fails.
        workspace = null;
        fetchedAt = null;
        usingSaved = false;
        notifyListeners();
      }
      final time = DateTime.now().toUtc();
      try {
        await cache?.saveWorkspace(result.id, {
          'version': 1,
          'workspace': result.toJson(),
          'fetchedAt': time.toIso8601String(),
        });
      } on CacheRevoked {
        return;
      } catch (_) {
        cacheNotice = 'Offline storage could not be prepared. Refresh the connection to try again.';
        return;
      }
      if (_disposed) return;
      workspace = result;
      fetchedAt = time;
      usingSaved = false;
      cacheNotice = null;
    } on ApiFailure catch (error) {
      if (_disposed) return;
      failure = error;
      if (const {
        ApiFailureKind.unauthorized,
        ApiFailureKind.verificationRequired,
        ApiFailureKind.forbidden,
        ApiFailureKind.workspaceRequired,
      }.contains(error.kind)) {
        try {
          await denyAccess(error);
        } catch (_) {
          cacheNotice =
              'Offline data could not be cleared. Sign out and try again.';
        }
      }
      if (error.retryAt != null) {
        _cooldown?.cancel();
        _cooldown = Timer(error.retryAt!.difference(DateTime.now()), () {
          if (!_disposed) notifyListeners();
        });
      }
    } catch (_) {
      if (!_disposed) {
        failure = const ApiFailure(ApiFailureKind.invalidResponse);
      }
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request?.cancel();
    _cooldown?.cancel();
    super.dispose();
  }
}
