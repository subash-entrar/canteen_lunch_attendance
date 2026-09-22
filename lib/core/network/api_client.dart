import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/school_prefs.dart';
import 'api_headers.dart';

class ApiClient {
  ApiClient(this._apiHeaders)
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 20),
            // Plain text — server sometimes prepends PHP/SQL errors before JSON.
            responseType: ResponseType.plain,
            contentType: Headers.formUrlEncodedContentType,
          ),
        ) {
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) {
          developer.log(object.toString(), name: 'Dio');
          if (kDebugMode) {
            debugPrint('[Dio] $object');
          }
        },
      ),
    );
  }

  final ApiHeaders _apiHeaders;
  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<dynamic>> postForm(
    String url, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final schoolId = await SchoolPrefs.getSchoolId();
      if (schoolId == null || schoolId <= 0) {
        throw DioApiException(
          'School ID is not set. Please restart the app and enter a school ID.',
        );
      }
      final body = {...data, 'school_id': schoolId};
      final headers = await _apiHeaders.build();
      if (kDebugMode) {
        debugPrint('[API] POST $url');
        debugPrint('[API] body: $body');
      }
      final response = await _dio.post<String>(
        url,
        data: body,
        options: Options(
          headers: headers,
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
        ),
      );
      final raw = response.data ?? '';
      if (kDebugMode) {
        debugPrint('[API] status: ${response.statusCode}');
        debugPrint('[API] raw response: $raw');
      }
      final parsed = parseServerJson(raw);
      return Response<dynamic>(
        data: parsed,
        headers: response.headers,
        requestOptions: response.requestOptions,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        isRedirect: response.isRedirect,
        redirects: response.redirects,
        extra: response.extra,
      );
    } on DioException catch (e, st) {
      final message = formatDioException(e);
      developer.log(
        'DioException type=${e.type} message=${e.message} '
        'status=${e.response?.statusCode} data=${e.response?.data} '
        'error=${e.error}',
        name: 'ApiClient',
        error: e,
        stackTrace: st,
      );
      if (kDebugMode) {
        debugPrint('[API] ERROR: $message');
        debugPrint('[API] Dio type: ${e.type}');
        debugPrint('[API] Dio message: ${e.message}');
        debugPrint('[API] Dio error: ${e.error}');
        debugPrint('[API] Response status: ${e.response?.statusCode}');
        debugPrint('[API] Response data: ${e.response?.data}');
      }
      throw DioApiException(message, e);
    } on FormatException catch (e, st) {
      developer.log('JSON parse failed: $e', name: 'ApiClient', stackTrace: st);
      if (kDebugMode) {
        debugPrint('[API] JSON parse failed: $e');
      }
      throw DioApiException('Invalid server response: ${e.message}');
    }
  }
}

/// Extracts JSON even when the server prints errors before it.
dynamic parseServerJson(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Empty response from server');
  }

  try {
    return jsonDecode(trimmed);
  } on FormatException {
    // e.g. "Table 'x' doesn't exist{"status":0,...}"
    final objectStart = trimmed.indexOf('{');
    final arrayStart = trimmed.indexOf('[');
    int start = -1;
    if (objectStart >= 0 && arrayStart >= 0) {
      start = objectStart < arrayStart ? objectStart : arrayStart;
    } else if (objectStart >= 0) {
      start = objectStart;
    } else if (arrayStart >= 0) {
      start = arrayStart;
    }
    if (start < 0) rethrow;

    final prefix = trimmed.substring(0, start).trim();
    if (prefix.isNotEmpty && kDebugMode) {
      debugPrint('[API] Non-JSON prefix from server: $prefix');
    }
    return jsonDecode(trimmed.substring(start));
  }
}

class DioApiException implements Exception {
  DioApiException(this.message, [this.cause]);

  final String message;
  final DioException? cause;

  @override
  String toString() => message;
}

String formatDioException(DioException e) {
  final status = e.response?.statusCode;
  final body = e.response?.data;

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return 'Connection timeout — server did not respond in time';
    case DioExceptionType.sendTimeout:
      return 'Send timeout — request took too long to send';
    case DioExceptionType.receiveTimeout:
      return 'Receive timeout — server took too long to respond';
    case DioExceptionType.badCertificate:
      return 'SSL certificate error';
    case DioExceptionType.cancel:
      return 'Request cancelled';
    case DioExceptionType.connectionError:
      return 'Connection failed — check internet or server URL'
          '${e.error != null ? ' (${e.error})' : ''}';
    case DioExceptionType.badResponse:
      return 'Server error'
          '${status != null ? ' ($status)' : ''}'
          '${body != null ? ': $body' : ''}';
    case DioExceptionType.unknown:
      final detail = e.error?.toString() ?? e.message ?? 'no details';
      return 'Network error: $detail'
          '${status != null ? ' [HTTP $status]' : ''}'
          '${body != null ? ' — $body' : ''}';
  }
}
