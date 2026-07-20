import 'dart:convert';
import 'dart:typed_data';

import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

typedef TokenProvider = Future<String?> Function();
typedef RegionProvider = AppRegion Function();
typedef LanguageProvider = String Function();

abstract interface class JsonApi {
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  });
  Future<Map<String, dynamic>> postJson(String path, {Object? body});
}

abstract interface class BinaryApi {
  Future<Uint8List> getBytes(String path);
}

abstract interface class JsonMutationApi {
  Future<Map<String, dynamic>> putJson(String path, {Object? body});
}

abstract interface class JsonDeleteApi {
  Future<Map<String, dynamic>> deleteJson(String path);
}

abstract interface class FileUploadApi {
  Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required String fieldName,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  });
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.traceId});
  final String message;
  final int? statusCode;
  final String? traceId;
  @override
  String toString() =>
      traceId == null ? message : '$message [traceId: $traceId]';
}

class ApiClient
    implements
        JsonApi,
        BinaryApi,
        JsonMutationApi,
        JsonDeleteApi,
        FileUploadApi {
  ApiClient({
    required this.config,
    required this.tokenProvider,
    RegionProvider? regionProvider,
    LanguageProvider? languageProvider,
    http.Client? transport,
  }) : regionProvider = regionProvider ?? (() => config.region),
       languageProvider = languageProvider ?? (() => config.languageTag),
       transport = transport ?? http.Client();

  final AppConfig config;
  final TokenProvider tokenProvider;
  final RegionProvider regionProvider;
  final LanguageProvider languageProvider;
  final http.Client transport;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final uri = Uri.parse('${config.apiBaseUrl}$path').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
    final response = await transport.get(uri, headers: await _headers());
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    final response = await transport.post(
      Uri.parse('${config.apiBaseUrl}$path'),
      headers: await _headers(write: true),
      body: jsonEncode(body ?? const <String, Object?>{}),
    );
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    final response = await transport.put(
      Uri.parse('${config.apiBaseUrl}$path'),
      headers: await _headers(write: true),
      body: jsonEncode(body ?? const <String, Object?>{}),
    );
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await transport.delete(
      Uri.parse('${config.apiBaseUrl}$path'),
      headers: await _headers(write: true),
    );
    return _decode(response);
  }

  @override
  Future<Uint8List> getBytes(String path) async {
    final response = await transport.get(
      Uri.parse('${config.apiBaseUrl}$path'),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode(response);
    }
    return response.bodyBytes;
  }

  @override
  Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required String fieldName,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${config.apiBaseUrl}$path'),
    );
    request.headers.addAll(await _headers());
    request.headers['Idempotency-Key'] =
        'app-${DateTime.now().microsecondsSinceEpoch}';
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );
    final response = await http.Response.fromStream(
      await transport.send(request),
    );
    return _decode(response);
  }

  Future<Map<String, String>> _headers({bool write = false}) async {
    final token = await tokenProvider();
    return {
      'Accept': 'application/json',
      'Accept-Language': languageProvider(),
      'X-Region': regionProvider().code,
      if (write) 'Content-Type': 'application/json',
      if (write)
        'Idempotency-Key': 'app-${DateTime.now().microsecondsSinceEpoch}',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final code = root['code'] as int? ?? response.statusCode;
    if (response.statusCode < 200 || response.statusCode >= 300 || code != 0) {
      throw ApiException(
        root['message'] as String? ?? 'Request failed',
        statusCode: response.statusCode,
        traceId: root['traceId'] as String?,
      );
    }
    final data = root['data'];
    return data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'value': data};
  }
}
