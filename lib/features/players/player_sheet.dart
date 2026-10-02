import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/player.dart';

/// A14 — Player Details quick view. Bottom sheet on phones, centred dialog on wide screens.
/// Everything shown comes from the [Player] already loaded by the caller (no extra request);
/// "Full Profile" opens A15 (/players/:id). [onTransfer]/[onRemove] are used by the transfer planner.
void showPlayerSheet(BuildContext c, Player p, {VoidCallback? onTransfer, VoidCallback? onRemove}) {
  final body = _PlayerDetails(p, onTransfer: onTransfer, onRemove: onRemove);
  if (MediaQuery.of(c).size.width >= 700) {
    showDialog(context: c, builder: (_) => Dialog(backgroundColor: Wz.panel, insetPadding: const EdgeInsets.all(24), clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Wz.green.withValues(alpha: .35))),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: SingleChildScrollView(child: body))));
  } else {
    showModalBottomSheet(context: c, isScrollControlled: true, backgroundColor: Wz.panel, clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        builder: (s) => ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(s).size.height * .9), child: SingleChildScrollView(child: body)));
  }
}

class _PlayerDetails extends StatelessWidget {
  final Player p; final VoidCallback? onTransfer, onRemove;
  const _PlayerDetails(this.p, {this.onTransfer, this.onRemove});

  static const _posName = {'GK': 'Goalkeeper', 'DEF': 'Defender', 'MID': 'Midfielder', 'FWD': 'Forward'};
  static Color _fdr(int d) => d <= 2 ? Wz.green : d == 3 ? const Color(0xFFCFD8D2) : d == 4 ? Wz.red : const Color(0xFF9B1030);
  static String _k(int n) => n >= 1000000 ? '${(n / 1000000).toStringAsFixed(1)}M' : n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K' : '$n';

  void _close(BuildContext c) => Navigator.of(c).pop();

