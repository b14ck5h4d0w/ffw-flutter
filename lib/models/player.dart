import '../core/json.dart';
import '../core/config.dart';
const _base = Config.baseUrl;
class Club {
  final int id; final String code, name, color; final int? fplCode;
  const Club({required this.id, required this.code, required this.name, required this.color, this.fplCode});
  factory Club.fromJson(dynamic j) => j is Map ? Club(id: jInt(j['id']), code: jStr(j['code']), name: jStr(j['name']), color: jStr(j['color'], '#333333'), fplCode: jIntN(j['fpl_code'])) : Club(id: 0, code: jStr(j), name: jStr(j), color: '#333333');
  String? get badgeUrl => fplCode == null ? null : '$_base/img/badge/$fplCode.png';
  String? get shirtUrl => fplCode == null ? null : 'https://fantasy.premierleague.com/dist/img/shirts/standard/shirt_$fplCode-110.webp';
}
class NextFixture { final int gw, fdr; final String opp, ha; const NextFixture(this.gw, this.opp, this.ha, this.fdr);
  factory NextFixture.fromJson(Map<String, dynamic> j) => NextFixture(jInt(j['gw']), jStr(j['opp']), jStr(j['ha']), jInt(j['fdr'], 3)); }
class Player {
  final int id; final String name, pos, status; final Club club; final double price, change, form, own, xg, xa; final int pts, goals, assists, minutes, bonus, tin, tout; final int? code, chance; final String? news; final List<NextFixture> next;
  // pick extras
  final int slot, mult; final bool c, v; final int? gwPts; final String fix, fixStatus; final double? sell;
  const Player({required this.id, required this.name, required this.pos, required this.status, required this.club, required this.price, required this.change, required this.form, required this.own, required this.xg, required this.xa, required this.pts, required this.goals, required this.assists, required this.minutes, required this.bonus, required this.tin, required this.tout, this.code, this.chance, this.news, required this.next, this.slot = 0, this.mult = 1, this.c = false, this.v = false, this.gwPts, this.fix = '', this.fixStatus = 'up', this.sell});
  factory Player.fromJson(Map<String, dynamic> j) => Player(id: jInt(j['id']), name: jStr(j['name']), pos: jStr(j['pos']), status: jStr(j['status'], 'a'), club: Club.fromJson(j['club'] ?? {'code': jStr(j['club']), 'color': jStr(j['color'], '#333333')}),
      price: jDouble(j['price']), change: jDouble(j['change']), form: jDouble(j['form']), own: jDouble(j['own']), xg: jDouble(j['xg']), xa: jDouble(j['xa']), pts: jInt(j['pts']), goals: jInt(j['goals']), assists: jInt(j['assists']), minutes: jInt(j['minutes']), bonus: jInt(j['bonus']), tin: jInt(j['tin']), tout: jInt(j['tout']),
      code: jIntN(j['code']), chance: jIntN(j['chance']), news: jStrN(j['news']), next: jListOf(j['next'], NextFixture.fromJson),
      slot: jInt(j['slot']), mult: jInt(j['mult'], 1), c: jBool(j['c'] ?? j['captain']), v: jBool(j['v'] ?? j['vice']), gwPts: jIntN(j['gw_pts']), fix: jStr(j['fix']), fixStatus: jStr(j['fix_status'], 'up'), sell: j['sell'] == null ? null : jDouble(j['sell']));
  String? get photoUrl => code == null ? null : '$_base/img/player/$code.png';
  bool get bench => slot > 11;
}
