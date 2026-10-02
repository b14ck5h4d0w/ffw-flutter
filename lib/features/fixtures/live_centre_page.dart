import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/fixture.dart';
import '../../models/player.dart';
import 'fixture_widgets.dart';

/// A17 — Live Match Centre (/live).
/// GET /api/app/fixtures (current GW) → live matches as big cards, then up next and finished.
/// Signed in with an FPL team: "Your players in action" = squad picks whose club is playing now
/// (matched by club code against the live fixtures — no extra endpoint). Polls every 30s while live.
class LiveCentrePage extends StatefulWidget { const LiveCentrePage({super.key}); @override State<LiveCentrePage> createState() => _LiveState(); }

class _LiveState extends State<LiveCentrePage> {
  bool _live = false;

  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: () => Repo.I.fixtures(), poll: _live ? const Duration(seconds: 30) : const Duration(minutes: 5), builder: (c, j, _) {
    final all = jListOf(j['fixtures'], Fixture.fromJson);
    final gw = jIntN(j['gw']) ?? (all.isNotEmpty ? all.first.gw : jInt(j['current'], 1));
    final live = all.where((f) => f.status == 'live').toList();
    final up = all.where((f) => f.status == 'up').toList()..sort((a, b) => (kickoffLocal(a) ?? DateTime(3000)).compareTo(kickoffLocal(b) ?? DateTime(3000)));
    final ft = all.where((f) => f.status == 'ft').toList()..sort((a, b) => (kickoffLocal(b) ?? DateTime(0)).compareTo(kickoffLocal(a) ?? DateTime(0)));
    if (live.isNotEmpty != _live) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _live = live.isNotEmpty); });
    final wide = MediaQuery.of(c).size.width >= 1100;
    final main = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (live.isNotEmpty) _liveSection(c, live) else _quiet(c, gw, up, all),
      if (up.isNotEmpty) ...[const SizedBox(height: 14), _section('Up Next', Icons.schedule_rounded, Wz.green, [for (final f in up.take(8)) _upRow(c, f)])],
      if (ft.isNotEmpty) ...[const SizedBox(height: 14), _section('Finished', Icons.check_circle_outline_rounded, Wz.muted, [for (final f in ft) FixtureRow(f, compact: Bp.compact(c))])],
    ]);
    final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_mine(c, live), const SizedBox(height: 14), _stats(gw, all, live)]);
    return ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      _header(c, gw, live.length),
      const SizedBox(height: 14),
      wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: main), const SizedBox(width: 16), Expanded(flex: 1, child: side)])
           : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [main, const SizedBox(height: 14), side]),
    ]);
  })));

  Widget _header(BuildContext c, int gw, int liveCount) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LIVE MATCH CENTRE', style: anton(Bp.compact(c) ? 28 : 40, color: Colors.white, spacing: 1)),
      Row(children: [
        Text('Gameweek $gw', style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
        if (liveCount > 0) ...[const SizedBox(width: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Wz.red.withValues(alpha: .15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Wz.red.withValues(alpha: .6))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Wz.red)), const SizedBox(width: 5), Text('$liveCount LIVE', style: const TextStyle(color: Wz.red, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8))]))],
      ]),
    ])),
    OutlinedButton.icon(onPressed: () => c.go('/fixtures?gw=$gw'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), icon: const Icon(Icons.calendar_month_outlined, size: 18), label: Text(Bp.compact(c) ? 'Fixtures' : 'All Fixtures')),
  ]);

  Widget _section(String title, IconData icon, Color col, List<Widget> rows, {Widget? trailing}) => Container(padding: const EdgeInsets.fromLTRB(14, 14, 14, 6), decoration: fixtureBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, color: col, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), if (trailing != null) trailing])),
    ...rows,
  ]));

  Widget _liveSection(BuildContext c, List<Fixture> live) => _section('Live Now', Icons.sensors_rounded, Wz.red, [
    // Two cards per row once the section itself (not the screen) is wide enough.
    LayoutBuilder(builder: (c, box) {
      final cols = box.maxWidth >= 640 ? 2 : 1; final w = (box.maxWidth - 10 * (cols - 1)) / cols;
      return Wrap(spacing: 10, runSpacing: 10, children: [for (final f in live) SizedBox(width: w, child: LiveMatchCard(f))]);
    }),
    const SizedBox(height: 8),
  ], trailing: const Text('auto-refresh 30s', style: TextStyle(color: Wz.muted, fontSize: 11)));

  /// Nothing live: next kick-off with a countdown, or "gameweek complete".
  Widget _quiet(BuildContext c, int gw, List<Fixture> up, List<Fixture> all) {
    final next = up.isEmpty ? null : up.first; final d = next == null ? null : kickoffLocal(next);
    String until() { if (d == null) return ''; final diff = d.difference(DateTime.now()); if (diff.isNegative) return 'starting soon'; if (diff.inDays >= 1) return 'in ${diff.inDays}d ${diff.inHours % 24}h'; if (diff.inHours >= 1) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m'; return 'in ${diff.inMinutes}m'; }
    return Container(padding: const EdgeInsets.all(20), decoration: fixtureBox(border: Wz.green.withValues(alpha: .35)), child: Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: Wz.green.withValues(alpha: .1), border: Border.all(color: Wz.green.withValues(alpha: .4))), child: Icon(next == null ? Icons.flag_rounded : Icons.timer_outlined, color: Wz.green, size: 28)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(next == null ? 'Gameweek $gw complete' : 'No matches live right now', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(next == null ? 'All ${all.length} matches have finished. Points are being finalised.' : 'Next kick-off: ${next.home.name} v ${next.away.name} · ${kickoffLabel(next)} (${until()})',
            style: const TextStyle(color: Wz.muted, fontSize: 13, height: 1.4)),
      ])),
      if (next == null && gw < 38) TextButton(onPressed: () => c.go('/fixtures?gw=${gw + 1}'), child: Text('GW ${gw + 1} ›')),
    ]));
  }

  Widget _upRow(BuildContext c, Fixture f) => InkWell(onTap: () => c.push('/match/${f.id}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
    child: Row(children: [
      ClubBadge(f.home, size: 26), const SizedBox(width: 8),
      Expanded(child: Text('${f.home.name}  v  ${f.away.name}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
      const SizedBox(width: 8), ClubBadge(f.away, size: 26), const SizedBox(width: 12),
      Text(kickoffLabel(f), style: const TextStyle(color: Wz.green, fontSize: 12.5, fontWeight: FontWeight.w600)),
    ])));

  /// Squad players whose club is in a live match.
  Widget _mine(BuildContext c, List<Fixture> live) {
    final u = Session.I.user;
    Widget card(Widget body) => Container(padding: const EdgeInsets.all(16), decoration: fixtureBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [Icon(Icons.shield_outlined, color: Wz.green, size: 20), SizedBox(width: 8), Text('Your Players', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]), const SizedBox(height: 10), body]));
    if (u == null) return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Log in to see which of your players are in action.', style: TextStyle(color: Wz.muted, fontSize: 13)), const SizedBox(height: 10), OutlinedButton(onPressed: () => c.go('/login'), child: const Text('Login'))]));
    if (u.fpl == null) return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Connect your FPL team to track your players live.', style: TextStyle(color: Wz.muted, fontSize: 13)), const SizedBox(height: 10), OutlinedButton(onPressed: () => c.go('/connect-fpl'), child: const Text('Connect with FPL'))]));
    if (live.isEmpty) return card(const Text('None of your players are playing right now.', style: TextStyle(color: Wz.muted, fontSize: 13)));
    final clubs = {for (final f in live) f.home.code, for (final f in live) f.away.code};
    return card(Async(load: () => Repo.I.squad(), builder: (c, s, _) {
      final mine = jListOf(s['picks'], Player.fromJson).where((p) => clubs.contains(p.club.code)).toList()..sort((a, b) => a.slot.compareTo(b.slot));
      if (mine.isEmpty) return const Text('None of your players are in the live matches.', style: TextStyle(color: Wz.muted, fontSize: 13));
      return Column(children: [for (final p in mine) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Container(width: 4, height: 30, color: Wz.hex(p.club.color)), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.bench ? Wz.muted : Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))), if (p.c) const Padding(padding: EdgeInsets.only(left: 6), child: Text('C', style: TextStyle(color: Wz.gold, fontSize: 11.5, fontWeight: FontWeight.w800)))]),
          Text('${p.pos} · ${p.club.code}${p.bench ? ' · bench' : ''}', style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
        ])),
        if (p.gwPts != null) Text('${p.gwPts}', style: const TextStyle(color: Wz.green, fontSize: 16, fontWeight: FontWeight.w700)),
      ]))]);
    }));
  }

  Widget _stats(int gw, List<Fixture> all, List<Fixture> live) {
    final played = all.where((f) => f.status != 'up').toList();
    final goals = played.fold<int>(0, (s, f) => s + (f.hs ?? 0) + (f.as_ ?? 0));
    Widget kv(IconData i, Color col, String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(i, color: col, size: 19), const SizedBox(width: 10), Text(k, style: const TextStyle(color: Wz.muted, fontSize: 13)), const Spacer(), Text(v, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))]));
    return Container(padding: const EdgeInsets.all(16), decoration: fixtureBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('GW $gw AT A GLANCE', style: const TextStyle(color: Wz.green, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)), const SizedBox(height: 4),
      kv(Icons.sensors_rounded, Wz.red, 'Live now', '${live.length}'),
      kv(Icons.check_circle_outline_rounded, Wz.green, 'Finished', '${all.where((f) => f.status == 'ft').length}'),
      kv(Icons.schedule_rounded, Wz.cyan, 'Still to play', '${all.where((f) => f.status == 'up').length}'),
      kv(Icons.sports_score_rounded, Wz.gold, 'Goals so far', '$goals'),
    ]));
  }
}
