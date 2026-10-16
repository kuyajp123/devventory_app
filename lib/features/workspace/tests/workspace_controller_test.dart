// Colocated tests are dev-only and are never imported by the application.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/features/workspace/workspace.dart';
import 'package:devventory_app/features/workspace/workspace_repository.dart';
import 'package:devventory_app/features/workspace/workspace_controller.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

class PendingWorkspace implements WorkspaceRepository {
  final result = Completer<Workspace>();
  CancelToken? token;
  int requests = 0;
  @override
  Future<Workspace> discover({CancelToken? cancelToken}) {
    token = cancelToken;
    requests++;
    return result.future;
  }
}

void main() {
  test(
    'discovery is single-flight and disposal cancels obsolete requests',
    () async {
      final repo = PendingWorkspace();
      final controller = WorkspaceController(repo);
      final loading = controller.refresh();
      final concurrent = controller.refresh();
      expect(repo.requests, 1);
      controller.dispose();
      expect(repo.token?.isCancelled, isTrue);
      repo.result.complete(const Workspace(id: null, publisherId: null));
      await loading;
      await concurrent;
      expect(controller.workspace, isNull);
    },
  );
  test(
    'errors are recoverable and never treated as an empty workspace',
    () async {
      final repo = PendingWorkspace();
      final controller = WorkspaceController(repo);
      final loading = controller.refresh();
      repo.result.completeError(const ApiFailure(ApiFailureKind.offline));
      await loading;
      expect(controller.failure?.kind, ApiFailureKind.offline);
      expect(controller.loading, isFalse);
      expect(controller.workspace, isNull);
      controller.dispose();
    },
  );
}
