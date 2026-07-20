import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('api client attaches EU region, language and bearer token', () async {
    late http.Request captured;
    final client = ApiClient(
      config: const AppConfig(),
      tokenProvider: () async => 'token-1',
      transport: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"code":0,"message":"ok","data":{"ok":true}}',
          200,
        );
      }),
    );

    final result = await client.getJson('/api/c/v1/home/feed');
    expect(result['ok'], true);
    expect(captured.headers['X-Region'], 'EU');
    expect(captured.headers['Accept-Language'], 'zh-CN');
    expect(captured.headers['Authorization'], 'Bearer token-1');
  });

  test('api client downloads authenticated binary content', () async {
    late http.Request captured;
    final client = ApiClient(
      config: const AppConfig(),
      tokenProvider: () async => 'token-2',
      transport: MockClient((request) async {
        captured = request;
        return http.Response.bytes([1, 2, 3], 200);
      }),
    );

    final bytes = await client.getBytes(
      '/api/c/v1/privacy/export-tasks/8/download',
    );

    expect(bytes, [1, 2, 3]);
    expect(captured.headers['Authorization'], 'Bearer token-2');
  });

  test('api client sends authenticated idempotent PUT JSON', () async {
    late http.Request captured;
    final client = ApiClient(
      config: const AppConfig(),
      tokenProvider: () async => 'token-3',
      transport: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"code":0,"message":"ok","data":{"nickname":"Updated"}}',
          200,
        );
      }),
    );

    final result = await client.putJson(
      '/api/c/v1/user/profile',
      body: {'nickname': 'Updated'},
    );

    expect(captured.method, 'PUT');
    expect(captured.headers['Authorization'], 'Bearer token-3');
    expect(captured.headers['Content-Type'], 'application/json');
    expect(captured.headers['Idempotency-Key'], isNotEmpty);
    expect(captured.body, '{"nickname":"Updated"}');
    expect(result['nickname'], 'Updated');
  });

  test('api client sends authenticated idempotent DELETE JSON', () async {
    late http.Request captured;
    final client = ApiClient(
      config: const AppConfig(),
      tokenProvider: () async => 'token-4',
      transport: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"code":0,"message":"ok","data":{"id":7,"status":3}}',
          200,
        );
      }),
    );

    final result = await client.deleteJson('/api/c/v1/devices/7');

    expect(captured.method, 'DELETE');
    expect(captured.headers['Authorization'], 'Bearer token-4');
    expect(captured.headers['Idempotency-Key'], isNotEmpty);
    expect(result['status'], 3);
  });

  test('api client uploads authenticated idempotent multipart bytes', () async {
    late http.Request captured;
    final client = ApiClient(
      config: const AppConfig(),
      tokenProvider: () async => 'token-upload',
      transport: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"code":0,"message":"ok","data":{"url":"/uploads/meal.png"}}',
          200,
        );
      }),
    );

    final result = await client.uploadBytes(
      '/api/c/v1/files/upload',
      fieldName: 'file',
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'meal.png',
      contentType: 'image/png',
    );

    expect(captured.method, 'POST');
    expect(captured.headers['Authorization'], 'Bearer token-upload');
    expect(captured.headers['X-Region'], 'EU');
    expect(captured.headers['Accept-Language'], 'zh-CN');
    expect(captured.headers['Idempotency-Key'], isNotEmpty);
    expect(captured.headers['Content-Type'], startsWith('multipart/form-data;'));
    expect(captured.body, contains('name="file"'));
    expect(captured.body, contains('filename="meal.png"'));
    expect(captured.body.toLowerCase(), contains('content-type: image/png'));
    expect(result['url'], '/uploads/meal.png');
  });
}
