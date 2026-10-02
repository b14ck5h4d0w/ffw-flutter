import 'package:flutter/foundation.dart';
import 'api.dart';
import 'json.dart';
import '../models/user.dart';

/// Warzone login state (bearer token + user). Separate from the FPL connection (see features/fpl).
class Session extends ChangeNotifier {
  Session._();
  static final Session I = Session._();
  WzUser? user; Map<String, bool> flags = {}; bool ready = false;
  bool get loggedIn => user != null;
  bool get isAdmin => user?.admin ?? false;

  Future<void> boot() async {
    await ApiClient.I.init();
    await refreshFlags();
    if (ApiClient.I.token != null) { try { await refreshMe(); } on ApiException catch (e) { if (e.kind == ErrKind.sessionExpired) await logout(); } catch (_) {} }
    ready = true; notifyListeners();
  }
  Future<void> refreshFlags() async {
    try { final j = jMap(await ApiClient.I.get('/api/app/flags')); flags = {for (final k in j.keys) k: jBool(j[k])}; } catch (_) { flags = {}; }
    notifyListeners();
  }
  bool flag(String k) => flags[k] ?? false;
  /// GET auth/me → {user}. Servers that predate auth/me answer 404; GET home also carries {user}, so fall back to it.
  Future<void> refreshMe() async {
    Map<String, dynamic> j;
    try { j = jMap(await ApiClient.I.get('/api/app/auth/me')); }
    on ApiException catch (e) { if (e.kind != ErrKind.notFound) rethrow; j = jMap(await ApiClient.I.get('/api/app/home')); }
    if (jMap(j['user']).isEmpty) throw ApiException(ErrKind.sessionExpired, 'no_user', 'Please log in again.');
    user = WzUser.fromJson(jMap(j['user'])); notifyListeners();
  }
  Future<void> login(String email, String password) async {
    final j = jMap(await ApiClient.I.post('/api/app/auth/login', {'email': email, 'password': password}));
    await ApiClient.I.setToken(jStr(j['token'])); user = WzUser.fromJson(jMap(j['user'])); notifyListeners();
  }
  Future<void> register(String name, String email, String password, {String? fpl}) async {
    final j = jMap(await ApiClient.I.post('/api/app/auth/register', {'name': name, 'email': email, 'password': password, if (fpl != null && fpl.isNotEmpty) 'fpl': fpl}));
    await ApiClient.I.setToken(jStr(j['token'])); user = WzUser.fromJson(jMap(j['user'])); notifyListeners();
  }
  Future<void> exchange(String code) async {
    final j = jMap(await ApiClient.I.post('/api/app/auth/exchange', {'code': code}));
    await ApiClient.I.setToken(jStr(j['token'])); user = WzUser.fromJson(jMap(j['user'])); notifyListeners();
  }
  Future<void> forgot(String email) => ApiClient.I.post('/api/app/auth/forgot', {'email': email});
  Future<void> reset(String token, String password) async { final j = jMap(await ApiClient.I.post('/api/app/auth/reset', {'token': token, 'password': password})); await ApiClient.I.setToken(jStr(j['token'])); user = WzUser.fromJson(jMap(j['user'])); notifyListeners(); }
  Future<void> logout() async { try { await ApiClient.I.post('/api/app/auth/logout'); } catch (_) {} await ApiClient.I.setToken(null); user = null; notifyListeners(); }
}
