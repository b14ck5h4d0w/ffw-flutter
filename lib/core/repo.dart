import 'api.dart';
import 'json.dart';
import '../models/user.dart';
import '../models/player.dart';
import '../models/league.dart';

/// One method per /api/app endpoint (docs: API_CONTRACT + API_CONTRACT_WEB_ADDITIONS).
class Repo {
  Repo._(); static final Repo I = Repo._();
  final _a = ApiClient.I;
  Future<Map<String, dynamic>> _g(String p, [Map<String, dynamic>? q]) async => jMap(await _a.get('/api/app/$p', query: q));
  Future<Map<String, dynamic>> _p(String p, [Object? b]) async => jMap(await _a.post('/api/app/$p', b));

  // public
  Future<Map<String, dynamic>> publicHome() => _g('public/home');
  Future<List<League>> publicLeagues({String q = ''}) async => jListOf((await _g('leagues', {'public': '1', 'q': q}))['items'], League.fromJson);
  Future<List<Map<String, dynamic>>> modes() async => jList((await _g('modes'))['modes']);
  Future<Map<String, dynamic>> table() => _g('table');
  Future<Map<String, dynamic>> results(int gw) => _g('results', {'gw': gw});
  Future<Map<String, dynamic>> history() => _g('history');
  Future<Map<String, dynamic>> hof({String? league}) => _g('hof', league == null ? null : {'league': league});
  Future<String?> globalSlug() async => jStrN((await _g('global'))['slug']);
  Future<Map<String, dynamic>> rankings({String q = '', int page = 1}) => _g('rankings', {'q': q, 'page': page});
  Future<Map<String, dynamic>> survivorSchedule(int players) => _g('survivor/schedule', {'players': players});
  Future<Map<String, dynamic>> news() => _g('news');

  // me
  Future<Map<String, dynamic>> home() => _g('home');
  Future<Map<String, dynamic>> squad({int? gw}) => _g('squad', gw == null ? null : {'gw': gw});
  Future<List<Map<String, dynamic>>> gameweeks() async => jList((await _g('gameweeks'))['items']);
  Future<Map<String, dynamic>> gwPoints(int gw) => _g('gameweeks/$gw/points');
  Future<Map<String, dynamic>> transfers() => _g('transfers');
  Future<Map<String, dynamic>> plan(List<int> out, List<int> inn) => _p('plan', {'out': out, 'in': inn});
  Future<Map<String, dynamic>> planPayload(Map<String, dynamic> myTeam, List<int> out, List<int> inn, {String? chip}) => _p('plan/payload', {'my_team': myTeam, 'out': out, 'in': inn, 'chip': chip});
  Future<List<Map<String, dynamic>>> transfersHistory() async => jList((await _g('transfers/history'))['items']);
  Future<List<Map<String, dynamic>>> chips() async => jList((await _g('chips'))['items']);
  Future<Map<String, dynamic>> hits() => _g('hits');
  Future<Map<String, dynamic>> fplLookup(String entry) => _g('fpl/lookup', {'entry': entry});
  Future<void> fplLink(int entry) => _p('me/fpl', {'entry': entry});
  Future<void> fplUnlink() => _a.delete('/api/app/me/fpl');
  Future<WzUser> updateMe(Map<String, dynamic> f) async => WzUser.fromJson(jMap((await _p('me', f))['user']));
  Future<String> avatar(List<int> bytes, String name) async => jStr(jMap(await _a.upload('/api/app/me/avatar', const {}, 'avatar', bytes, name))['avatar']);
  Future<void> deleteAccount() => _p('delete-account', {'confirm': 'DELETE'});

  // players
  Future<List<Player>> players({String? pos, String q = '', double? max, String? club, String sort = 'form', int limit = 60}) async =>
      jListOf((await _g('players', {if (pos != null) 'pos': pos, 'q': q, if (max != null) 'max': max, if (club != null) 'club': club, 'sort': sort, 'limit': limit}))['items'], Player.fromJson);
  Future<Map<String, dynamic>> player(int id) => _g('players/$id');
  Future<List<Player>> watchlist() async => jListOf((await _g('watchlist'))['items'], Player.fromJson);
  Future<void> watch(int id, bool on) => on ? _p('watchlist', {'player': id}) : _a.delete('/api/app/watchlist/$id');

  // fixtures
  Future<Map<String, dynamic>> fixtures({int? gw}) => _g('fixtures', gw == null ? null : {'gw': gw});
  Future<Map<String, dynamic>> match(int id) => _g('matches/$id');

