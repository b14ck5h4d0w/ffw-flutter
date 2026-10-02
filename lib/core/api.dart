import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'json.dart';

enum ErrKind { offline, sessionExpired, forbidden, notFound, validation, server, fplNotLinked, noSquad, rateLimited }

class ApiException implements Exception {
  final ErrKind kind; final String code; final String message; final List<String> problems; final int status;
  ApiException(this.kind, this.code, this.message, {this.problems = const [], this.status = 0});
  @override String toString() => message;
}

/// Bearer-token client for /api/app and /api/admin. Parses the envelope {ok:false,error:{code,message,problems}}.
class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();
  final Dio _dio = Dio(BaseOptions(baseUrl: Config.baseUrl, connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 20), headers: {'User-Agent': 'FFW/1.0 (${kIsWeb ? 'Web' : 'Mobile'}; Flutter)'}));
  final _secure = const FlutterSecureStorage();
  String? _token;
  String get baseUrl => Config.baseUrl;
  String? get token => _token;

  Future<void> init() async {
    try { _token = kIsWeb ? (await SharedPreferences.getInstance()).getString('wz_token') : await _secure.read(key: 'wz_token'); } catch (_) {}
  }
  Future<void> setToken(String? t) async {
    _token = t;
    try {
      if (kIsWeb) { final p = await SharedPreferences.getInstance(); if (t == null) { await p.remove('wz_token'); } else { await p.setString('wz_token', t); } }
      else { if (t == null) { await _secure.delete(key: 'wz_token'); } else { await _secure.write(key: 'wz_token', value: t); } }
    } catch (_) {}
  }
  Options _opts([Map<String, dynamic>? extra]) => Options(headers: {if (_token != null) 'Authorization': 'Bearer $_token', ...?extra});

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _run(() => _dio.get(path, queryParameters: query, options: _opts()));
  Future<dynamic> post(String path, [Object? body]) => _run(() => _dio.post(path, data: body == null ? null : jsonEncode(body), options: _opts({'Content-Type': 'application/json'})));
  Future<dynamic> delete(String path) => _run(() => _dio.delete(path, options: _opts()));
  Future<dynamic> upload(String path, Map<String, String> fields, String fileField, List<int> bytes, String filename) =>
      _run(() => _dio.post(path, data: FormData.fromMap({...fields, fileField: MultipartFile.fromBytes(bytes, filename: filename)}), options: _opts()));

  Future<dynamic> _run(Future<Response> Function() f) async {
    try {
      final r = await f(); final d = r.data;
      if (d is Map && d['ok'] == false && d['error'] is Map) throw _envelope(jMap(d), r.statusCode ?? 200);
      return d;
    } on DioException catch (e) {
      final s = e.response?.statusCode ?? 0; final d = e.response?.data;
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) throw ApiException(ErrKind.offline, 'offline', 'You appear to be offline.');
      if (d is Map && d['error'] is Map) throw _envelope(jMap(d), s);
      if (s == 401 || s == 302) throw ApiException(ErrKind.sessionExpired, 'unauthorized', 'Please sign in again.', status: s);
      if (s == 403) throw ApiException(ErrKind.forbidden, 'forbidden', 'No access.', status: s);
      if (s == 404) throw ApiException(ErrKind.notFound, 'not_found', 'Not available.', status: s);
      throw ApiException(ErrKind.server, 'server', 'Something went wrong. Please try again.', status: s);
    }
  }
  ApiException _envelope(Map<String, dynamic> d, int s) {
    final e = jMap(d['error']); final code = jStr(e['code']); var msg = jStr(e['message'], 'Something went wrong.');
    if (msg.length > 240 || msg.contains('<') || msg.contains('Traceback')) msg = 'Something went wrong.';
    final kind = s == 401 ? ErrKind.sessionExpired : s == 403 ? ErrKind.forbidden : code == 'fpl_not_linked' ? ErrKind.fplNotLinked : code == 'no_squad' ? ErrKind.noSquad : code == 'rate_limited' ? ErrKind.rateLimited : s == 404 ? ErrKind.notFound : (s >= 500 ? ErrKind.server : ErrKind.validation);
    return ApiException(kind, code, msg, problems: (e['problems'] as List? ?? const []).map((x) => x.toString()).toList(), status: s);
  }
}
