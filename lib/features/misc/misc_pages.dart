import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/theme.dart';
import '../modes/mode_views.dart' show kModes;

/// Premier League table (/table) — GET /api/app/table → {gw, rows[{pos, club, code, played, won, drawn, lost, gf, ga, gd, pts, form[]}]}.
/// Seasons history (/history) — GET /api/app/history → seasons[{season, leagues[{name, slug, modes[], champion}]}].
/// A31 Hall of Fame · A32 Season Detail (/hof[?league=&season=]) — GET /api/app/hof → {current_season, league, entries[{season, mode, winner, manager, points}]}.

BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
EdgeInsets _pad(BuildContext c) => Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28);
Widget _head(BuildContext c, String title, String sub) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text(title, style: anton(Bp.compact(c) ? 30 : 40, color: Colors.white, spacing: 1)), Text(sub, style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 14)]);
(String, Color) _mode(String k) { final m = kModes[k] ?? kModes[k.replaceAll('_', '-')]; return m == null ? (k, Wz.muted) : (m.name, m.color); }

// ---------- Premier League table ----------
class TablePage extends StatelessWidget {
  const TablePage({super.key});
  static const _th = TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w700);
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: Repo.I.table, builder: (c, j, _) {
    final rows = jList(j['rows']); final wide = !Bp.compact(c);
    Widget n(String t, {double w = 34, TextStyle? s}) => SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: s ?? const TextStyle(color: Colors.white70, fontSize: 13)));
    return ListView(padding: _pad(c), children: [
      _head(c, 'PREMIER LEAGUE', 'Table${j['gw'] != null ? ' · after Gameweek ${j['gw']}' : ''}'),
      Container(padding: const EdgeInsets.fromLTRB(12, 14, 12, 8), decoration: _box(), child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: Row(children: [
          const SizedBox(width: 30, child: Text('#', style: _th)), const Expanded(child: Text('CLUB', style: _th)),
          n('P', s: _th), if (wide) ...[n('W', s: _th), n('D', s: _th), n('L', s: _th), n('GF', s: _th), n('GA', s: _th)], n('GD', w: 40, s: _th),
          if (wide) const SizedBox(width: 118, child: Text('FORM', textAlign: TextAlign.center, style: _th)), n('PTS', w: 44, s: _th),
        ])),
        for (final r in rows) () { final pos = jInt(r['pos']); final zone = pos <= 4 ? Wz.green : pos >= rows.length - 2 ? Wz.red : null;
          return Container(margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: zone ?? Wz.border2, width: 3))),
            child: Row(children: [
              SizedBox(width: 27, child: Text('$pos', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              Expanded(child: Text(wide ? jStr(r['club']) : jStr(r['code'], jStr(r['club'])), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
              n('${r['played'] ?? 0}'), if (wide) ...[n('${r['won'] ?? 0}'), n('${r['drawn'] ?? 0}'), n('${r['lost'] ?? 0}'), n('${r['gf'] ?? 0}'), n('${r['ga'] ?? 0}')],
              n('${jInt(r['gd']) > 0 ? '+' : ''}${jInt(r['gd'])}', w: 40),
              if (wide) SizedBox(width: 118, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final f in (r['form'] as List? ?? const []).take(5)) Container(width: 19, height: 19, margin: const EdgeInsets.symmetric(horizontal: 2), alignment: Alignment.center, decoration: BoxDecoration(color: f == 'W' ? Wz.green : f == 'L' ? Wz.red : Wz.muted, borderRadius: BorderRadius.circular(4)), child: Text('$f', style: const TextStyle(color: Wz.bg, fontSize: 10.5, fontWeight: FontWeight.w800)))])),
              n('${r['pts'] ?? 0}', w: 44, s: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
            ])); }(),
        if (rows.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Table not available yet.', style: TextStyle(color: Wz.muted))),
      ])),
      const SizedBox(height: 10),
      const Row(children: [Icon(Icons.square_rounded, size: 12, color: Wz.green), SizedBox(width: 6), Text('Top four', style: TextStyle(color: Wz.muted, fontSize: 12)), SizedBox(width: 16), Icon(Icons.square_rounded, size: 12, color: Wz.red), SizedBox(width: 6), Text('Bottom three', style: TextStyle(color: Wz.muted, fontSize: 12))]),
    ]);
  })));
}

