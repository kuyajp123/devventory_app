import 'package:dio/dio.dart';
import 'package:devventory_app/features/projects/project.dart';
import 'package:devventory_app/features/projects/projects_repository.dart';

class FakeProjectsRepository implements ProjectsRepository {
  List<Project> records = [];
  Object? failure;
  Future<List<Project>>? pending;
  CancelToken? lastToken;
  int reads = 0;
  @override
  Future<List<Project>> fetchAll({
    CancelToken? cancelToken,
    void Function(int)? onProgress,
  }) async {
    reads++;
    lastToken = cancelToken;
    if (failure != null) throw failure!;
    return pending ?? List.of(records);
  }
}
