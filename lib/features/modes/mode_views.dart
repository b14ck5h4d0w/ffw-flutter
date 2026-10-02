import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';

/// Game-mode screens.
/// A33 Modes Hub (/modes) — GET /api/app/modes → modes[{key, name, summary, leagues}].
/// Inside a league (tabs of LeaguePage):
///   A44–A47 Last Survivor — GET leagues/<slug>/survivor → {round, gws[], live, drop, alive[], out[], rounds[], winner}
///   A38–A43 Civil War     — GET leagues/<slug>/civil-war → {n, clan_size, facts, current{gw, complete, rows[]}, table[]}
///   A51–A55 Head-to-Head  — GET leagues/<slug>/h2h → {champion, rounds[{name, gw, matches[{a, b, winner}]}]}

const kModes = {
  'ranking': (name: 'Ranking', color: Wz.gold, icon: Icons.emoji_events_rounded, tag: 'Climb. Compete. Be legendary.', type: 'Season long'),
  'civil-war': (name: 'Civil War', color: Wz.red, icon: Icons.close_rounded, tag: 'Clans. Rivals. Total war.', type: 'Clan vs clan'),
  'survivor': (name: 'Last Survivor', color: Wz.purple2, icon: Icons.dangerous_outlined, tag: 'Survive the round. Stay alive.', type: 'Knockout'),
  'h2h': (name: 'Head-to-Head', color: Wz.cyan, icon: Icons.shield_outlined, tag: 'One vs one. No excuses.', type: '1 vs 1'),
};

BoxDecoration _box({Color? border, Color? color}) => BoxDecoration(color: color ?? Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
EdgeInsets _pad(BuildContext c) => Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 6, 14, 24) : const EdgeInsets.fromLTRB(24, 6, 24, 28);
String _ini(String s) => s.trim().isEmpty ? '?' : s.trim().substring(0, s.trim().length >= 2 ? 2 : 1).toUpperCase();
Widget _title(IconData i, Color col, String t, {Widget? trailing}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(i, color: col, size: 20), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))), if (trailing != null) trailing]));
Widget _stat(String v, String k, Color col) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(10), border: Border.all(color: col.withValues(alpha: .45))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: col, fontSize: 19, fontWeight: FontWeight.w700)), Text(k, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5))]));

/// Mode header inside a league tab: mode colour, title, tagline, stat tiles.
class _ModeHead extends StatelessWidget {
  final String mode, tagline; final List<Widget> stats;
  const _ModeHead({required this.mode, required this.tagline, this.stats = const []});
  @override Widget build(BuildContext c) {
    final m = kModes[mode]!;
    return Container(margin: const EdgeInsets.only(bottom: 14), padding: EdgeInsets.all(Bp.compact(c) ? 16 : 20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: m.color.withValues(alpha: .5)),
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [m.color.withValues(alpha: .22), Wz.panel, Wz.panel])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(m.icon, color: m.color, size: 30), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${m.name.toUpperCase()} MODE', style: anton(Bp.compact(c) ? 24 : 30, color: Colors.white, spacing: .8)),
          Text(tagline, style: TextStyle(color: m.color, fontSize: 13.5, fontWeight: FontWeight.w600)),
        ]))]),
        if (stats.isNotEmpty) ...[const SizedBox(height: 14), Wrap(spacing: 10, runSpacing: 10, children: stats)],
      ]));
  }
}

// ======================================================================================
// Last Survivor
// ======================================================================================

