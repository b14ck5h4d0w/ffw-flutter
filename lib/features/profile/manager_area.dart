import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';

/// My FPL tools: Chips (/chips), Points Hits (/hits), Gameweek History (/gw-history).
/// GET /api/app/chips → items[{name, total, remaining, used[], available, active}]
/// GET /api/app/hits → {total, gws[{gw, transfers, cost}]}
/// GET /api/app/gameweeks → items[{gw, pts, rank, hits, bench}]

BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
String _num(dynamic v) { final n = jIntN(v); return n == null ? '—' : '$n'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','); }

Widget _page(BuildContext c, {required String title, required String sub, required Widget Function(BuildContext) body}) {
  final head = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    InkWell(onTap: () => c.canPop() ? c.pop() : c.go('/squad'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70), SizedBox(width: 6), Text('My Team', style: TextStyle(color: Colors.white70, fontSize: 13))])),
    const SizedBox(height: 8), Text(title, style: anton(Bp.compact(c) ? 30 : 40, color: Colors.white, spacing: 1)), Text(sub, style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 14)]);
  return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
    head,
    Session.I.user?.fpl == null ? Container(padding: const EdgeInsets.all(26), decoration: _box(), child: Column(children: [const Icon(Icons.link_rounded, color: Wz.green, size: 36), const SizedBox(height: 10), const Text('Connect your FPL team to see this.', style: TextStyle(color: Wz.muted)), const SizedBox(height: 14), FilledButton(onPressed: () => c.go('/connect-fpl'), child: const Text('Connect with FPL'))])) : body(c),
  ])));
}

class ChipsPage extends StatelessWidget {
  const ChipsPage({super.key});
  static const _meta = {
    'wildcard': ('Wildcard', Icons.bolt_rounded, Wz.green, 'Unlimited free transfers for one gameweek. Changes are permanent.'),
    'freehit': ('Free Hit', Icons.checkroom_rounded, Wz.purple2, 'Unlimited transfers for one gameweek; your squad then returns to how it was.'),
    'bboost': ('Bench Boost', Icons.groups_rounded, Wz.cyan, 'Points from your bench players count for one gameweek.'),
    '3xc': ('Triple Captain', Icons.star_rounded, Wz.gold, 'Your captain scores triple instead of double for one gameweek.'),
  };
  @override Widget build(BuildContext c) => _page(c, title: 'CHIPS', sub: 'Your game-changers for the season.', body: (c) => Async(load: Repo.I.chips, builder: (c, items, _) => items.isEmpty
    ? Container(padding: const EdgeInsets.all(26), decoration: _box(), child: const Center(child: Text('No chip data yet.', style: TextStyle(color: Wz.muted))))
    : GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 440, mainAxisExtent: 172, crossAxisSpacing: 12, mainAxisSpacing: 12), itemBuilder: (c, i) {
        final ch = items[i]; final m = _meta[jStr(ch['name'])] ?? (jStr(ch['name']), Icons.bolt_rounded, Wz.green, '');
        final active = jBool(ch['active']), avail = jBool(ch['available']); final used = (ch['used'] as List? ?? const []);
        final st = active ? ('ACTIVE', Wz.gold) : avail ? ('AVAILABLE', Wz.green) : ('USED', Wz.muted);
        return Container(padding: const EdgeInsets.all(16), decoration: _box(border: avail || active ? m.$3.withValues(alpha: .5) : null), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: m.$3.withValues(alpha: avail || active ? .2 : .06), borderRadius: BorderRadius.circular(10)), child: Icon(m.$2, color: avail || active ? m.$3 : Wz.faint, size: 26)), const SizedBox(width: 12),
            Expanded(child: Text(m.$1, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: st.$2.withValues(alpha: .14), borderRadius: BorderRadius.circular(20), border: Border.all(color: st.$2.withValues(alpha: .6))), child: Text(st.$1, style: TextStyle(color: st.$2, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .8)))]),
          const SizedBox(height: 10),
          Expanded(child: Text(m.$4, style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 13, height: 1.4))),
          Text([if (ch['remaining'] != null && ch['total'] != null) '${ch['remaining']} of ${ch['total']} left', if (used.isNotEmpty) 'used in GW ${used.join(', ')}'].join(' · '), style: const TextStyle(color: Wz.muted, fontSize: 12.5)),
        ]));
      })));
}

