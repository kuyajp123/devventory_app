import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:devventory_app/features/projects/project.dart';
import 'package:devventory_app/features/projects/projects_repository.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

class ProjectsController extends ChangeNotifier {
  ProjectsController(
    this._repository,
    this._scope, {
    required this.onAccessFailure,
    this.checkWorkspace,
  });
  final ProjectsRepository _repository;
  final CacheScope _scope;
  final Future<void> Function(ApiFailure) onAccessFailure;
  final Future<void> Function()? checkWorkspace;
  List<Project>? projects;
  DateTime? fetchedAt;
  ApiFailure? failure;
  String? cacheNotice;
  bool loading = false, saved = false, _disposed = false;
  int received = 0;
  CancelToken? _request;
  Timer? _cooldown;
  bool get canRefresh =>
      !loading &&
      _scope.valid &&
      (failure?.retryAt == null || !DateTime.now().isBefore(failure!.retryAt!));
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    loading = true;
    _emit();
    try {
      final document = await _scope.read('projects');
      if (_disposed || !_scope.valid) return;
      if (document != null) {
        if (document['version'] != 1 || document['items'] is! List) {
          throw const FormatException('Unsupported saved projects');
        }
        final time = projectTime(document['fetchedAt']);
        final items = (document['items'] as List)
            .map(Project.fromJson)
            .toList();
        if (items.map((item) => item.id).toSet().length != items.length) {
          throw const FormatException('Duplicate saved projects');
        }
        projects = List.unmodifiable(items);
        fetchedAt = time;
        saved = true;
      }
    } on CacheRevoked {
      return;
    } catch (_) {
      cacheNotice = 'Saved projects could not be read. Connect and refresh to download them again.';
    } finally {
      loading = false;
      _emit();
    }
    if (!_disposed) await refresh();
  }

  Future<void> refresh() async {
    if (_disposed || !canRefresh) return;
    loading = true;
    failure = null;
    received = 0;
    _request = CancelToken();
    _emit();
    try {
      await checkWorkspace?.call();
      if (_disposed || !_scope.valid) return;
      final complete = await _repository.fetchAll(
        cancelToken: _request,
        onProgress: (count) {
          if (!_disposed && _scope.valid) {
            received = count;
            _emit();
          }
        },
      );
      if (_disposed || !_scope.valid) return;
      // Confirm the authenticated workspace again before committing root results.
      await checkWorkspace?.call();
      if (_disposed || !_scope.valid) return;
      final time = DateTime.now().toUtc();
      try {
        await _scope.replace('projects', {
          'version': 1,
          'fetchedAt': time.toIso8601String(),
          'items': complete.map((item) => item.toJson()).toList(),
        });
        if (_disposed || !_scope.valid) return;
        saved = true;
        cacheNotice = null;
      } on CacheRevoked {
        return;
      } catch (_) {
        saved = false;
        cacheNotice = 'Projects loaded, but could not be saved for offline reading. Refresh to try saving again.';
      }
      if (_disposed || !_scope.valid) return;
      projects = List.unmodifiable(complete);
      fetchedAt = time;
    } on ApiFailure catch (error) {
      if (_disposed || !_scope.valid) return;
      failure = error;
      if (const {
        ApiFailureKind.unauthorized,
        ApiFailureKind.forbidden,
        ApiFailureKind.verificationRequired,
        ApiFailureKind.workspaceRequired,
      }.contains(error.kind)) {
        projects = null;
        fetchedAt = null;
        saved = false;
        _emit();
        try {
          await onAccessFailure(error);
        } catch (_) {
          cacheNotice =
              'Offline storage could not be cleared. Sign out and try again.';
        }
      }
      if (error.retryAt != null) {
        _cooldown?.cancel();
        _cooldown = Timer(error.retryAt!.difference(DateTime.now()), _emit);
      }
    } on CacheRevoked {
      projects = null;
      fetchedAt = null;
    } catch (_) {
      if (!_disposed) {
        failure = const ApiFailure(ApiFailureKind.invalidResponse);
      }
    } finally {
      loading = false;
      _emit();
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