class SurvivorView extends StatelessWidget {
  final String slug; const SurvivorView(this.slug, {super.key});
  @override Widget build(BuildContext c) => Async(load: () => Repo.I.survivor(slug), poll: const Duration(seconds: 60), builder: (c, j, _) {
    final alive = jList(j['alive']), out = jList(j['out']), rounds = jList(j['rounds']);
    final gws = (j['gws'] as List? ?? const []).map((e) => jInt(e)).toList();
    final me = alive.where((a) => jBool(a['me'])).firstOrNull; final meOut = out.where((a) => jBool(a['me'])).firstOrNull;
    final winner = j['winner'] == null ? null : jMap(j['winner']);
    final live = jBool(j['live']);
    final risky = alive.where((a) => jStr(a['status']) == 'AT RISK').toList(), safe = alive.where((a) => jStr(a['status']) != 'AT RISK').toList();
    final mine = winner != null ? null : meOut != null ? 'OUT' : me == null ? null : jStr(me['status'], 'SAFE');

    Widget row(Map<String, dynamic> a) {
      final risk = jStr(a['status']) == 'AT RISK'; final per = jMap(a['per_gw']);
      return InkWell(onTap: a['user_id'] == null ? null : () => c.push('/manager/${a['user_id']}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: jBool(a['me']) ? Wz.green.withValues(alpha: .1) : risk ? Wz.red.withValues(alpha: .07) : Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: risk ? Wz.red.withValues(alpha: .55) : jBool(a['me']) ? Wz.green.withValues(alpha: .5) : Wz.border2)),
        child: Row(children: [
          SizedBox(width: 30, child: Text('${a['rank'] ?? '–'}', style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700))),
          HexAvatar(_ini(jStr(a['team'], jStr(a['name']))), url: jStrN(a['avatar']), size: 34, color: risk ? Wz.red : Wz.green), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Flexible(child: Text(jStr(a['team'], jStr(a['name'])), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600))), if (jBool(a['me'])) const Padding(padding: EdgeInsets.only(left: 6), child: Text('YOU', style: TextStyle(color: Wz.green, fontSize: 10, fontWeight: FontWeight.w800)))]),
            Text([jStr(a['name']), if (a['clan'] != null) jStr(a['clan']), for (final g in gws) 'GW$g ${per['$g'] ?? '–'}'].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
          ])),
          Text('${a['pts'] ?? 0}', style: TextStyle(color: risk ? Wz.red : Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(width: 10),
          StatusPill(jStr(a['status'], 'SAFE')),
        ])));
    }

    final standings = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.leaderboard_rounded, Wz.purple2, live ? 'Live Standings' : 'Standings', trailing: Text('${alive.length} alive', style: const TextStyle(color: Wz.muted, fontSize: 12))),
      if (alive.isEmpty) const Text('No managers in this mode yet.', style: TextStyle(color: Wz.muted)),
      for (final a in safe) row(a),
      if (risky.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [const Expanded(child: Divider(color: Wz.red)), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(live ? 'DANGER LINE · AT RISK' : 'DANGER LINE', style: const TextStyle(color: Wz.red, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6))), const Expanded(child: Divider(color: Wz.red))])),
        for (final a in risky) row(a),
      ],
    ]));
    final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(padding: const EdgeInsets.all(16), decoration: _box(border: Wz.red.withValues(alpha: .4)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.timer_outlined, Wz.red, winner != null ? 'Champion' : 'Next Elimination'),
        if (winner != null) Row(children: [const Icon(Icons.emoji_events_rounded, color: Wz.gold, size: 32), const SizedBox(width: 12), Expanded(child: Text(jStr(winner['team'], jStr(winner['name'])), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)))])
        else ...[
          Text(gws.isEmpty ? 'Round ${j['round'] ?? '–'}' : 'Round ${j['round'] ?? '–'} · GW ${gws.first}${gws.length > 1 ? '–${gws.last}' : ''}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('The lowest ${j['drop'] ?? 1} ${jInt(j['drop'], 1) == 1 ? 'manager is' : 'managers are'} eliminated when the round ends.${live ? ' Until then, the bottom places are only AT RISK.' : ''}', style: const TextStyle(color: Wz.muted, fontSize: 13, height: 1.4)),
        ],
      ])),
      if (rounds.isNotEmpty) ...[const SizedBox(height: 14), Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.view_timeline_outlined, Wz.purple2, 'Rounds'),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final r in rounds) () {
          final done = jBool(r['complete']); final g = (r['gws'] as List? ?? const []); final el = (r['eliminated'] as List? ?? const []).length;
          return Container(width: 84, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: done ? Wz.bg.withValues(alpha: .6) : Wz.red.withValues(alpha: .12), borderRadius: BorderRadius.circular(8), border: Border.all(color: done ? Wz.border2 : Wz.red.withValues(alpha: .7))),
            child: Column(children: [Text('R${r['rd']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), Text(g.isEmpty ? '' : 'GW ${g.first}${g.length > 1 ? '–${g.last}' : ''}', style: const TextStyle(color: Wz.muted, fontSize: 10.5)), Text(done ? '$el out' : 'live', style: TextStyle(color: done ? Wz.muted : Wz.red, fontSize: 10.5, fontWeight: FontWeight.w600))]));
        }()]),
      ]))],
      if (out.isNotEmpty) ...[const SizedBox(height: 14), Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.history_rounded, Wz.muted, 'Elimination History', trailing: Text('${out.length} out', style: const TextStyle(color: Wz.muted, fontSize: 12))),
        for (final o in out) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
          Expanded(child: Text(jStr(o['team'], jStr(o['name'])), overflow: TextOverflow.ellipsis, style: TextStyle(color: jBool(o['me']) ? Wz.green : Colors.white70, fontSize: 13.5))),
          Text('Round ${o['round_out'] ?? '–'} · ${o['pts'] ?? 0} pts', style: const TextStyle(color: Wz.muted, fontSize: 12)), const SizedBox(width: 10), const StatusPill('OUT'),
        ])),
      ]))],
    ]);
    return ListView(padding: _pad(c), children: [
      _ModeHead(mode: 'survivor', tagline: 'Survive. Adapt. Be the last.', stats: [
        _stat('${alive.length + out.length}', 'Total Players', Colors.white), _stat('${alive.length}', 'Remaining', Wz.green), _stat('${out.length}', 'Eliminated', Wz.red),
        if (mine != null) _stat(mine, 'Your Status', mine == 'SAFE' ? Wz.green : mine == 'OUT' ? Wz.muted : Wz.red),
      ]),
      MediaQuery.of(c).size.width >= 1100 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: standings), const SizedBox(width: 16), Expanded(flex: 2, child: side)])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [standings, const SizedBox(height: 14), side]),
    ]);
  });
}

