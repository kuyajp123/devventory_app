import 'package:dio/dio.dart';
import 'package:devventory_app/features/projects/project.dart';
import 'package:devventory_app/shared/network/api_client.dart';
import 'package:devventory_app/shared/network/api_failure.dart';

abstract interface class ProjectsRepository {
  Future<List<Project>> fetchAll({
    CancelToken? cancelToken,
    void Function(int)? onProgress,
  });
}

class CloudProjectsRepository implements ProjectsRepository {
  CloudProjectsRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Project>> fetchAll({
    CancelToken? cancelToken,
    void Function(int)? onProgress,
  }) async {
    final result = <Project>[];
    final cursors = <String>{}, ids = <String>{};
    String? cursor;
    try {
      do {
        if (cancelToken?.isCancelled ?? false) {
          throw const ApiFailure(ApiFailureKind.cancelled);
        }
        final response = await _api.get(
          '/v1/projects',
          query: {'limit': 100, 'cursor': ?cursor},
          cancelToken: cancelToken,
        );
        if (response is! Map ||
            response['protocolVersion'] != 1 ||
            response['items'] is! List ||
            (response['items'] as List).length > 100 ||
            !response.containsKey('nextCursor')) {
          throw const FormatException('Invalid project page');
        }
        for (final value in response['items'] as List) {
          final project = Project.fromJson(value);
          if (!ids.add(project.id)) {
            throw const FormatException('Duplicate project');
          }
          result.add(project);
        }
        final next = response['nextCursor'];
        if (next != null &&
            (next is! String ||
                next.isEmpty ||
                next.length > 1024 ||
                !cursors.add(next))) {
          throw const FormatException('Invalid project cursor');
        }
        cursor = next as String?;
        onProgress?.call(result.length);
      } while (cursor != null);
      return List.unmodifiable(result);
    } on FormatException {
      throw const ApiFailure(ApiFailureKind.invalidResponse);
    }
  }
}
