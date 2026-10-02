import '../../core/api.dart';
import '../../core/json.dart';

class AdminResult { final bool ok; final List<(String, String)> messages; AdminResult(this.ok, this.messages);
  factory AdminResult.fromJson(Map<String, dynamic> j) => AdminResult(jBool(j['ok']), jList(j['messages']).map((m) => (jStr(m['level']), jStr(m['text']))).toList()); }

/// One method per /api/admin endpoint (API_ADMIN.md).
class AdminRepo {
  AdminRepo._(); static final AdminRepo I = AdminRepo._();
  final _a = ApiClient.I;
  Future<Map<String, dynamic>> g(String p, [Map<String, dynamic>? q]) async => jMap(await _a.get('/api/admin/$p', query: q));
  Future<AdminResult> p(String p, [Object? b]) async => AdminResult.fromJson(jMap(await _a.post('/api/admin/$p', b)));
  Future<Map<String, dynamic>> raw(String p, [Object? b]) async => jMap(await _a.post('/api/admin/$p', b));
  Future<AdminResult> d(String p) async => AdminResult.fromJson(jMap(await _a.delete('/api/admin/$p')));
  Future<AdminResult> up(String p, Map<String, String> f, List<int> bytes, String name, [String field = 'file']) async => AdminResult.fromJson(jMap(await _a.upload('/api/admin/$p', f, field, bytes, name)));
  String url(String p) => '${_a.baseUrl}/api/admin/$p';
}
