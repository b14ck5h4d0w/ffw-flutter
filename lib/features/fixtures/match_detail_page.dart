import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/theme.dart';
import '../../models/fixture.dart';
import 'fixture_widgets.dart';

/// A18 Match Detail · A19 Timeline · A20 Lineups (/match/:id?tab=overview|timeline|lineups).
/// GET /api/app/matches/<id> → {fixture, timeline[{minute,type,player,home,assist}],
/// home_lineup[] / away_lineup[] ({name,pos,pts,mine}), stats[] (currently empty)}.
/// Match facts are counted from the timeline. Polls every 30s while the match is live.
class MatchDetailPage extends StatefulWidget { final int id; final String? tab; const MatchDetailPage(this.id, {super.key, this.tab}); @override State<MatchDetailPage> createState() => _MatchState(); }

class _MatchState extends State<MatchDetailPage> {
  static const _tabs = [('overview', 'Overview'), ('timeline', 'Timeline'), ('lineups', 'Lineups')];
  late String tab = _tabs.any((t) => t.$1 == widget.tab) ? widget.tab! : 'overview';
  bool _live = false;

  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: () => Repo.I.match(widget.id), poll: _live ? const Duration(seconds: 30) : const Duration(minutes: 5), builder: (c, j, _) {
    final f = Fixture.fromJson(jMap(j['fixture']));
    final tl = jListOf(j['timeline'], MatchEvent.fromJson)..sort((a, b) => a.minute.compareTo(b.minute));
    final hl = jList(j['home_lineup']), al = jList(j['away_lineup']);
    final live = f.status == 'live';
    if (live != _live) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _live = live); });
    return ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 10, 14, 24) : const EdgeInsets.fromLTRB(24, 18, 24, 28), children: [
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => c.canPop() ? c.pop() : c.go('/fixtures?gw=${f.gw}'), style: TextButton.styleFrom(foregroundColor: Colors.white70),
          icon: const Icon(Icons.arrow_back_rounded, size: 18), label: Text('Gameweek ${f.gw}'))),
      const SizedBox(height: 6),
      _hero(c, f, tl),
      const SizedBox(height: 14),
      _tabBar(),
      const SizedBox(height: 14),
      switch (tab) { 'timeline' => _timeline(c, f, tl), 'lineups' => _lineups(c, f, hl, al), _ => _overview(c, f, tl, hl, al) },
    ]);
  })));

  // ---------- hero ----------
  Widget _hero(BuildContext c, Fixture f, List<MatchEvent> tl) {
    final compact = Bp.compact(c);
    final live = f.status == 'live', up = f.status == 'up';
    final d = kickoffLocal(f);
    List<Widget> scorers(bool home) => [for (final e in tl.where((e) => e.type == 'goal' && e.home == home))
      Text("${e.player.split(' ').last} ${e.minute}'", textAlign: home ? TextAlign.right : TextAlign.left, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12.5))];
    Widget team(club) => Expanded(child: Column(children: [
      ClubBadge(club, size: compact ? 52 : 76), const SizedBox(height: 8),
      Text(compact ? club.code : club.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: compact ? 16 : 20, fontWeight: FontWeight.w700)),
    ]));
    return Container(padding: EdgeInsets.fromLTRB(16, compact ? 18 : 26, 16, compact ? 16 : 22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: live ? Wz.red.withValues(alpha: .6) : Wz.border2),
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Wz.hex(f.home.color).withValues(alpha: .45), Wz.panel, Wz.panel, Wz.hex(f.away.color).withValues(alpha: .45)], stops: const [0, .38, .62, 1])),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (live ? Wz.red : up ? Wz.green : Wz.muted).withValues(alpha: .15), borderRadius: BorderRadius.circular(20), border: Border.all(color: (live ? Wz.red : up ? Wz.green : Wz.muted).withValues(alpha: .6))),
          child: Text(live ? "LIVE · ${f.min}'" : up ? 'UPCOMING' : 'FULL TIME', style: TextStyle(color: live ? Wz.red : up ? Wz.green : Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1))),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          team(f.home),
          Padding(padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 24), child: up
              ? Column(children: [Text(d == null ? 'TBC' : DateFormat('HH:mm').format(d), style: anton(compact ? 36 : 52, color: Wz.green, spacing: 1)), Text(d == null ? '' : DateFormat('EEE d MMM').format(d), style: const TextStyle(color: Wz.muted, fontSize: 12.5))])
              : Text('${f.hs ?? 0} – ${f.as_ ?? 0}', style: anton(compact ? 46 : 68, color: Colors.white, spacing: 2))),
          team(f.away),
        ]),
        if (!up && tl.any((e) => e.type == 'goal')) ...[
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: scorers(true))),
            Padding(padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 30), child: const Icon(Icons.sports_soccer_rounded, color: Colors.white54, size: 16)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: scorers(false))),
          ]),
        ],
        if (!up && d != null) ...[const SizedBox(height: 10), Text('${DateFormat('EEEE d MMMM, HH:mm').format(d)} · Gameweek ${f.gw}', style: const TextStyle(color: Wz.muted, fontSize: 12))],
        if (live) ...[const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: (f.min / 90).clamp(0, 1), minHeight: 4, color: Wz.red, backgroundColor: Wz.border2))],
      ]));
  }

  Widget _tabBar() => Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Row(children: [
    for (final t in _tabs) Expanded(child: InkWell(onTap: () => setState(() => tab = t.$1), borderRadius: BorderRadius.circular(7), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center,
      decoration: BoxDecoration(color: tab == t.$1 ? Wz.green.withValues(alpha: .16) : null, borderRadius: BorderRadius.circular(7), border: tab == t.$1 ? Border.all(color: Wz.green.withValues(alpha: .5)) : null),
      child: Text(t.$2, style: TextStyle(color: tab == t.$1 ? Wz.green : Colors.white70, fontSize: 14, fontWeight: FontWeight.w600))))),
  ]));

  Widget _card(String title, IconData icon, Color col, Widget body, {Widget? trailing}) => Container(padding: const EdgeInsets.all(16), decoration: fixtureBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [Icon(icon, color: col, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), if (trailing != null) trailing]),
    const SizedBox(height: 12), body,
  ]));

  static (IconData, Color, String) _ev(String type) => switch (type) {
    'goal' => (Icons.sports_soccer_rounded, Wz.green, 'Goal'),
    'yellow' => (Icons.square_rounded, Wz.gold, 'Yellow card'),
    'red' => (Icons.square_rounded, Wz.red, 'Red card'),
    'sub' => (Icons.swap_vert_rounded, Wz.cyan, 'Substitution'),
    'bonus' => (Icons.star_rounded, Wz.gold, 'Bonus'),
    _ => (Icons.circle, Wz.muted, type),
  };

  // ---------- overview (A18) ----------
  Widget _overview(BuildContext c, Fixture f, List<MatchEvent> tl, List<Map<String, dynamic>> hl, List<Map<String, dynamic>> al) {
    if (f.status == 'up') return _card('Before Kick-off', Icons.schedule_rounded, Wz.green, Text('Kick-off ${kickoffLabel(f)}. The timeline and lineups appear once the match starts.', style: const TextStyle(color: Wz.muted, height: 1.4)));
    final key = tl.where((e) => e.type == 'goal' || e.type == 'red' || e.type == 'yellow').toList();
    final mine = [...hl, ...al].where((p) => jBool(p['mine'])).toList();
    int n(String t, bool home) => tl.where((e) => e.type == t && e.home == home).length;
    final facts = [('Goals', f.hs ?? n('goal', true), f.as_ ?? n('goal', false)), ('Yellow cards', n('yellow', true), n('yellow', false)), ('Red cards', n('red', true), n('red', false)), ('Substitutions', n('sub', true), n('sub', false))];
    final left = _card('Key Events', Icons.bolt_rounded, Wz.gold, key.isEmpty ? const Text('No goals or cards yet.', style: TextStyle(color: Wz.muted)) : Column(children: [for (final e in key) _eventRow(f, e)]),
        trailing: TextButton(onPressed: () => setState(() => tab = 'timeline'), child: const Text('Full Timeline ›')));
    final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _card('Match Facts', Icons.bar_chart_rounded, Wz.cyan, Column(children: [
        Row(children: [Expanded(child: Text(f.home.code, style: const TextStyle(color: Wz.muted, fontSize: 12, fontWeight: FontWeight.w700))), Text(f.away.code, style: const TextStyle(color: Wz.muted, fontSize: 12, fontWeight: FontWeight.w700))]),
        for (final s in facts) _factRow(f, s.$1, s.$2, s.$3),
      ])),
      const SizedBox(height: 14),
      _card('Your Players', Icons.shield_outlined, Wz.green, mine.isEmpty ? const Text('None of your players are in this match.', style: TextStyle(color: Wz.muted, fontSize: 13))
          : Column(children: [for (final p in mine) _lineupRow(p, sane: false)])),
    ]);
    return MediaQuery.of(c).size.width >= 1100
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: left), const SizedBox(width: 16), Expanded(flex: 2, child: right)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 14), right]);
  }

  Widget _factRow(Fixture f, String label, int h, int a) {
    final t = h + a; final hc = Wz.hex(f.home.color), ac = Wz.hex(f.away.color);
    return Padding(padding: const EdgeInsets.only(top: 12), child: Column(children: [
      Row(children: [SizedBox(width: 30, child: Text('$h', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))), Expanded(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12.5))), SizedBox(width: 30, child: Text('$a', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)))]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(3), child: SizedBox(height: 5, child: t == 0 ? Container(color: Wz.border2) : Row(children: [
        Expanded(flex: h == 0 ? 0 : h, child: Container(color: Color.lerp(hc, Colors.white, .15))), if (h > 0 && a > 0) const SizedBox(width: 2), Expanded(flex: a == 0 ? 0 : a, child: Container(color: Color.lerp(ac, Colors.white, .15))),
      ]))),
    ]));
  }

  Widget _eventRow(Fixture f, MatchEvent e) {
    final (icon, col, label) = _ev(e.type);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 40, child: Text("${e.minute}'", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
      Icon(icon, color: col, size: e.type == 'yellow' || e.type == 'red' ? 15 : 19), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.player, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        Text(e.assist != null ? '$label · assist ${e.assist}' : label, style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
      ])),
      ClubBadge(e.home ? f.home : f.away, size: 22),
    ]));
  }

  // ---------- timeline (A19) ----------
  Widget _timeline(BuildContext c, Fixture f, List<MatchEvent> tl) {
    if (tl.isEmpty) return _card('Timeline', Icons.timeline_rounded, Wz.cyan, Text(f.status == 'up' ? 'The match has not started yet.' : 'No events yet.', style: const TextStyle(color: Wz.muted)));
    final compact = Bp.compact(c);
    Widget side(MatchEvent? e, bool left) {
      if (e == null) return const Expanded(child: SizedBox());
      final (_, _, label) = _ev(e.type);
      return Expanded(child: Column(crossAxisAlignment: left ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Text(compact ? e.player.split(' ').last : e.player, textAlign: left ? TextAlign.right : TextAlign.left, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: e.type == 'goal' ? FontWeight.w700 : FontWeight.w500)),
        Text(e.assist != null ? '$label · ${e.assist}' : label, style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
      ]));
    }
    return _card('Timeline', Icons.timeline_rounded, Wz.cyan, Column(children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text(f.home.name, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)), const SizedBox(width: 8), ClubBadge(f.home, size: 22)])),
        const SizedBox(width: 76),
        Expanded(child: Row(children: [ClubBadge(f.away, size: 22), const SizedBox(width: 8), Text(f.away.name, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))])),
      ])),
      for (final e in tl) () {
        final (icon, col, _) = _ev(e.type);
        return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [side(e.home ? e : null, true)])).expanded(),
          SizedBox(width: 76, child: Stack(alignment: Alignment.center, children: [
            Container(width: 2, color: Wz.border2),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Wz.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: col.withValues(alpha: .7))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: col, size: 13), const SizedBox(width: 4), Text("${e.minute}'", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))])),
          ])),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [side(e.home ? null : e, false)])).expanded(),
        ]));
      }(),
    ]), trailing: Text('${tl.length} events', style: const TextStyle(color: Wz.muted, fontSize: 12)));
  }

  // ---------- lineups (A20) ----------
  Widget _lineups(BuildContext c, Fixture f, List<Map<String, dynamic>> hl, List<Map<String, dynamic>> al) {
    if (hl.isEmpty && al.isEmpty) return _card('Lineups', Icons.groups_rounded, Wz.green, Text(f.status == 'up' ? 'Lineups appear close to kick-off.' : 'Lineups are not available for this match.', style: const TextStyle(color: Wz.muted)));
    // Positions are only shown when the feed looks trustworthy (a real XI has GK, DEF, MID and FWD).
    bool sane(List<Map<String, dynamic>> l) => l.map((p) => jStr(p['pos'])).toSet().length >= 4;
    Widget team(club, List<Map<String, dynamic>> l) => Container(padding: const EdgeInsets.all(16), decoration: fixtureBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [ClubBadge(club, size: 26), const SizedBox(width: 10), Expanded(child: Text(club.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))), const Text('RATING', style: TextStyle(color: Wz.muted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1))]),
      const SizedBox(height: 10),
      if (l.isEmpty) const Text('Not available.', style: TextStyle(color: Wz.muted)) else for (final p in l) _lineupRow(p, sane: sane(l)),
    ]));
    final h = team(f.home, hl), a = team(f.away, al);
    return MediaQuery.of(c).size.width >= 760
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: h), const SizedBox(width: 16), Expanded(child: a)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [h, const SizedBox(height: 14), a]);
  }

  Widget _lineupRow(Map<String, dynamic> p, {required bool sane}) {
    final mine = jBool(p['mine']); final r = p['pts'] is num ? (p['pts'] as num).toDouble() : null;
    final col = r == null ? Wz.muted : r >= 7.5 ? Wz.green : r >= 6.5 ? Colors.white : Wz.gold;
    return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: mine ? Wz.green.withValues(alpha: .1) : Wz.bg.withValues(alpha: .5), borderRadius: BorderRadius.circular(8), border: Border.all(color: mine ? Wz.green.withValues(alpha: .5) : Wz.border)),
      child: Row(children: [
        if (sane) SizedBox(width: 38, child: Text(jStr(p['pos']), style: const TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w700))),
        Expanded(child: Text(jStr(p['name']), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        if (mine) const Padding(padding: EdgeInsets.only(right: 8), child: Tooltip(message: 'In your team', child: Icon(Icons.shield_rounded, color: Wz.green, size: 16))),
        if (r != null) Text(r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1), style: TextStyle(color: col, fontSize: 14.5, fontWeight: FontWeight.w700)),
      ]));
  }
}

extension on Widget { Widget expanded() => Expanded(child: this); }