// ---------- Seasons history ----------
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: Repo.I.history, builder: (c, j, _) {
    final seasons = jList(j['seasons']);
    return ListView(padding: _pad(c), children: [
      _head(c, 'HISTORY', 'Every season. Every champion.'),
      if (seasons.isEmpty) Container(padding: const EdgeInsets.all(28), decoration: _box(), child: const Center(child: Text('No history yet.', style: TextStyle(color: Wz.muted)))),
      for (final s in seasons) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [const Icon(Icons.calendar_month_outlined, color: Wz.gold, size: 20), const SizedBox(width: 8), Text('Season ${s['season']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), TextButton(onPressed: () => c.go('/hof?season=${Uri.encodeQueryComponent(jStr(s['season']))}'), child: const Text('Hall of Fame ›'))]),
        const SizedBox(height: 8),
        for (final l in jList(s['leagues'])) () { final ch = l['champion'] is Map ? jMap(l['champion']) : null;
          return InkWell(onTap: () => c.go('/league/${l['slug']}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(jStr(l['name']), style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)), const SizedBox(height: 5),
              Wrap(spacing: 6, runSpacing: 4, children: [for (final m in (l['modes'] as List? ?? const [])) () { final mm = _mode('$m'); return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: mm.$2.withValues(alpha: .12), borderRadius: BorderRadius.circular(20), border: Border.all(color: mm.$2.withValues(alpha: .5))), child: Text(mm.$1, style: TextStyle(color: mm.$2, fontSize: 11, fontWeight: FontWeight.w600))); }()]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.emoji_events_rounded, size: 16, color: ch == null ? Wz.faint : Wz.gold), const SizedBox(width: 5), Text(ch == null ? 'In progress' : jStr(ch['team'], jStr(ch['name'])), style: TextStyle(color: ch == null ? Wz.muted : Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))]),
              if (ch != null) const Text('Champion', style: TextStyle(color: Wz.muted, fontSize: 11)),
            ]),
            const Icon(Icons.chevron_right_rounded, color: Wz.muted),
          ]))); }(),
      ])),
    ]);
  })));
}

