import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Contract-shaped responses only. No emulator ID token reaches a real Worker.
class SyntheticCloud implements HttpClientAdapter {
  bool offline = false, edited = false;
  int projectPages = 0, workspaceReads = 0;
  static const cursor = 'synthetic second page/%';

  void _require(bool condition, String field) {
    // Flutter's expect() is guarded and cannot run from a native I/O callback
    // while a widget pump is pending. Keep fixture validation outside that API.
    if (!condition) throw StateError('Invalid synthetic request: $field');
  }

  Map<String, dynamic> project(int index) {
    final id = '00000000-0000-4000-8000-${index.toString().padLeft(12, '0')}';
    return {
      'kind': 'project',
      'id': id,
      'data': {
        'id': id,
        'name': edited && index == 1
            ? 'Updated synthetic project'
            : 'Synthetic project ${index.toString().padLeft(3, '0')}',
        'description': 'Synthetic metadata for the native offline journey.',
        'projectType': 'mobile',
        'createdAt': '2026-10-15T00:00:00Z',
        'updatedAt': '2026-10-15T01:00:00Z',
      },
      'snapshotId': '55555555-5555-4555-8555-555555555555',
      'observedAt': '2026-10-15T01:00:00Z',
      'receivedAt': '2026-10-15T01:01:00Z',
    };
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _require(options.uri.host == 'synthetic.invalid', 'origin');
    _require(options.method == 'GET', 'method');
    // Assert presence, never print/serialize the emulator bearer token.
    final authorization = options.headers['Authorization'];
    _require(
      authorization is String && authorization.startsWith('Bearer '),
      'authorization presence',
    );
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Synthetic offline',
      );
    }
    final Map<String, dynamic> body;
    switch (options.path) {
      case '/v1/workspaces':
        workspaceReads++;
        body = {
          'protocolVersion': 1,
          'workspaceId': '11111111-1111-4111-8111-111111111111',
          'deviceId': '22222222-2222-4222-8222-222222222222',
        };
      case '/v1/projects':
        projectPages++;
        _require(options.queryParameters['limit'] == 100, 'limit');
        _require(
          !options.queryParameters.containsKey('snapshotId'),
          'root snapshot',
        );
        final second = options.queryParameters['cursor'] != null;
        if (second) {
          _require(options.queryParameters['cursor'] == cursor, 'cursor');
        }
        body = {
          'protocolVersion': 1,
          'items': second
              ? [project(101)]
              : List.generate(100, (index) => project(index + 1)),
          'nextCursor': second || edited ? null : cursor,
        };
      default:
        throw StateError('Unexpected synthetic path');
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
