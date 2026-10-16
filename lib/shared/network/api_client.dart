import 'package:dio/dio.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/network/session_token_provider.dart';

const productionOrigin = 'https://devventory-sync.devventory.workers.dev';

/// Read-only boundary. No publisher tokens, account IDs or write methods.
class ApiClient {
  ApiClient({
    required this._tokens,
    Dio? dio,
    String origin = productionOrigin,
    DateTime Function()? now,
  }) : _dio = dio ?? Dio(),
       _now = now ?? DateTime.now {
    final uri = Uri.tryParse(origin);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw ArgumentError('An HTTPS API origin is required.');
    }
    _dio.options = BaseOptions(
      baseUrl: origin,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      followRedirects: false,
      validateStatus: (_) => true,
    );
  }
  final SessionTokenProvider _tokens;
  final Dio _dio;
  final DateTime Function() _now;
  String? _backoffUser;
  DateTime? _retryAt;

  Future<Object?> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    if (!RegExp(r'^/v1/[a-zA-Z0-9/_-]+$').hasMatch(path)) {
      throw ArgumentError('Only versioned relative API paths are supported.');
    }
    final uid = _tokens.userId;
    if (uid == null) throw const ApiFailure(ApiFailureKind.unauthorized);
    if (_backoffUser == uid && _retryAt != null && _now().isBefore(_retryAt!)) {
      throw ApiFailure(ApiFailureKind.rateLimited, retryAt: _retryAt);
    }
    void checkIdentity() {
      if (uid != _tokens.userId || (cancelToken?.isCancelled ?? false)) {
        throw const ApiFailure(ApiFailureKind.cancelled);
      }
    }

    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        final token = await _tokens.idToken(forceRefresh: attempt == 1);
        checkIdentity();
        if (token == null || token.isEmpty) {
          throw const ApiFailure(ApiFailureKind.unauthorized);
        }
        final response = await _dio.get<Object?>(
          path,
          queryParameters: query,
          cancelToken: cancelToken,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );
        checkIdentity();
        final status = response.statusCode ?? 0;
        if (status == 401 && attempt == 0) continue;
        if (status == 200) return response.data;
        final data = response.data;
        final error = data is Map ? data['error'] : null;
        final code = error is Map ? error['code'] : null;
        if (status == 429) {
          final seconds =
              int.tryParse(response.headers.value('retry-after') ?? '') ?? 60;
          _backoffUser = uid;
          _retryAt = _now().add(Duration(seconds: seconds.clamp(1, 3600)));
          throw ApiFailure(ApiFailureKind.rateLimited, retryAt: _retryAt);
        }
        throw ApiFailure(switch (status) {
          401 => ApiFailureKind.unauthorized,
          403 when code == 'EMAIL_VERIFICATION_REQUIRED' =>
            ApiFailureKind.verificationRequired,
          403 => ApiFailureKind.forbidden,
          409 when code == 'WORKSPACE_REQUIRED' =>
            ApiFailureKind.workspaceRequired,
          >= 500 => ApiFailureKind.unavailable,
          _ => ApiFailureKind.invalidResponse,
        });
      }
    } on DioException catch (error) {
      checkIdentity();
      throw ApiFailure(switch (error.type) {
        DioExceptionType.cancel => ApiFailureKind.cancelled,
        DioExceptionType.unknown when error.error is FormatException =>
          ApiFailureKind.invalidResponse,
        _ => ApiFailureKind.offline,
      });
    } on FormatException {
      throw const ApiFailure(ApiFailureKind.invalidResponse);
    }
    throw const ApiFailure(ApiFailureKind.unauthorized);
  }

  void close() => _dio.close(force: true);
}
