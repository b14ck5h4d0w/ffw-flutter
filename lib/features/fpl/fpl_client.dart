import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config.dart';
import '../../core/json.dart';

class FplWriteUnavailable implements Exception { final String msg; FplWriteUnavailable(this.msg); @override String toString() => msg; }

/// Direct connection to the user's FPL account. MOBILE: the user signs in on FPL's own page inside the app; the session
/// cookie is kept only in the device Keystore and used to call FPL from the phone. WEB: no private FPL access (CORS) —
/// linking is by public entry id and writes hand off to the FFW app. The Warzone server never sees FPL credentials.
abstract class FplClient {
  static FplClient get I => kIsWeb ? WebFplClient() : MobileFplClient();
  bool get canWrite;
  Future<bool> loggedIn();
  Future<int?> entry();
  Future<void> logout();
  Future<Map<String, dynamic>> myTeam(int entry);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> payload);
  Future<Map<String, dynamic>> transfer(Map<String, dynamic> payload) => post('/api/transfers/', payload);
  Future<Map<String, dynamic>> saveTeam(int entry, Map<String, dynamic> payload) => post('/api/my-team/$entry/', payload);
}

class WebFplClient extends FplClient {
  @override bool get canWrite => false;
  @override Future<bool> loggedIn() async => false;
  @override Future<int?> entry() async => null;
  @override Future<void> logout() async {}
  @override Future<Map<String, dynamic>> myTeam(int e) => throw FplWriteUnavailable('Official changes are made in the FFW app.');
  @override Future<Map<String, dynamic>> post(String p, Map<String, dynamic> b) => throw FplWriteUnavailable('Official changes are made in the FFW app.');
}

class MobileFplClient extends FplClient {
  static const _st = FlutterSecureStorage();
  static const ua = 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36';
  final _dio = Dio(BaseOptions(baseUrl: Config.fplBase, headers: {'User-Agent': ua}, validateStatus: (_) => true));
  @override bool get canWrite => true;
  Future<String> _cookie() async => (await _st.read(key: 'fpl_cookie')) ?? '';
  String _csrf(String c) { for (final p in c.split(';')) { final t = p.trim(); if (t.startsWith('csrftoken=')) return t.substring(10); } return ''; }
  @override Future<bool> loggedIn() async { final c = await _cookie(); return c.contains('pl_profile=') || c.contains('sessionid='); }
  @override Future<int?> entry() async { final e = await _st.read(key: 'fpl_entry'); return e == null ? null : int.tryParse(e); }
  @override Future<void> logout() async { await _st.delete(key: 'fpl_cookie'); await _st.delete(key: 'fpl_entry'); }

  /// Called by FplLoginPage once FPL's session cookie appears. Stores it and resolves the entry id via /api/me/.
  Future<int?> storeCookie(String cookie) async {
    await _st.write(key: 'fpl_cookie', value: cookie);
    try { final r = await _dio.get('/api/me/', options: Options(headers: {'Cookie': cookie})); final e = jIntN(jMap(jMap(r.data)['player'])['entry']); if (e != null) await _st.write(key: 'fpl_entry', value: '$e'); return e; } catch (_) { return null; }
  }
  @override Future<Map<String, dynamic>> myTeam(int e) async {
    final r = await _dio.get('/api/my-team/$e/', options: Options(headers: {'Cookie': await _cookie()}));
    if (r.statusCode == 401 || r.statusCode == 403) { await logout(); throw FplWriteUnavailable('FPL session expired — sign in again.'); }
    if (r.statusCode != 200) throw FplWriteUnavailable('FPL error ${r.statusCode}');
    return jMap(r.data);
  }
  @override Future<Map<String, dynamic>> post(String path, Map<String, dynamic> payload) async {
    final c = await _cookie();
    final r = await _dio.post(path, data: jsonEncode(payload), options: Options(headers: {'Cookie': c, 'X-CSRFToken': _csrf(c), 'Referer': '${Config.fplBase}/', 'Origin': Config.fplBase, 'Content-Type': 'application/json'}));
    if (r.statusCode == 401 || r.statusCode == 403) { await logout(); throw FplWriteUnavailable('FPL session expired — sign in again.'); }
    if (r.statusCode == null || r.statusCode! >= 300) {
      final d = r.data; String m = 'FPL rejected the request (${r.statusCode}).';
      if (d is Map) { final ne = d['non_field_errors']; m = ne is List && ne.isNotEmpty ? ne.first.toString() : (d['detail']?.toString() ?? m); }
      throw FplWriteUnavailable(m);
    }
    return jMap(r.data);
  }
}
