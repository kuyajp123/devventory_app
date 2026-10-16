import 'package:dio/dio.dart';
import 'package:devventory_app/shared/network/api_client.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/features/workspace/workspace.dart';

abstract interface class WorkspaceRepository {
  Future<Workspace> discover({CancelToken? cancelToken});
}

class CloudWorkspaceRepository implements WorkspaceRepository {
  CloudWorkspaceRepository(this._api);
  final ApiClient _api;
  @override
  Future<Workspace> discover({CancelToken? cancelToken}) async {
    final response = await _api.get('/v1/workspaces', cancelToken: cancelToken);
    try {
      return Workspace.fromJson(response);
    } on FormatException {
      throw const ApiFailure(ApiFailureKind.invalidResponse);
    }
  }
}
