import '../core/json.dart';
import 'player.dart';
class MatchEvent { final int minute; final String type, player; final bool home; final String? assist; const MatchEvent(this.minute, this.type, this.player, this.home, this.assist);
  factory MatchEvent.fromJson(Map<String, dynamic> j) => MatchEvent(jInt(j['minute']), jStr(j['type']), jStr(j['player']), jBool(j['home']), jStrN(j['assist'])); }
class Fixture {
  final int id, gw, min; final Club home, away; final String status; final int? hs, as_; final String? ko; final List<MatchEvent> events;
  const Fixture({required this.id, required this.gw, required this.min, required this.home, required this.away, required this.status, this.hs, this.as_, this.ko, required this.events});
  factory Fixture.fromJson(Map<String, dynamic> j) => Fixture(id: jInt(j['id']), gw: jInt(j['gw']), min: jInt(j['min'] ?? j['minute']), home: Club.fromJson(j['home']), away: Club.fromJson(j['away']), status: jStr(j['status'], 'up'), hs: jIntN(j['hs']), as_: jIntN(j['as']), ko: jStrN(j['ko'] ?? j['kickoff']), events: jListOf(j['events'], MatchEvent.fromJson));
  String get label => status == 'live' ? 'ON PLAY' : status == 'ft' ? 'FINISHED' : 'UPCOMING';
}