  @override Widget build(BuildContext c) {
    final col = Wz.hex(p.club.color);
    final flagged = p.status != 'a' && p.status.isNotEmpty;
    final stats = <(String, String)>[
      ('Total Pts', '${p.pts}'), ('Form', p.form.toStringAsFixed(1)), ('Selected', '${p.own.toStringAsFixed(1)}%'),
      if (p.gwPts != null) ('GW Pts', '${p.gwPts}'),
      ('Goals', '${p.goals}'), ('Assists', '${p.assists}'), ('Bonus', '${p.bonus}'), ('Minutes', _k(p.minutes)),
      ('xG', p.xg.toStringAsFixed(2)), ('xA', p.xa.toStringAsFixed(2)),
    ];
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ---- hero ----
      Container(height: 170, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [col.withValues(alpha: .9), Color.lerp(col, Wz.bg, .8)!])), child: Stack(children: [
        Positioned(right: -60, top: -80, child: Container(width: 240, height: 240, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .07)))),
        Positioned(left: 8, bottom: 0, width: 150, height: 160, child: p.photoUrl == null ? _crest()
            : Image.network(p.photoUrl!, fit: BoxFit.contain, alignment: Alignment.bottomCenter, errorBuilder: (_, __, ___) => _crest())),
        Positioned(left: 170, right: 44, top: 20, bottom: 14, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_posName[p.pos] ?? p.pos} · ${p.club.name.isEmpty ? p.club.code : p.club.name}'.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(p.name.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: anton(30, color: Colors.white, spacing: .6)),
          const Spacer(),
          Row(children: [
            _chip('£${p.price.toStringAsFixed(1)}m', Wz.bg),
            if (p.change != 0) ...[const SizedBox(width: 6), Icon(p.change > 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: p.change > 0 ? Wz.green : Wz.red),
              Text('£${p.change.abs().toStringAsFixed(1)}m', style: TextStyle(color: p.change > 0 ? Wz.green : Wz.red, fontSize: 12, fontWeight: FontWeight.w600))],
            if (p.sell != null) ...[const SizedBox(width: 10), Text('Sell £${p.sell!.toStringAsFixed(1)}m', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12))],
          ]),
        ])),
        Positioned(right: 4, top: 4, child: IconButton(onPressed: () => _close(c), tooltip: 'Close', icon: const Icon(Icons.close_rounded, color: Colors.white))),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (flagged || (p.news ?? '').isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: (p.status == 'd' ? Wz.gold : Wz.red).withValues(alpha: .12), borderRadius: BorderRadius.circular(8), border: Border.all(color: (p.status == 'd' ? Wz.gold : Wz.red).withValues(alpha: .5))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, color: p.status == 'd' ? Wz.gold : Wz.red, size: 20), const SizedBox(width: 10),
            // FPL news usually already states the chance ("Knock - 75% chance of playing").
            Expanded(child: Text([if ((p.news ?? '').isNotEmpty) p.news!, if (p.chance != null && !(p.news ?? '').contains('%')) '${p.chance}% chance of playing'].join(' · ').ifEmpty('Availability doubt'), style: const TextStyle(color: Wz.text, fontSize: 13, height: 1.35))),
          ])),
        // ---- stats ----
        GridView.count(crossAxisCount: 5, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.15, children: [
          for (final (i, s) in stats.indexed) Container(decoration: BoxDecoration(color: i == 0 ? Wz.green.withValues(alpha: .12) : Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(8), border: Border.all(color: i == 0 ? Wz.green.withValues(alpha: .5) : Wz.border2)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              FittedBox(child: Text(s.$2, style: TextStyle(color: i == 0 ? Wz.green : Colors.white, fontSize: 17, fontWeight: FontWeight.w700))),
              const SizedBox(height: 2),
              Text(s.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 10.5)),
            ])),
        ]),
        if (p.tin > 0 || p.tout > 0) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _flow(Icons.login_rounded, Wz.green, 'Transfers in', _k(p.tin))),
            const SizedBox(width: 8),
            Expanded(child: _flow(Icons.logout_rounded, Wz.red, 'Transfers out', _k(p.tout))),
          ]),
        ],
        // ---- fixtures ----
        if (p.next.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('NEXT FIXTURES', style: TextStyle(color: Wz.green, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(children: [for (final n in p.next.take(5)) Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(color: _fdr(n.fdr), borderRadius: BorderRadius.circular(7)),
            child: Column(children: [
              Text('GW${n.gw}', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: n.fdr >= 4 ? Colors.white70 : Colors.black87)),
              Text('${n.opp} (${n.ha})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: n.fdr >= 4 ? Colors.white : Colors.black)),
            ])))]),
        ],
        // ---- actions ----
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () { _close(c); c.push('/players/${p.id}'); }, icon: const Icon(Icons.person_search_rounded, size: 18), label: const Text('Full Profile'),
              style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green), minimumSize: const Size.fromHeight(46)))),
          if (onTransfer != null) ...[const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () { _close(c); onTransfer!(); }, icon: const Icon(Icons.swap_horiz_rounded, size: 18), label: const Text('Transfer'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46))))],
          if (onRemove != null) ...[const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () { _close(c); onRemove!(); }, icon: const Icon(Icons.close_rounded, size: 18), label: const Text('Remove'),
              style: OutlinedButton.styleFrom(foregroundColor: Wz.red, side: BorderSide(color: Wz.red.withValues(alpha: .6)), minimumSize: const Size.fromHeight(46))))],
        ]),
      ])),
    ]);
  }

  Widget _crest() => Center(child: Text(p.club.code, style: anton(52, color: Colors.white.withValues(alpha: .35), spacing: 2)));
  Widget _chip(String t, Color bg) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg.withValues(alpha: .7), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)));
  Widget _flow(IconData i, Color col, String label, String v) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(8), border: Border.all(color: Wz.border2)),
      child: Row(children: [Icon(i, color: col, size: 18), const SizedBox(width: 8), Expanded(child: Text(label, style: const TextStyle(color: Wz.muted, fontSize: 12))), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]));
}

extension on String { String ifEmpty(String alt) => isEmpty ? alt : this; }
