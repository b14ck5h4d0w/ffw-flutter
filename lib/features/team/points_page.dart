import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/player.dart';
import '../players/pitch.dart';
import '../players/player_sheet.dart';

/// A13 — Gameweek Points Detail (/points?gw=N).
/// GET /api/app/gameweeks → items[{gw, pts, rank, hits, bench}] (season list, newest first)
/// GET /api/app/gameweeks/<gw>/points → {squad:{picks[] (gw_pts, mult), chip?}}.
/// Pitch in points mode, per-player breakdown (captain multiplier shown), season bars.
class PointsPage extends StatefulWidget { final int? gw; const PointsPage({super.key, this.gw}); @override State<PointsPage> createState() => _PointsState(); }

class _PointsState extends State<PointsPage> {
  int? gw;

  @override Widget build(BuildContext c) {
    if (Session.I.user?.fpl == null) return Scaffold(backgroundColor: Wz.bg, body: _notLinked(c));
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: Repo.I.gameweeks, builder: (c, gws, _) {
      if (gws.isEmpty) return ListView(padding: const EdgeInsets.all(24), children: const [Center(child: Text('No gameweeks played yet.', style: TextStyle(color: Wz.muted)))]);
      final list = [...gws]..sort((a, b) => jInt(a['gw']).compareTo(jInt(b['gw'])));
      final latest = jInt(list.last['gw']), first = jInt(list.first['gw']);
      gw ??= (widget.gw != null && list.any((g) => jInt(g['gw']) == widget.gw)) ? widget.gw : latest;
      final cur = list.firstWhere((g) => jInt(g['gw']) == gw, orElse: () => list.last);
      final wide = MediaQuery.of(c).size.width >= 1100;
      return ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
        _header(c, first, latest),
        const SizedBox(height: 14),
        _stats(c, cur),
        const SizedBox(height: 14),
        Async(key: ValueKey(gw), load: () => Repo.I.gwPoints(gw!), builder: (c, p, _) {
          final sq = jMap(p['squad']);
          final picks = jListOf(sq['picks'], Player.fromJson);
          final main = Container(padding: const EdgeInsets.all(14), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text('Gameweek $gw', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const Spacer(),
              if (jStrN(sq['chip']) != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Wz.purple.withValues(alpha: .2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Wz.purple2)),
                  child: Text('Chip: ${_chip(jStr(sq['chip']))}', style: const TextStyle(color: Wz.purple2, fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 12),
            picks.isEmpty ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No squad data for this gameweek.', style: TextStyle(color: Wz.muted)))) : Pitch(picks: picks, mode: 'points', onTap: (pl) => showPlayerSheet(c, pl)),
          ]));
          final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_breakdown(picks), const SizedBox(height: 14), _season(list)]);
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: main), const SizedBox(width: 16), Expanded(flex: 2, child: side)])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [main, const SizedBox(height: 14), side]);
        }),
      ]);
    })));
  }

  static String _chip(String k) => const {'wildcard': 'Wildcard', 'freehit': 'Free Hit', 'bboost': 'Bench Boost', '3xc': 'Triple Captain'}[k] ?? k;
  static BoxDecoration _box() => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2));
  static int _pts(Player p) => (p.gwPts ?? 0) * (p.mult == 0 ? 1 : p.mult);

  Widget _header(BuildContext c, int first, int latest) {
    final compact = Bp.compact(c);
    Widget nav(IconData i, bool on, int to) => IconButton.filledTonal(onPressed: on ? () => setState(() => gw = to) : null, icon: Icon(i),
        style: IconButton.styleFrom(backgroundColor: Wz.panel2, foregroundColor: Colors.white, disabledBackgroundColor: Wz.panel, disabledForegroundColor: Wz.faint));
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GAMEWEEK POINTS', style: anton(compact ? 28 : 40, color: Colors.white, spacing: 1)),
        Text('Gameweek $gw${gw == latest ? ' · latest' : ''}', style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
      ])),
      nav(Icons.chevron_left_rounded, gw! > first, gw! - 1), const SizedBox(width: 8), nav(Icons.chevron_right_rounded, gw! < latest, gw! + 1),
    ]);
  }

  Widget _stats(BuildContext c, Map<String, dynamic> g) {
    final hits = jInt(g['hits']);
    final items = <(IconData, Color, String, String)>[
      (Icons.bolt_rounded, Wz.green, '${jInt(g['pts'])}', 'Points'),
      if (g['rank'] != null) (Icons.bar_chart_rounded, Wz.cyan, '${g['rank']}'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','), 'GW Rank'),
      (Icons.remove_circle_outline_rounded, hits > 0 ? Wz.red : Wz.muted, hits > 0 ? '-$hits' : '0', 'Transfer Hits'),
      if (g['bench'] != null) (Icons.event_seat_outlined, Wz.gold, '${g['bench']}', 'Bench Points'),
    ];
    final w = Bp.compact(c) ? (MediaQuery.of(c).size.width - 38) / 2 : 200.0;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final (i, it) in items.indexed) Container(width: w, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: i == 0 ? Wz.green.withValues(alpha: .1) : Wz.panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: i == 0 ? Wz.green.withValues(alpha: .5) : Wz.border2)),
        child: Row(children: [
          Icon(it.$1, color: it.$2, size: 26), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.$3, style: TextStyle(color: Colors.white, fontSize: i == 0 ? 24 : 18, fontWeight: FontWeight.w700)),
            Text(it.$4, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5)),
          ])),
        ])),
    ]);
  }

  Widget _breakdown(List<Player> picks) {
    final xi = picks.where((p) => !p.bench).toList()..sort((a, b) => _pts(b).compareTo(_pts(a)));
    final bench = picks.where((p) => p.bench).toList();
    final total = xi.fold<int>(0, (s, p) => s + _pts(p));
    Widget row(Player p, {bool benchRow = false}) => InkWell(onTap: () => showPlayerSheet(context, p), child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      Container(width: 4, height: 26, color: Wz.hex(p.club.color)), const SizedBox(width: 10),
      Expanded(child: Row(children: [
        Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: benchRow ? Wz.muted : Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500))),
        if (p.c) Padding(padding: const EdgeInsets.only(left: 6), child: Text(p.mult == 3 ? 'TC' : 'C', style: const TextStyle(color: Wz.gold, fontSize: 11.5, fontWeight: FontWeight.w800))),
        if (p.v) const Padding(padding: EdgeInsets.only(left: 6), child: Text('V', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w800))),
      ])),
      Text(p.pos, style: const TextStyle(color: Wz.muted, fontSize: 11.5)), const SizedBox(width: 14),
      if (p.mult > 1) Text('${p.gwPts ?? 0}×${p.mult} ', style: const TextStyle(color: Wz.gold, fontSize: 11.5)),
      SizedBox(width: 34, child: Text('${benchRow ? (p.gwPts ?? 0) : _pts(p)}', textAlign: TextAlign.right, style: TextStyle(color: benchRow ? Wz.muted : Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
    ])));
    return Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [const Icon(Icons.format_list_numbered_rounded, color: Wz.green, size: 20), const SizedBox(width: 8), const Text('Points Breakdown', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(),
        Text('$total pts', style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 10),
      for (final p in xi) row(p),
      if (bench.isNotEmpty) ...[const Divider(color: Wz.border2, height: 18), const Text('BENCH (not counted)', style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)), for (final p in bench) row(p, benchRow: true)],
    ]));
  }

  /// Season bars — tap a bar to jump to that gameweek.
  Widget _season(List<Map<String, dynamic>> list) {
    final maxPts = list.fold<int>(1, (m, g) => jInt(g['pts']) > m ? jInt(g['pts']) : m);
    return Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [Icon(Icons.show_chart_rounded, color: Wz.cyan, size: 20), SizedBox(width: 8), Text('Season So Far', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 14),
      SizedBox(height: 130, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final g in list) Expanded(child: Tooltip(message: 'GW ${g['gw']}: ${g['pts']} pts', child: InkWell(onTap: () => setState(() => gw = jInt(g['gw'])), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (jInt(g['gw']) == gw) Text('${g['pts']}', style: const TextStyle(color: Wz.green, fontSize: 10.5, fontWeight: FontWeight.w700)),
          Container(height: 100 * jInt(g['pts']) / maxPts + 2, decoration: BoxDecoration(color: jInt(g['gw']) == gw ? Wz.green : Wz.green.withValues(alpha: .3), borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
          const SizedBox(height: 4),
          Text('${g['gw']}', style: TextStyle(color: jInt(g['gw']) == gw ? Colors.white : Wz.muted, fontSize: 10)),
        ]))))),
      ])),
      const SizedBox(height: 8),
      TextButton(onPressed: () => context.go('/gw-history'), style: TextButton.styleFrom(foregroundColor: Wz.green), child: const Text('Full Gameweek History ›')),
    ]));
  }

  Widget _notLinked(BuildContext c) => Center(child: Container(margin: const EdgeInsets.all(20), constraints: const BoxConstraints(maxWidth: 440), padding: const EdgeInsets.all(24), decoration: _box(),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.bolt_rounded, color: Wz.green, size: 40), const SizedBox(height: 12),
      Text('GAMEWEEK POINTS', style: anton(26, color: Colors.white)), const SizedBox(height: 6),
      const Text('Connect your FPL team to see your gameweek points.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted)), const SizedBox(height: 16),
      FilledButton.icon(onPressed: () => c.go('/connect-fpl'), icon: const Icon(Icons.link_rounded), label: const Text('Connect with FPL')),
    ])));
}
