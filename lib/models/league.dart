import '../core/json.dart';
class League {
  final String slug, name, code, desc, season, prize; final bool public, joined, owner, official; final List<String> modes; final int managers, clans; final String? logo, badgeColor, mySurvivor; final int? myRank, myClanRank;
  /// `public_view`: anyone with the link can view the league without logging in. Null while the server doesn't send it.
  final bool? publicView;
  const League({this.publicView,required this.slug, required this.name, required this.code, required this.desc, required this.season, required this.prize, required this.public, required this.joined, required this.owner, required this.official, required this.modes, required this.managers, required this.clans, this.logo, this.badgeColor, this.mySurvivor, this.myRank, this.myClanRank});
  factory League.fromJson(Map<String, dynamic> j) => League(publicView: j.containsKey('public_view') ? jBool(j['public_view']) : null, slug: jStr(j['slug']), name: jStr(j['name']), code: jStr(j['code']), desc: jStr(j['desc']), season: jStr(j['season']), prize: jStr(j['prize']), public: jBool(j['public']), joined: jBool(j['joined']), owner: jBool(j['owner']), official: jBool(j['official']),
      modes: (j['modes'] as List? ?? const []).map((e) => e.toString()).toList(), managers: jInt(j['managers']), clans: jInt(j['clans']), logo: jStrN(j['logo']), badgeColor: jStrN(j['badge_color']), mySurvivor: jStrN(j['my_survivor']), myRank: jIntN(j['my_rank']), myClanRank: jIntN(j['my_clan_rank']));
  bool has(String m) => modes.contains(m);
}
class StandingRow {
  final int rank, userId, gw, total, mv; final String name, team; final String? avatar, clan; final List<int> form; final bool me;
  const StandingRow({required this.rank, required this.userId, required this.gw, required this.total, required this.mv, required this.name, required this.team, this.avatar, this.clan, required this.form, required this.me});
  factory StandingRow.fromJson(Map<String, dynamic> j) => StandingRow(rank: jInt(j['rank']), userId: jInt(j['user_id']), gw: jInt(j['gw']), total: jInt(j['total']), mv: jInt(j['mv']), name: jStr(j['name']), team: jStr(j['team']), avatar: jStrN(j['avatar']), clan: jStrN(j['clan']), form: (j['form'] as List? ?? const []).map((e) => jInt(e)).toList(), me: jBool(j['me']));
}
class Clan {
  final String slug, name, motto, league, leagueSlug; final bool open, me; final int members, maxMembers, total; final int? rank; final String? logo; final List<int> form;
  const Clan({required this.slug, required this.name, required this.motto, required this.league, required this.leagueSlug, required this.open, required this.me, required this.members, required this.maxMembers, required this.total, this.rank, this.logo, required this.form});
  factory Clan.fromJson(Map<String, dynamic> j) => Clan(slug: jStr(j['slug']), name: jStr(j['name']), motto: jStr(j['motto']), league: jStr(j['league']), leagueSlug: jStr(j['league_slug']), open: jBool(j['open'], true), me: jBool(j['me']), members: jInt(j['members']), maxMembers: jInt(j['max_members'], 10), total: jInt(j['total']), rank: jIntN(j['rank']), logo: jStrN(j['logo']), form: (j['form'] as List? ?? const []).map((e) => jInt(e)).toList());
}