// ======================================================================================
// Civil War — never SAFE / AT RISK / OUT: clan gameweek score, position and War Points only.
// ======================================================================================

class CivilWarView extends StatelessWidget {
  final String slug; const CivilWarView(this.slug, {super.key});
  @override Widget build(BuildContext c) => Async(load: () => Repo.I.civilWar(slug), poll: const Duration(seconds: 60), builder: (c, j, _) {
    final table = jList(j['table']); final cur = jMap(j['current']); final rows = jList(cur['rows']); final facts = jMap(j['facts']);
    final done = jBool(cur['complete']);
    final myClan = table.where((t) => jBool(t['me'])).firstOrNull;

    final battle = rows.isEmpty ? null : Container(padding: const EdgeInsets.all(16), decoration: _box(border: (done ? Wz.border2 : Wz.red.withValues(alpha: .5))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.bolt_rounded, Wz.red, 'Gameweek ${cur['gw'] ?? ''} Battle', trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: (done ? Wz.green : Wz.gold).withValues(alpha: .14), borderRadius: BorderRadius.circular(20), border: Border.all(color: (done ? Wz.green : Wz.gold).withValues(alpha: .6))),
        child: Text(done ? 'FINAL' : 'PROJECTED', style: TextStyle(color: done ? Wz.green : Wz.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8)))),
      if (!done) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Live gameweek — War Points are projected and lock when the gameweek is official.', style: TextStyle(color: Wz.muted, fontSize: 12.5))),
      for (final r in rows) InkWell(onTap: () => c.push('/clan/${r['slug']}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: jBool(r['me']) ? Wz.green.withValues(alpha: .1) : Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: jBool(r['me']) ? Wz.green.withValues(alpha: .5) : Wz.border2)),
        child: Row(children: [
          SizedBox(width: 32, child: Text('#${r['pos']}', style: TextStyle(color: jInt(r['pos']) == 1 ? Wz.gold : Colors.white70, fontSize: 15, fontWeight: FontWeight.w700))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(jStr(r['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
            Text(jList(r['members']).map((m) => '${jStr(m['name']).split(' ').first} ${m['pts']}').join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${r['gw_pts'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const Text('GW pts', style: TextStyle(color: Wz.muted, fontSize: 10.5))]),
          const SizedBox(width: 12),
          Container(width: 62, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Wz.red.withValues(alpha: done ? .25 : .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Wz.red.withValues(alpha: .6))),
            child: Column(children: [Text('+${r['award'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)), Text(done ? 'War Pts' : 'proj.', style: const TextStyle(color: Wz.muted, fontSize: 10))])),
        ]))),
    ]));
    final standings = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.military_tech_outlined, Wz.red, 'Clan Standings', trailing: Text('${table.length} clans', style: const TextStyle(color: Wz.muted, fontSize: 12))),
      if (table.isEmpty) const Text('No clans yet. Clans are formed from the Clans page.', style: TextStyle(color: Wz.muted)),
      for (final t in table) InkWell(onTap: () => c.push('/clan/${t['slug']}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: jBool(t['me']) ? Wz.green.withValues(alpha: .1) : Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: jBool(t['me']) ? Wz.green.withValues(alpha: .5) : Wz.border2)),
        child: Row(children: [
          SizedBox(width: 30, child: Text('${t['rank']}', style: TextStyle(color: jInt(t['rank']) == 1 ? Wz.gold : Colors.white70, fontSize: 15, fontWeight: FontWeight.w700))),
          HexAvatar(_ini(jStr(t['code'], jStr(t['name']))), url: jStrN(t['logo']), size: 34, color: Wz.red), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Flexible(child: Text(jStr(t['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600))), if (jBool(t['me'])) const Padding(padding: EdgeInsets.only(left: 6), child: Text('YOUR CLAN', style: TextStyle(color: Wz.green, fontSize: 10, fontWeight: FontWeight.w800)))]),
            Text([if (t['wins'] != null) '${t['wins']} GW wins', if (t['pts'] != null) '${t['pts']} FPL pts', if (jStr(t['leader']).isNotEmpty) 'Captain ${t['leader']}'].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${t['war_pts'] ?? t['rank_pts'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const Text('War Points', style: TextStyle(color: Wz.muted, fontSize: 10.5))]),
        ]))),
    ]));
    final rules = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.gavel_rounded, Wz.gold, 'War Points'),
      for (final t in const ["A clan's gameweek score is the total of its members' official FPL points.", 'Top clan of the gameweek earns 10 War Points; the lowest earns 1.', 'War Points are projected during a live gameweek and locked when it is official.', 'No one is eliminated in Civil War.'])
        Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 5, color: Wz.red)), const SizedBox(width: 10), Expanded(child: Text(t, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13, height: 1.4)))])),
    ]));
    final wide = MediaQuery.of(c).size.width >= 1100;
    return ListView(padding: _pad(c), children: [
      _ModeHead(mode: 'civil-war', tagline: 'Same league. Same passion. Different sides.', stats: [
        _stat('${j['n'] ?? table.length}', 'Clans', Colors.white), if (j['clan_size'] != null) _stat('${j['clan_size']}', 'Members per Clan', Wz.cyan),
        if (jStr(facts['leader']).isNotEmpty) _stat(jStr(facts['leader']), 'Leading Clan', Wz.gold),
        if (myClan != null) _stat('#${myClan['rank']}', 'Your Clan', Wz.green),
      ]),
      wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: Column(children: [if (battle != null) ...[battle, const SizedBox(height: 14)], standings])), const SizedBox(width: 16), Expanded(flex: 2, child: rules)])
           : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (battle != null) ...[battle, const SizedBox(height: 14)], standings, const SizedBox(height: 14), rules]),
    ]);
  });
}