// ---------- Hall of Fame ----------
class HofPage extends StatefulWidget { final String? league, season; const HofPage({super.key, this.league, this.season}); @override State<HofPage> createState() => _HofState(); }
class _HofState extends State<HofPage> {
  late String? season = widget.season;
  static const _gold = Color(0xFFF4BF3A);
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: () => Repo.I.hof(league: widget.league), builder: (c, j, _) {
    final entries = jList(j['entries']); final compact = Bp.compact(c);
    final seasons = <String>{for (final e in entries) jStr(e['season'])}.where((s) => s.isNotEmpty).toList()..sort((a, b) => b.compareTo(a));
    final sel = season != null && seasons.contains(season) ? season : null;
    final shown = sel == null ? entries : entries.where((e) => jStr(e['season']) == sel).toList();
    final titles = <String, int>{}; for (final e in entries) { final w = jStr(e['winner']); if (w.isNotEmpty) titles[w] = (titles[w] ?? 0) + 1; }
    final legends = titles.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final league = jStrN(j['league'] is Map ? jMap(j['league'])['name'] : j['league']);
    return ListView(padding: _pad(c), children: [
      Container(height: compact ? null : 240, clipBehavior: Clip.antiAlias, decoration: _box(border: _gold.withValues(alpha: .5)), child: Stack(children: [
        Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .4)], stops: const [.35, 1])))),
        if (!compact) Positioned(right: 200, top: 6, bottom: -210, child: Image.asset(WzAssets.player10, fit: BoxFit.fitHeight, alignment: Alignment.topCenter)),
        if (!compact) Positioned(right: 22, top: 30, child: Transform.rotate(angle: -.14, child: Column(children: [const FfwCrown(size: 30), Text('Different players.\nA bigger legacy.', textAlign: TextAlign.center, style: script(28))]))),
        Padding(padding: EdgeInsets.all(compact ? 18 : 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          ShaderMask(blendMode: BlendMode.srcIn, shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE9A6), _gold, Color(0xFFB07A12)]).createShader(r), child: Text('HALL OF FAME', style: anton(compact ? 36 : 56, color: Colors.white, spacing: 1.5))),
          Text(league == null ? 'CHAMPIONS. LEGENDS. A LASTING LEGACY.' : league.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2.2)),
          const SizedBox(height: 10),
          Text('The greatest managers. The strongest clans. The stories that live forever.', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 14)),
        ])),
      ])),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _stat(c, Icons.calendar_month_outlined, '${seasons.length}', 'Seasons Recorded'), _stat(c, Icons.emoji_events_rounded, '${entries.length}', 'Titles Awarded'),
        _stat(c, Icons.workspace_premium_rounded, '${titles.length}', 'Different Champions'), if (jStr(j['current_season']).isNotEmpty) _stat(c, Icons.bolt_rounded, jStr(j['current_season']), 'Current Season'),
      ]),
      const SizedBox(height: 14),
      if (entries.isEmpty) Container(padding: const EdgeInsets.all(32), decoration: _box(), child: Column(children: [
        const Icon(Icons.emoji_events_outlined, color: _gold, size: 46), const SizedBox(height: 12),
        const Text('The first champions are still being decided', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 6),
        Text('Winners are added here when a season${jStr(j['current_season']).isNotEmpty ? ' (${j['current_season']})' : ''} is complete.', textAlign: TextAlign.center, style: const TextStyle(color: Wz.muted)),
      ]))
      else ...[
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final s in <String?>[null, ...seasons]) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(selected: sel == s, onSelected: (_) => setState(() => season = s), showCheckmark: false, label: Text(s == null ? 'All Seasons' : 'Season $s'),
            labelStyle: TextStyle(color: sel == s ? Wz.bg : Colors.white, fontWeight: FontWeight.w600), selectedColor: _gold, backgroundColor: Wz.panel, side: const BorderSide(color: Wz.border2)))])),
        const SizedBox(height: 14),
        () {
          final champs = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [const Icon(Icons.emoji_events_rounded, color: _gold, size: 20), const SizedBox(width: 8), Text(sel == null ? 'Champions' : 'Season $sel Champions', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]), const SizedBox(height: 12),
            GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: shown.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, mainAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10), itemBuilder: (c, i) { final h = shown[i]; final m = _mode(jStr(h['mode']));
              return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _gold.withValues(alpha: .55)), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_gold.withValues(alpha: .2), Wz.panel])),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text('SEASON ${h['season']}', style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: m.$2.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)), child: Text(m.$1, style: TextStyle(color: m.$2, fontSize: 10.5, fontWeight: FontWeight.w700)))]),
                  const Spacer(),
                  Row(children: [const Icon(Icons.emoji_events_rounded, color: _gold, size: 28), const SizedBox(width: 10), Expanded(child: Text(jStr(h['winner']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)))]),
                  const SizedBox(height: 4),
                  Text([if (jStr(h['manager']).isNotEmpty) jStr(h['manager']), if (h['points'] != null) '${h['points']} pts'].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 12.5)),
                ])); }),
          ]));
          final legendsBox = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Row(children: [Icon(Icons.workspace_premium_rounded, color: _gold, size: 20), SizedBox(width: 8), Text('Most Titles', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]), const SizedBox(height: 10),
            for (final (i, e) in legends.take(8).indexed) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
              SizedBox(width: 28, child: Text('${i + 1}', style: TextStyle(color: i == 0 ? _gold : Wz.muted, fontWeight: FontWeight.w700))),
              Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14))),
              Text('${e.value} title${e.value == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            ])),
          ]));
          return MediaQuery.of(c).size.width >= 1100 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: champs), const SizedBox(width: 16), Expanded(flex: 1, child: legendsBox)])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [champs, const SizedBox(height: 14), legendsBox]);
        }(),
      ],
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(18), decoration: _box(border: _gold.withValues(alpha: .35)), child: Row(children: [const FfwCrown(size: 36), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('LEGACY LIVES FOREVER', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2)), const SizedBox(height: 4),
        Text('Greatness is not a single season, but a legacy of many.', style: script(22))]))])),
    ]);
  })));

  Widget _stat(BuildContext c, IconData i, String v, String k) => Container(width: Bp.compact(c) ? (MediaQuery.of(c).size.width - 38) / 2 : 210, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: _box(),
      child: Row(children: [Icon(i, color: _gold, size: 26), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)), Text(k, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5))]))]));
}
