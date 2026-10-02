// Tolerant JSON helpers: the API sends explicit nulls; never crash on a missing key.
int jInt(dynamic v, [int d = 0]) => v == null ? d : (v is int ? v : (v is double ? v.round() : int.tryParse(v.toString()) ?? d));
int? jIntN(dynamic v) => v == null ? null : jInt(v);
double jDouble(dynamic v, [double d = 0]) => v == null ? d : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? d);
String jStr(dynamic v, [String d = '']) => v == null ? d : v.toString();
String? jStrN(dynamic v) => v?.toString();
bool jBool(dynamic v, [bool d = false]) => v == null ? d : (v is bool ? v : (v.toString() == '1' || v.toString().toLowerCase() == 'true'));
Map<String, dynamic> jMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> jList(dynamic v) => v is List ? v.map(jMap).toList() : <Map<String, dynamic>>[];
List<T> jListOf<T>(dynamic v, T Function(Map<String, dynamic>) f) => jList(v).map(f).toList();