// ======================================================================================
// Head-to-Head
// ======================================================================================

class H2HView extends StatelessWidget {
  final String slug; const H2HView(this.slug, {super.key});
  @override Widget build(BuildContext c) => Async(load: () => Repo.I.h2h(slug), poll: const Duration(seconds: 60), builder: (c, j, _) {
    final rounds = jList(j['rounds']); final champ = j['champion'] == null ? null : jMap(j['champion']);
    final total = rounds.fold<int>(0, (s, r) => s + jList(r['matches']).length);
    final played = rounds.fold<int>(0, (s, r) => s + jList(r['matches']).where((m) => jStr(m['winner']).isNotEmpty).length);

    Widget side(Map<String, dynamic> p, bool win, bool decided, {bool right = false}) => Expanded(child: Row(mainAxisAlignment: right ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
      if (!right) HexAvatar(_ini(jStr(p['name'])), url: jStrN(p['avatar']), size: 32, color: win ? Wz.green : Wz.cyan),
      if (!right) const SizedBox(width: 10),
      Flexible(child: Text(jStr(p['name'], 'TBD'), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: right ? TextAlign.right : TextAlign.left, style: TextStyle(color: decided && !win ? Wz.muted : Colors.white, fontSize: 14, fontWeight: win ? FontWeight.w700 : FontWeight.w500))),
      if (right) const SizedBox(width: 10),
      if (right) HexAvatar(_ini(jStr(p['name'])), url: jStrN(p['avatar']), size: 32, color: win ? Wz.green : Wz.cyan),
    ]));

    return ListView(padding: _pad(c), children: [
      _ModeHead(mode: 'h2h', tagline: "It's not just points. It's personal.", stats: [
        _stat('${rounds.length}', 'Rounds', Colors.white), _stat('$played / $total', 'Matches Played', Wz.cyan),
        if (champ != null) _stat(jStr(champ['name']), 'Champion', Wz.gold),
      ]),
      if (rounds.isEmpty) Container(padding: const EdgeInsets.all(24), decoration: _box(), child: const Center(child: Text('The bracket has not been drawn yet.', style: TextStyle(color: Wz.muted)))),
      for (final r in rounds) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.account_tree_outlined, Wz.cyan, jStr(r['name'], 'Round'), trailing: Text('GW ${r['gw'] ?? '–'}', style: const TextStyle(color: Wz.muted, fontSize: 12.5))),
        for (final m in jList(r['matches'])) () {
          final a = jMap(m['a']), b = jMap(m['b']); final w = jStr(m['winner']); final decided = w.isNotEmpty;
          return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: (jBool(a['me']) || jBool(b['me'])) ? Wz.green.withValues(alpha: .5) : Wz.border2)),
            child: Row(children: [
              side(a, w == 'a', decided),
              Container(width: 96, margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: Wz.panel2, borderRadius: BorderRadius.circular(8)),
                child: Text(a['pts'] == null && b['pts'] == null ? 'vs' : '${a['pts'] ?? '–'}  :  ${b['pts'] ?? '–'}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
              side(b, w == 'b', decided, right: true),
            ]));
        }(),
      ])),
    ]);
  });
}

