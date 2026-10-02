import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/player.dart';
import 'pitch.dart';
import 'player_sheet.dart';

/// Players Hub (/players) — GET /api/app/players?pos=&q=&max=&sort=&limit= → items[Player]; watchlist via /watchlist.
/// Tap a row for the quick details (A14); "Full Profile" opens A15.
class PlayersPage extends StatefulWidget { const PlayersPage({super.key}); @override State<PlayersPage> createState() => _PlayersState(); }

class _PlayersState extends State<PlayersPage> {
  final search = TextEditingController(); String? pos; String q = '', sort = 'form'; double? max; bool watch = false; int ver = 0;
  static const _sorts = [('form', 'Form'), ('pts', 'Total Points'), ('price', 'Price'), ('own', 'Selected %')];
  static const _prices = [null, 5.0, 6.0, 7.5, 9.0, 11.0];
  @override void dispose() { search.dispose(); super.dispose(); }
  void _go() => setState(() { q = search.text.trim(); ver++; });

  @override Widget build(BuildContext c) {
    final compact = Bp.compact(c);
    Widget chip(String label, bool on, VoidCallback tap, {Color color = Wz.green}) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), selected: on, showCheckmark: false, onSelected: (_) => tap(), selectedColor: color, labelStyle: TextStyle(color: on ? Wz.bg : Colors.white, fontWeight: FontWeight.w600), backgroundColor: Wz.panel, side: const BorderSide(color: Wz.border2)));
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: compact ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      Text('PLAYERS', style: anton(compact ? 30 : 40, color: Colors.white, spacing: 1)),
      const Text('Search. Filter. Scout.', style: TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      TextField(controller: search, onSubmitted: (_) => _go(), textInputAction: TextInputAction.search, style: const TextStyle(color: Wz.text), decoration: InputDecoration(hintText: 'Search players by name…', prefixIcon: const Icon(Icons.search_rounded, color: Wz.muted),
          suffixIcon: q.isEmpty ? IconButton(onPressed: _go, icon: const Icon(Icons.arrow_forward_rounded, color: Wz.green)) : IconButton(onPressed: () { search.clear(); _go(); }, tooltip: 'Clear', icon: const Icon(Icons.close_rounded, color: Wz.muted)))),
      const SizedBox(height: 12),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (final p in [null, 'GK', 'DEF', 'MID', 'FWD']) chip(p ?? 'All', !watch && pos == p, () => setState(() { watch = false; pos = p; ver++; })),
        if (Session.I.loggedIn) chip('Watchlist', watch, () => setState(() { watch = !watch; ver++; }), color: Wz.red),
      ])),
      if (!watch) ...[
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          const Padding(padding: EdgeInsets.only(right: 10), child: Text('Sort', style: TextStyle(color: Wz.muted, fontSize: 12.5))),
          for (final s in _sorts) chip(s.$2, sort == s.$1, () => setState(() { sort = s.$1; ver++; }), color: Wz.cyan),
          const Padding(padding: EdgeInsets.only(left: 6, right: 10), child: Text('Max price', style: TextStyle(color: Wz.muted, fontSize: 12.5))),
          for (final m in _prices) chip(m == null ? 'Any' : '£${m.toStringAsFixed(1)}m', max == m, () => setState(() { max = m; ver++; }), color: Wz.gold),
        ])),
      ],
      const SizedBox(height: 14),
      Async<List<Player>>(key: ValueKey('$ver'), load: () => watch ? Repo.I.watchlist() : Repo.I.players(pos: pos, q: q, sort: sort, max: max, limit: 80), builder: (c, ps, _) {
        if (ps.isEmpty) return Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)), child: Center(child: Text(watch ? 'Your watchlist is empty. Add players from their profile.' : 'No players match.', style: const TextStyle(color: Wz.muted))));
        return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: ps.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 430, mainAxisExtent: 86, crossAxisSpacing: 10, mainAxisSpacing: 8), itemBuilder: (c, i) { final p = ps[i]; final flag = p.status != 'a' && p.status.isNotEmpty;
          return InkWell(onTap: () => showPlayerSheet(c, p, onTransfer: Session.I.user?.fpl == null ? null : () => c.push('/transfers?in=${p.id}')), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.fromLTRB(10, 8, 12, 8), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)), child: Row(children: [
            Container(width: 54, height: 66, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Wz.hex(p.club.color).withValues(alpha: .8), Wz.bg])),
              child: p.photoUrl == null ? Center(child: Text(p.club.code, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))) : Image.network(p.photoUrl!, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => Center(child: Text(p.club.code, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))))),
            const SizedBox(width: 12),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))), if (flag) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.warning_amber_rounded, size: 15, color: p.status == 'd' ? Wz.gold : Wz.red))]),
              Text('${p.pos} · ${p.club.code} · form ${p.form.toStringAsFixed(1)} · ${p.own.toStringAsFixed(1)}%', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 12)),
              const SizedBox(height: 5),
              Row(children: [for (final n in p.next.take(4)) Container(width: 34, margin: const EdgeInsets.only(right: 3), padding: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(color: PlayerCard.fdr(n.fdr).withValues(alpha: .85), borderRadius: BorderRadius.circular(4)), child: Text(n.opp, textAlign: TextAlign.center, style: TextStyle(color: n.fdr >= 4 ? Colors.white : Wz.bg, fontSize: 9.5, fontWeight: FontWeight.w700)))]),
            ])),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('£${p.price.toStringAsFixed(1)}m', style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w700)),
              Text('${p.pts} pts', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            ]),
          ]))); });
      }),
    ])));
  }
}

/// About / Help (/about).
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override Widget build(BuildContext c) {
    Widget card(IconData i, Color col, String t, String s) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(i, color: col, size: 26), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(s, style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 13.5, height: 1.45))]))]));
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      Text('HELP & ABOUT', style: anton(Bp.compact(c) ? 30 : 40, color: Colors.white, spacing: 1)),
      const Text('More than a game. A battle of minds.', style: TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      card(Icons.sports_soccer_rounded, Wz.green, 'What is FFW?', 'Fantasy Football Warzone runs private-league tournaments for Fantasy Premier League managers. Your official FPL points power four game modes: Ranking, Civil War, Last Survivor and Head-to-Head.'),
      const SizedBox(height: 10),
      card(Icons.link_rounded, Wz.cyan, 'Connecting your FPL team', "In the app you sign in on FPL's own page; your FPL login stays on your phone and is never sent to FFW. On the web, link your team with its public Team ID."),
      const SizedBox(height: 10),
      card(Icons.swap_horiz_rounded, Wz.gold, 'Transfers', 'Plan a draft, review it, then slide to confirm. Nothing is sent to FPL until you confirm. Official transfers are made from the FFW mobile app.'),
      const SizedBox(height: 10),
      card(Icons.info_outline_rounded, Wz.muted, 'Unofficial fan project', 'FFW is not affiliated with, or endorsed by, the Premier League or Fantasy Premier League.'),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        OutlinedButton.icon(onPressed: () => c.go('/modes'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.sports_mma_rounded, size: 18), label: const Text('Game Modes')),
        OutlinedButton(onPressed: () => c.push('/legal/privacy'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), child: const Text('Privacy Policy')),
        OutlinedButton(onPressed: () => c.push('/legal/terms'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), child: const Text('Terms of Service')),
      ]),
    ])));
  }
}
