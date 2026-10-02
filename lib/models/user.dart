import '../core/json.dart';
class WzUser {
  final int id; final String name, team, email; final String? avatar, country, bio; final int? fpl, joined; final bool admin;
  const WzUser({required this.id, required this.name, required this.team, required this.email, this.avatar, this.country, this.bio, this.fpl, this.joined, required this.admin});
  factory WzUser.fromJson(Map<String, dynamic> j) => WzUser(id: jInt(j['id']), name: jStr(j['name']), team: jStr(j['team']), email: jStr(j['email']), avatar: jStrN(j['avatar']), country: jStrN(j['country']), bio: jStrN(j['bio']), fpl: jIntN(j['fpl']), joined: jIntN(j['joined']), admin: jBool(j['admin']));
  String get initials { final p = name.trim().split(RegExp(r'\s+')); return p.length >= 2 ? (p[0][0] + p[1][0]).toUpperCase() : name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : '?'; }
}