// ======================================================================================
// A33 — Modes Hub
// ======================================================================================

class ModesPage extends StatelessWidget {
  const ModesPage({super.key});
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: Repo.I.modes, builder: (c, ms, _) {
    final compact = Bp.compact(c);
    Map<String, dynamic>? of(String k) => ms.where((x) => x['key'] == k).firstOrNull;
    return ListView(padding: compact ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      Container(height: compact ? null : 220, clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
        Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .45)], stops: const [.35, 1])))),
        if (!compact) Positioned(right: 190, top: 6, bottom: -210, child: Image.asset(WzAssets.player10, fit: BoxFit.fitHeight, alignment: Alignment.topCenter)),
        if (!compact) Positioned(right: 22, top: 30, child: Transform.rotate(angle: -.14, child: Column(children: [const FfwCrown(size: 30), Text('Choose your\nbattlefield.', textAlign: TextAlign.center, style: script(30))]))),
        Padding(padding: EdgeInsets.all(compact ? 18 : 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('PLAY YOUR WAY', style: anton(compact ? 32 : 46, color: Colors.white, spacing: 1)),
          const Text('Four battlefields. One Warzone.', style: TextStyle(color: Wz.green, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Different modes, same passion. Modes are switched on per league by its owner.', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 13.5)),
        ])),
      ])),
      const SizedBox(height: 16),
      GridView.extent(maxCrossAxisExtent: 360, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: compact ? 1.5 : .98, children: [
        for (final k in kModes.keys) () {
          final m = kModes[k]!; final d = of(k); final n = jInt(d?['leagues']);
          return Container(clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: m.color.withValues(alpha: .6)),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [m.color.withValues(alpha: .28), Wz.panel], stops: const [0, .6])),
            padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(m.icon, color: m.color, size: 34), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(20), border: Border.all(color: (n > 0 ? Wz.green : Wz.muted).withValues(alpha: .7))),
                child: Text(n > 0 ? 'LIVE NOW' : 'NOT RUNNING', style: TextStyle(color: n > 0 ? Wz.green : Wz.muted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .8)))]),
              const SizedBox(height: 10),
              Text(m.name.toUpperCase(), style: anton(26, color: Colors.white, spacing: .8)),
              Text(m.tag, style: TextStyle(color: m.color, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(child: Text(jStr(d?['summary']), maxLines: compact ? 2 : 4, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 13, height: 1.4))),
              Row(children: [
                Icon(Icons.emoji_events_outlined, size: 15, color: m.color), const SizedBox(width: 5), Text('$n league${n == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(width: 14), const Icon(Icons.category_outlined, size: 15, color: Wz.muted), const SizedBox(width: 5), Text(m.type, style: const TextStyle(color: Wz.muted, fontSize: 12.5)),
              ]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, height: 38, child: FilledButton(onPressed: () => c.go(Session.I.loggedIn ? '/leagues' : '/leagues/directory'), style: FilledButton.styleFrom(backgroundColor: m.color, foregroundColor: k == 'ranking' || k == 'h2h' ? Wz.bg : Colors.white), child: Text(Session.I.loggedIn ? 'Play in My Leagues' : 'Find a League'))),
            ]));
        }(),
      ]),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(18), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.help_outline_rounded, Wz.green, 'How Modes Work'),
        for (final t in const ['Every league can run one or more modes at the same time — all from the same FPL points.', 'The league owner switches modes on from League Settings.', 'Open a league to see its Standings, Last Survivor, Civil War and Head-to-Head tabs.'])
          Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 5, color: Wz.green)), const SizedBox(width: 10), Expanded(child: Text(t, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13.5, height: 1.4)))])),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          if (Session.I.loggedIn) OutlinedButton.icon(onPressed: () => c.go('/create-league'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Create a League')),
          OutlinedButton.icon(onPressed: () => c.go('/leagues/directory'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), icon: const Icon(Icons.travel_explore_rounded, size: 18), label: const Text('Discover Leagues')),
        ]),
      ])),
    ]);
  })));
}
