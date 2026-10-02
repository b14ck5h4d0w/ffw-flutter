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

/// A12 — My Team / Pitch View (/squad).
/// GET /api/app/squad → {picks[], chip, bank, value, hits, bench_pts}. Pitch or list view,
/// captaincy, availability flags (status/chance/news) and a next-3 fixture-difficulty ticker.
class MyTeamPage extends StatefulWidget { const MyTeamPage({super.key}); @override State<MyTeamPage> createState() => _MyTeamState(); }

class _MyTeamState extends State<MyTeamPage> {
  bool list = false;

  static const _posOrder = {'GK': 0, 'DEF': 1, 'MID': 2, 'FWD': 3};
  static const _chipName = {'wildcard': 'Wildcard', 'freehit': 'Free Hit', 'bboost': 'Bench Boost', '3xc': 'Triple Captain'};

  @override Widget build(BuildContext c) {
    final u = Session.I.user;
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: u?.fpl == null ? _notLinked(c) : Async(load: () => Repo.I.squad(), builder: (c, s, reload) {
      final picks = jListOf(s['picks'], Player.fromJson);
      final wide = MediaQuery.of(c).size.width >= 1100;
      return ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
        _header(c, u!.team),
        const SizedBox(height: 14),
        _stats(c, s),
        const SizedBox(height: 14),
        if (picks.isEmpty) _empty()
        else wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: _main(c, picks)), const SizedBox(width: 16), Expanded(flex: 2, child: _side(c, picks))])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_main(c, picks), const SizedBox(height: 14), _side(c, picks)]),
      ]);
    })));
  }

  // ---------- header / stats ----------
  Widget _header(BuildContext c, String team) {
    final compact = Bp.compact(c);
    final actions = [
      FilledButton.icon(onPressed: () => c.go('/transfers'), icon: const Icon(Icons.swap_horiz_rounded, size: 19), label: const Text('Transfers')),
      OutlinedButton.icon(onPressed: () => c.go('/points'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.bolt_outlined, size: 19), label: const Text('Points')),
      OutlinedButton.icon(onPressed: () => c.go('/chips'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.bolt_rounded, size: 19), label: const Text('Chips')),
    ];
    final title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MY TEAM', style: anton(compact ? 30 : 40, color: Colors.white, spacing: 1)),
      if (team.isNotEmpty) Text(team, style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
    ]);
    return compact
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 10), Wrap(spacing: 8, children: actions)])
        : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: title), ...[for (final a in actions) Padding(padding: const EdgeInsets.only(left: 10), child: a)]]);
  }

  Widget _stats(BuildContext c, Map<String, dynamic> s) {
    final chip = jStrN(s['chip']);
    final items = <(IconData, Color, String, String)>[
      if (s['value'] != null) (Icons.payments_outlined, Wz.green, '£${s['value']}m', 'Squad Value'),
      if (s['bank'] != null) (Icons.account_balance_wallet_outlined, Wz.cyan, '£${s['bank']}m', 'In the Bank'),
      (Icons.bolt_rounded, Wz.purple2, chip == null ? 'None' : (_chipName[chip] ?? chip), 'Active Chip'),
      if (s['hits'] != null) (Icons.remove_circle_outline_rounded, Wz.red, jInt(s['hits']) == 0 ? '0' : '-${jInt(s['hits'])}', 'Points Hits'),
      if (s['bench_pts'] != null) (Icons.event_seat_outlined, Wz.gold, '${s['bench_pts']}', 'Bench Points'),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final it in items) Container(width: Bp.compact(c) ? (MediaQuery.of(c).size.width - 38) / 2 : 190, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
        child: Row(children: [
          Icon(it.$1, color: it.$2, size: 24), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            Text(it.$4, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5)),
          ])),
        ])),
    ]);
  }

  // ---------- pitch / list ----------
  Widget _main(BuildContext c, List<Player> picks) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Text('Starting XI', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const Spacer(),
        SegmentedButton<bool>(showSelectedIcon: false, segments: const [ButtonSegment(value: false, icon: Icon(Icons.stadium_outlined, size: 18), label: Text('Pitch')), ButtonSegment(value: true, icon: Icon(Icons.view_list_rounded, size: 18), label: Text('List'))],
          selected: {list}, onSelectionChanged: (v) => setState(() => list = v.first),
          style: ButtonStyle(visualDensity: VisualDensity.compact, backgroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Wz.green.withValues(alpha: .18) : Wz.bg),
              foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Wz.green : Wz.muted), side: const WidgetStatePropertyAll(BorderSide(color: Wz.border2)))),
      ]),
      const SizedBox(height: 12),
      list ? _list(c, picks) : Pitch(picks: picks, mode: 'team', onTap: (p) => showPlayerSheet(c, p)),
    ]));

  Widget _list(BuildContext c, List<Player> picks) {
    final xi = picks.where((p) => !p.bench).toList()..sort((a, b) => (_posOrder[a.pos] ?? 9).compareTo(_posOrder[b.pos] ?? 9));
    final bench = picks.where((p) => p.bench).toList()..sort((a, b) => a.slot.compareTo(b.slot));
    Widget row(Player p) => InkWell(onTap: () => showPlayerSheet(c, p), child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
      SizedBox(width: 40, height: 40, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Container(color: Wz.hex(p.club.color).withValues(alpha: .5),
          child: p.photoUrl == null ? null : Image.network(p.photoUrl!, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => const SizedBox())))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          if (p.c || p.v) Padding(padding: const EdgeInsets.only(left: 6), child: Text(p.c ? 'C' : 'V', style: TextStyle(color: p.c ? Wz.gold : Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
          if (p.status != 'a' && p.status.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.warning_amber_rounded, size: 16, color: p.status == 'd' ? Wz.gold : Wz.red)),
        ]),
        Text('${p.pos} · ${p.club.code} · £${p.price.toStringAsFixed(1)}m', style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
      ])),
      for (final n in p.next.take(3)) Container(width: 46, margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(vertical: 3), decoration: BoxDecoration(color: PlayerCard.fdr(n.fdr).withValues(alpha: .85), borderRadius: BorderRadius.circular(5)),
          child: Text(n.opp, textAlign: TextAlign.center, style: TextStyle(color: n.fdr >= 4 ? Colors.white : Wz.bg, fontSize: 10.5, fontWeight: FontWeight.w700))),
      SizedBox(width: 44, child: Text('${p.pts}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
    ])));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [Spacer(), Text('NEXT 3', style: TextStyle(color: Wz.muted, fontSize: 10.5, fontWeight: FontWeight.w600)), SizedBox(width: 58), Text('PTS', style: TextStyle(color: Wz.muted, fontSize: 10.5, fontWeight: FontWeight.w600))]),
      for (final p in xi) row(p),
      if (bench.isNotEmpty) ...[const Divider(color: Wz.border2, height: 20), const Text('SUBSTITUTES', style: TextStyle(color: Wz.green, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)), for (final p in bench) row(p)],
    ]);
  }

  // ---------- side panels ----------
  Widget _side(BuildContext c, List<Player> picks) {
    final cap = picks.where((p) => p.c).firstOrNull; final vice = picks.where((p) => p.v).firstOrNull;
    final flagged = picks.where((p) => p.status != 'a' && p.status.isNotEmpty).toList();
    final xi = picks.where((p) => !p.bench && p.next.isNotEmpty).toList()..sort((a, b) {
      double avg(Player p) => p.next.take(3).fold<int>(0, (s, n) => s + n.fdr) / p.next.take(3).length;
      return avg(a).compareTo(avg(b));
    });
    Widget card(String title, IconData icon, Color col, Widget body) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Icon(icon, color: col, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]), const SizedBox(height: 12), body]));
    Widget capRow(String label, Player? p, Color col) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: col), child: Text(label, style: const TextStyle(color: Wz.bg, fontWeight: FontWeight.w800))),
      const SizedBox(width: 12),
      Expanded(child: Text(p?.name ?? 'Not set', style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600))),
      if (p != null && p.next.isNotEmpty) Text('${p.next.first.opp} (${p.next.first.ha})', style: const TextStyle(color: Wz.muted, fontSize: 12.5)),
    ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      card('Captaincy', Icons.workspace_premium_rounded, Wz.gold, Column(children: [capRow('C', cap, Wz.gold), capRow('V', vice, Colors.white)])),
      card('Availability', Icons.medical_services_outlined, flagged.isEmpty ? Wz.green : Wz.gold, flagged.isEmpty
          ? const Row(children: [Icon(Icons.check_circle_rounded, color: Wz.green, size: 18), SizedBox(width: 8), Text('All players available.', style: TextStyle(color: Wz.muted))])
          : Column(children: [for (final p in flagged) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: p.status == 'd' ? Wz.gold : Wz.red), const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.name}${p.chance != null ? ' · ${p.chance}%' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                if ((p.news ?? '').isNotEmpty) Text(p.news!, style: const TextStyle(color: Wz.muted, fontSize: 12)),
              ])),
            ]))])),
      if (xi.isNotEmpty) card('Fixture Ticker', Icons.calendar_month_outlined, Wz.cyan, Column(children: [
        for (final p in xi.take(8)) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
          Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13))),
          for (final n in p.next.take(3)) Container(width: 50, margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(vertical: 3), decoration: BoxDecoration(color: PlayerCard.fdr(n.fdr).withValues(alpha: .85), borderRadius: BorderRadius.circular(5)),
              child: Text('${n.opp} ${n.ha}', textAlign: TextAlign.center, style: TextStyle(color: n.fdr >= 4 ? Colors.white : Wz.bg, fontSize: 10.5, fontWeight: FontWeight.w700))),
        ])),
        const SizedBox(height: 4),
        const Text('Easiest runs first. Green = easy, red = hard.', style: TextStyle(color: Wz.muted, fontSize: 11.5)),
      ])),
    ]);
  }

  Widget _empty() => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)),
      child: const Column(children: [Icon(Icons.hourglass_top_rounded, color: Wz.gold, size: 32), SizedBox(height: 10), Text('Your squad is still syncing. Check back in a moment.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted))]));

  Widget _notLinked(BuildContext c) => Center(child: Container(margin: const EdgeInsets.all(20), constraints: const BoxConstraints(maxWidth: 440), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.shield_outlined, color: Wz.green, size: 40), const SizedBox(height: 12),
      Text('MY TEAM', style: anton(28, color: Colors.white)), const SizedBox(height: 6),
      const Text('Connect your FPL team to see your squad on the pitch.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted)), const SizedBox(height: 16),
      FilledButton.icon(onPressed: () => c.go('/connect-fpl'), icon: const Icon(Icons.link_rounded), label: const Text('Connect with FPL')),
    ])));
}
