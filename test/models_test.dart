import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_warzone/core/json.dart';
import 'package:fpl_warzone/models/player.dart';
import 'package:fpl_warzone/models/league.dart';
import 'package:fpl_warzone/models/fixture.dart';

void main() {
  test('json helpers tolerate nulls', () { expect(jInt(null, 3), 3); expect(jBool('1'), true); expect(jStrN(null), null); expect(jList(null), isEmpty); });
  test('player parses contract shape and legacy flat club', () {
    final p = Player.fromJson({'id': 55, 'name': 'Haaland', 'pos': 'FWD', 'club': {'id': 13, 'code': 'MCI', 'name': 'Man City', 'color': '#6CABDD', 'fpl_code': 43}, 'price': 14.0, 'code': 223094, 'pts': 82, 'next': [{'gw': 9, 'opp': 'BHA', 'ha': 'A', 'fdr': 3}], 'slot': 12, 'c': true});
    expect(p.club.code, 'MCI'); expect(p.club.badgeUrl, endsWith('/img/badge/43.png')); expect(p.photoUrl, endsWith('/img/player/223094.png')); expect(p.next.first.opp, 'BHA'); expect(p.bench, true); expect(p.c, true);
    final q = Player.fromJson({'id': 1, 'name': 'X', 'pos': 'GK', 'club': 'ARS', 'color': '#EF0107'}); expect(q.club.code, 'ARS'); expect(q.club.fplCode, null);
  });
  test('league + row', () { final l = League.fromJson({'slug': 'bb', 'name': 'Bhai Brothers', 'modes': ['ranking', 'survivor'], 'joined': true, 'my_survivor': 'SAFE'}); expect(l.has('survivor'), true); expect(l.mySurvivor, 'SAFE');
    final r = StandingRow.fromJson({'rank': 3, 'user_id': 1, 'name': 'A', 'team': 'B', 'gw': 50, 'total': 300, 'mv': 2, 'form': [50, 60], 'me': true}); expect(r.form.length, 2); expect(r.me, true); });
  test('fixture status label', () { final f = Fixture.fromJson({'id': 1, 'gw': 8, 'home': {'code': 'MCI', 'name': 'Man City', 'color': '#6CABDD'}, 'away': {'code': 'BUR', 'name': 'Burnley', 'color': '#6C1D45'}, 'status': 'live', 'hs': 2, 'as': 0, 'min': 65}); expect(f.label, 'ON PLAY'); expect(f.as_, 0); });
}
