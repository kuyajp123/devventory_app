import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:devventory_app/features/workspace/workspace.dart';
import 'package:devventory_app/features/workspace/workspace_repository.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspaceController(this._repository);
  final WorkspaceRepository _repository;
  Workspace? workspace;
  ApiFailure? failure;
  DateTime? fetchedAt;
  bool loading = false;
  bool _disposed = false;
  CancelToken? _request;
  Timer? _cooldown;
  bool get canRetry =>
      !loading &&
      (failure?.retryAt == null || !DateTime.now().isBefore(failure!.retryAt!));

  Future<void> refresh() async {
    if (_disposed || !canRetry) return;
    loading = true;
    failure = null;
    workspace = null;
    _request = CancelToken();
    notifyListeners();
    try {
      final result = await _repository.discover(cancelToken: _request);
      if (_disposed) return;
      workspace = result;
      fetchedAt = DateTime.now();
    } on ApiFailure catch (error) {
      if (_disposed) return;
      failure = error;
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