class HitsPage extends StatelessWidget {
  const HitsPage({super.key});
  @override Widget build(BuildContext c) => _page(c, title: 'POINTS HITS', sub: 'What extra transfers have cost you.', body: (c) => Async(load: Repo.I.hits, builder: (c, j, _) {
    final gws = jList(j['gws']); final hit = gws.where((g) => jInt(g['cost']) > 0).toList(); final total = jInt(j['total']);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        _tile(c, Icons.remove_circle_outline_rounded, total > 0 ? Wz.red : Wz.green, total > 0 ? '-$total' : '0', 'Total Points Lost'),
        _tile(c, Icons.event_busy_outlined, Wz.gold, '${hit.length}', 'Gameweeks With a Hit'),
        _tile(c, Icons.swap_horiz_rounded, Wz.cyan, '${gws.fold<int>(0, (s, g) => s + jInt(g['transfers']))}', 'Transfers Made'),
      ]),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('By Gameweek', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 10),
        if (hit.isEmpty) const Padding(padding: EdgeInsets.all(14), child: Row(children: [Icon(Icons.check_circle_rounded, color: Wz.green), SizedBox(width: 10), Text('No points hits taken. Disciplined.', style: TextStyle(color: Wz.muted))])),
        for (final g in hit) Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))), child: Row(children: [
          SizedBox(width: 120, child: Text('Gameweek ${g['gw']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))), Expanded(child: Text('${g['transfers']} transfer${jInt(g['transfers']) == 1 ? '' : 's'}', style: const TextStyle(color: Wz.muted, fontSize: 13))),
          Text('-${g['cost']} pts', style: const TextStyle(color: Wz.red, fontSize: 15, fontWeight: FontWeight.w700))])),
      ])),
    ]);
  }));
}

class GwHistoryPage extends StatelessWidget {
  const GwHistoryPage({super.key});
  static const _th = TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w700);
  @override Widget build(BuildContext c) => _page(c, title: 'GAMEWEEK HISTORY', sub: 'Your season, week by week.', body: (c) => Async(load: Repo.I.gameweeks, builder: (c, gws, _) {
    if (gws.isEmpty) return Container(padding: const EdgeInsets.all(26), decoration: _box(), child: const Center(child: Text('No gameweeks played yet.', style: TextStyle(color: Wz.muted))));
    final list = [...gws]..sort((a, b) => jInt(b['gw']).compareTo(jInt(a['gw'])));
    final total = list.fold<int>(0, (s, g) => s + jInt(g['pts'])); final best = list.reduce((a, b) => jInt(a['pts']) >= jInt(b['pts']) ? a : b);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        _tile(c, Icons.emoji_events_rounded, Wz.gold, _num(total), 'Points So Far'), _tile(c, Icons.functions_rounded, Wz.cyan, (total / list.length).toStringAsFixed(1), 'Average per GW'),
        _tile(c, Icons.local_fire_department_rounded, Wz.green, '${best['pts']}', 'Best · GW ${best['gw']}'),
      ]),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), decoration: _box(), child: Column(children: [
        const Padding(padding: EdgeInsets.only(bottom: 8), child: Row(children: [SizedBox(width: 60, child: Text('GW', style: _th)), Expanded(child: Text('GW RANK', style: _th)), SizedBox(width: 60, child: Text('HITS', textAlign: TextAlign.right, style: _th)), SizedBox(width: 60, child: Text('BENCH', textAlign: TextAlign.right, style: _th)), SizedBox(width: 60, child: Text('PTS', textAlign: TextAlign.right, style: _th))])),
        for (final g in list) InkWell(onTap: () => c.go('/points?gw=${g['gw']}'), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Wz.border))), child: Row(children: [
          SizedBox(width: 60, child: Text('${g['gw']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))), Expanded(child: Text(_num(g['rank']), style: const TextStyle(color: Colors.white70))),
          SizedBox(width: 60, child: Text(jInt(g['hits']) > 0 ? '-${g['hits']}' : '0', textAlign: TextAlign.right, style: TextStyle(color: jInt(g['hits']) > 0 ? Wz.red : Colors.white70))),
          SizedBox(width: 60, child: Text('${g['bench'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70))),
          SizedBox(width: 60, child: Text('${g['pts'] ?? 0}', textAlign: TextAlign.right, style: TextStyle(color: g == best ? Wz.gold : Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700))),
        ]))),
      ])),
    ]);
  }));
}

Widget _tile(BuildContext c, IconData i, Color col, String v, String k) => Container(width: Bp.compact(c) ? (MediaQuery.of(c).size.width - 38) / 2 : 220, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: _box(),
    child: Row(children: [Icon(i, color: col, size: 26), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)), Text(k, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5))]))]));