  // leagues
  Future<List<League>> myLeagues() async => jListOf((await _g('leagues'))['items'], League.fromJson);
  Future<List<League>> directory({String q = '', bool public = false}) async => jListOf((await _g('leagues/directory', {'q': q, if (public) 'public': '1'}))['items'], League.fromJson);
  Future<Map<String, dynamic>> league(String slug) => _g('leagues/$slug');
  Future<Map<String, dynamic>> standings(String slug, String view) => _g('leagues/$slug/standings', {'view': view});
  Future<List<Map<String, dynamic>>> members(String slug) async => jList((await _g('leagues/$slug/members'))['items']);
  Future<List<Map<String, dynamic>>> requests(String slug) async => jList((await _g('leagues/$slug/requests'))['items']);
  Future<void> requestAction(String slug, int id, bool accept) => _p('leagues/$slug/requests/$id', {'accept': accept});
  Future<Map<String, dynamic>> join(String code) => _p('join', {'code': code});
  Future<Map<String, dynamic>> joinLeague(String slug) => _p('leagues/$slug/join');
  Future<League> createLeague(Map<String, dynamic> f) async => League.fromJson(jMap((await _p('leagues', f))['league']));
  Future<Map<String, dynamic>> survivor(String slug) => _g('leagues/$slug/survivor');
  Future<Map<String, dynamic>> civilWar(String slug) => _g('leagues/$slug/civil-war');
  Future<Map<String, dynamic>> h2h(String slug) => _g('leagues/$slug/h2h');
  Future<Map<String, dynamic>> leagueHistory(String slug) => _g('leagues/$slug/history');
  Future<Map<String, dynamic>> settings(String slug) async => jMap((await _g('leagues/$slug/settings'))['settings']);
  Future<Map<String, dynamic>> saveSettings(String slug, Map<String, dynamic> f) async => jMap((await _p('leagues/$slug/settings', f))['settings']);
  Future<void> leagueLogo(String slug, List<int> b, String n) => _a.upload('/api/app/leagues/$slug/logo', const {}, 'logo', b, n);
  Future<void> kick(String slug, int uid) => _p('leagues/$slug/members/$uid/kick');
  Future<List<Map<String, dynamic>>> codes(String slug) async => jList((await _g('codes', {'league': slug}))['codes']);
  Future<Map<String, dynamic>> codeCreate({String? league, String? clan, String label = '', int maxUses = 0}) => _p('codes/create', {if (league != null) 'league': league, if (clan != null) 'clan': clan, 'label': label, 'max_uses': maxUses});
  Future<void> codeToggle(int id) => _p('codes/$id/toggle');
  Future<void> codeDelete(int id) => _a.delete('/api/app/codes/$id');

  // clans
  Future<List<Clan>> clans({String? league}) async => jListOf((await _g('clans', league == null ? null : {'league': league}))['items'], Clan.fromJson);
  Future<Map<String, dynamic>> clan(String slug) => _g('clans/$slug');
  Future<Clan> createClan(String name, String league, {String motto = '', bool open = true}) async => Clan.fromJson(jMap((await _p('clans', {'name': name, 'league': league, 'motto': motto, 'open': open}))['clan']));
  Future<Map<String, dynamic>> joinClan(String slug) => _p('clans/$slug/join');
  Future<void> leaveClan(String slug) => _p('clans/$slug/leave');
  Future<List<Map<String, dynamic>>> clanRequests(String slug) async => jList((await _g('clans/$slug/requests'))['items']);
  Future<void> clanRequestAction(String slug, int id, bool accept) => _p('clans/$slug/requests/$id', {'accept': accept});
  Future<void> clanRole(String slug, int uid, String role) => _p('clans/$slug/members/$uid/role', {'role': role});
  Future<void> clanKick(String slug, int uid) => _p('clans/$slug/members/$uid/kick');
  Future<void> clanTransfer(String slug, int uid) => _p('clans/$slug/transfer', {'to': uid});
  Future<void> clanDissolve(String slug) => _p('clans/$slug/dissolve', {'confirm': 'DISSOLVE'});
  Future<void> clanSettings(String slug, Map<String, dynamic> f) => _p('clans/$slug/settings', f);
  Future<void> clanLogo(String slug, List<int> b, String n) => _a.upload('/api/app/clans/$slug/logo', const {}, 'logo', b, n);

  // chat / social
  Future<Map<String, dynamic>> chat(String kind, String slug, {int after = 0}) => _g('chat/$kind/$slug', {'after': after});
  Future<void> send(String kind, String slug, String text, {bool announce = false}) => _p('chat/$kind/$slug', {'text': text, 'announce': announce});
  Future<void> report(String kind, String slug, int id, String reason) => _p('chat/$kind/$slug/$id/report', {'reason': reason});
  Future<List<Map<String, dynamic>>> blocks() async => jList((await _g('blocks'))['items']);
  Future<void> block(int uid) => _p('blocks', {'user': uid});
  Future<void> unblock(int uid) => _a.delete('/api/app/blocks/$uid');
  Future<Map<String, dynamic>> notifications() => _g('notifications');
  Future<void> markRead([List<int>? ids]) => _p('notifications/read', ids == null ? {} : {'ids': ids});
  Future<void> prefs(Map<String, bool> p) => _p('notifications/prefs', p);
  Future<void> pushToken(String token, String platform) => _p('push/subscribe', {'token': token, 'platform': platform});
  Future<Map<String, dynamic>> manager(int id) => _g('managers/$id');
}
