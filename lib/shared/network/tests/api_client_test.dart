// Colocated tests are dev-only and are never imported by the application.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devventory_app/shared/network/api_client.dart';
import 'package:devventory_app/shared/network/api_failure.dart';
import 'package:devventory_app/shared/network/session_token_provider.dart';

class Tokens implements SessionTokenProvider {
  @override
  String? get userId => uid;
  String? uid = 'one';
  int refreshes = 0;
  Completer<String?>? pending;
  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (forceRefresh) refreshes++;
    return pending?.future ?? (forceRefresh ? 'fresh' : 'current');
  }
}

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody reply(
  int status, [
  Object? data,
  Map<String, List<String>>? extra,
]) => ResponseBody.fromString(
  jsonEncode(data ?? {}),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
    ...?extra,
  },
);

void main() {
  late Tokens tokens;
  late Adapter adapter;
  ApiClient client(
    FutureOr<ResponseBody> Function(RequestOptions) respond, {
    DateTime Function()? now,
  }) {
    adapter = Adapter(respond);
    return ApiClient(
      tokens: tokens,
      dio: Dio()..httpClientAdapter = adapter,
      now: now,
    );
  }

  setUp(() => tokens = Tokens());

  test('GET attaches a token and retries a 401 only once', () async {
    final api = client(
      (request) => request.headers['Authorization'] == 'Bearer fresh'
          ? reply(200, {'ok': true})
          : reply(401),
    );
    expect(await api.get('/v1/workspaces'), {'ok': true});
    expect(tokens.refreshes, 1);
    expect(adapter.requests, hasLength(2));
    expect(
      adapter.requests.every((r) => r.method == 'GET' && !r.followRedirects),
      isTrue,
    );
  });

  test('repeated 401 requires sign-in, never loops', () async {
    final api = client((_) => reply(401));
    await expectLater(
      api.get('/v1/workspaces'),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.unauthorized,
        ),
      ),
    );
    expect(adapter.requests, hasLength(2));
  });

  test('rejects off-origin paths before obtaining credentials', () async {
    final api = client((_) => reply(200));
    for (final path in [
      'https://elsewhere.test/v1/x',
      '//elsewhere.test/v1/x',
      '/v1/../x',
      '/v1/x?external=true',
    ]) {
      await expectLater(api.get(path), throwsArgumentError);
    }
    expect(adapter.requests, isEmpty);
  });

  test('rejects old identity both before sending and after response', () async {
    final pending = Completer<String?>();
    tokens.pending = pending;
    final api = client((_) => reply(200));
    final request = api.get('/v1/workspaces');
    tokens.uid = 'two';
    pending.complete('old');
    await expectLater(
      request,
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.cancelled,
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
    tokens.pending = null;
    final nextApi = client((_) {
      tokens.uid = 'three';
      return reply(200);
    });
    await expectLater(
      nextApi.get('/v1/workspaces'),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.cancelled,
        ),
      ),
    );
  });

  test(
    'rate limit backoff is enforced but not shared across identities',
    () async {
      var time = DateTime.utc(2026);
      final api = client(
        (_) => reply(
          429,
          {
            'error': {'code': 'RATE_LIMITED'},
          },
          {
            'retry-after': ['60'],
          },
        ),
        now: () => time,
      );
      for (var i = 0; i < 2; i++) {
        await expectLater(
          api.get('/v1/workspaces'),
          throwsA(
            isA<ApiFailure>().having(
              (e) => e.kind,
              'kind',
              ApiFailureKind.rateLimited,
            ),
          ),
        );
      }
      expect(adapter.requests, hasLength(1));
      tokens.uid = 'two';
      await expectLater(api.get('/v1/workspaces'), throwsA(isA<ApiFailure>()));
      expect(adapter.requests, hasLength(2));
      time = time.add(const Duration(seconds: 61));
      await expectLater(api.get('/v1/workspaces'), throwsA(isA<ApiFailure>()));
      expect(adapter.requests, hasLength(3));
    },
  );

  test(
    'verification, availability, redirects and bad JSON have safe errors',
    () async {
      for (final entry in {
        403: ApiFailureKind.verificationRequired,
        503: ApiFailureKind.unavailable,
        302: ApiFailureKind.invalidResponse,
      }.entries) {
        final api = client(
          (_) => reply(entry.key, {
            'error': {
              'code': entry.key == 403
                  ? 'EMAIL_VERIFICATION_REQUIRED'
                  : 'AUTH_UNAVAILABLE',
            },
          }),
        );
        await expectLater(
          api.get('/v1/workspaces'),
          throwsA(isA<ApiFailure>().having((e) => e.kind, 'kind', entry.value)),
        );
      }
      final api = client(
        (_) => ResponseBody.fromString(
          'not json',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      await expectLater(api.get('/v1/workspaces'), throwsA(isA<ApiFailure>()));
    },
  );
}
