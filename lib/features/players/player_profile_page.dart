import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/player.dart';
import 'pitch.dart';

/// A15 — Player Full Profile / Stats (/players/:id).
/// GET /api/app/players/<id> → Player fields + first_name, second_name, fixtures[5], history[{gw,opp,ha,minutes,pts}],
/// in_my_team, watchlisted, shots, shots_on_target (may be null).
class PlayerProfilePage extends StatelessWidget {
  final int id; const PlayerProfilePage(this.id, {super.key});

  static String _k(int n) => n >= 1000000 ? '${(n / 1000000).toStringAsFixed(1)}M' : n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K' : '$n';
  static BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
  static const _posName = {'GK': 'Goalkeeper', 'DEF': 'Defender', 'MID': 'Midfielder', 'FWD': 'Forward'};

  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: () => Repo.I.player(id), builder: (c, j, reload) {
    final p = Player.fromJson(j);
    final hist = jList(j['history']);
    final fixtures = jList(j['fixtures']).isNotEmpty ? jList(j['fixtures']).map(NextFixture.fromJson).toList() : p.next;
    final wide = MediaQuery.of(c).size.width >= 1100;
    final left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_history(hist), const SizedBox(height: 14), _statsCard(p, j)]);
    final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_fixtures(fixtures), const SizedBox(height: 14), _market(p)]);
    return ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 10, 14, 24) : const EdgeInsets.fromLTRB(24, 18, 24, 28), children: [
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => c.canPop() ? c.pop() : c.go('/players'), style: TextButton.styleFrom(foregroundColor: Colors.white70),
          icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('Players'))),
      const SizedBox(height: 6),
      _hero(c, p, j, reload),
      if ((p.news ?? '').isNotEmpty || (p.status != 'a' && p.status.isNotEmpty)) ...[const SizedBox(height: 14), _news(p)],
      const SizedBox(height: 14),
      wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: left), const SizedBox(width: 16), Expanded(flex: 2, child: right)])
           : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 14), right]),
    ]);
  })));

  // ---------- hero ----------
  Widget _hero(BuildContext c, Player p, Map<String, dynamic> j, Future<void> Function() reload) {
    final col = Wz.hex(p.club.color);
    final compact = Bp.compact(c);
    final first = jStr(j['first_name']); final last = jStr(j['second_name'], p.name);
    final watch = jBool(j['watchlisted']); final mine = jBool(j['in_my_team']);
    final stats = <(String, String)>[
      ('Season Pts', '${p.pts}'), ('Form', p.form.toStringAsFixed(1)), ('Price', '£${p.price.toStringAsFixed(1)}m'),
      ('Selected', '${p.own.toStringAsFixed(1)}%'), ('Pts / £m', p.price > 0 ? (p.pts / p.price).toStringAsFixed(1) : '—'),
    ];
    return Container(clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: col.withValues(alpha: .6)),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [col.withValues(alpha: .85), Color.lerp(col, Wz.bg, .82)!, Wz.bg])),
      child: Stack(children: [
        Positioned(right: -80, top: -120, child: Container(width: 360, height: 360, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)))),
        Positioned(right: compact ? -20 : 40, bottom: 0, height: compact ? 170 : 250, width: compact ? 150 : 240, child: p.photoUrl == null ? const SizedBox()
            : Image.network(p.photoUrl!, fit: BoxFit.contain, alignment: Alignment.bottomCenter, errorBuilder: (_, __, ___) => const SizedBox())),
        Padding(padding: EdgeInsets.fromLTRB(compact ? 18 : 28, compact ? 18 : 26, compact ? 130 : 300, compact ? 18 : 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_posName[p.pos] ?? p.pos} · ${p.club.name}'.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.3)),
          const SizedBox(height: 6),
          if (first.isNotEmpty && first != last) Text(first, style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: compact ? 16 : 20)),
          Text(last.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: anton(compact ? 36 : 56, color: Colors.white, spacing: 1)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (mine) _pill(Icons.shield_rounded, 'In your team', Wz.green),
            if (p.change != 0) _pill(p.change > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, '${p.change > 0 ? '+' : '-'}£${p.change.abs().toStringAsFixed(1)}m this GW', p.change > 0 ? Wz.green : Wz.red),
          ]),
          SizedBox(height: compact ? 14 : 20),
          Wrap(spacing: compact ? 18 : 28, runSpacing: 10, children: [for (final s in stats) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.$2, style: TextStyle(color: Colors.white, fontSize: compact ? 20 : 26, fontWeight: FontWeight.w700)),
            Text(s.$1.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 10.5, letterSpacing: 1)),
          ])]),
          const SizedBox(height: 18),
          if (Session.I.loggedIn) Wrap(spacing: 10, runSpacing: 10, children: [
            if (!mine) FilledButton.icon(onPressed: () => c.push('/transfers?in=${p.id}'), icon: const Icon(Icons.swap_horiz_rounded, size: 19), label: const Text('Transfer In')),
            OutlinedButton.icon(onPressed: () async { try { await Repo.I.watch(p.id, !watch); await reload(); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); } },
                style: OutlinedButton.styleFrom(foregroundColor: watch ? Wz.red : Colors.white, side: BorderSide(color: watch ? Wz.red : Colors.white54)),
                icon: Icon(watch ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 19), label: Text(watch ? 'On Watchlist' : 'Add to Watchlist')),
          ]),
        ])),
      ]));
  }

  Widget _pill(IconData i, String t, Color col) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withValues(alpha: .7))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 15, color: col), const SizedBox(width: 6), Text(t, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w600))]));

  Widget _news(Player p) {
    final col = p.status == 'd' ? Wz.gold : Wz.red;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: col.withValues(alpha: .1), borderRadius: BorderRadius.circular(10), border: Border.all(color: col.withValues(alpha: .5))),
      child: Row(children: [Icon(Icons.warning_amber_rounded, color: col), const SizedBox(width: 12),
        Expanded(child: Text((p.news ?? '').isNotEmpty ? p.news! : 'Availability doubt${p.chance != null ? ' · ${p.chance}% chance of playing' : ''}', style: const TextStyle(color: Wz.text, fontSize: 14)))]));
  }

  Widget _title(IconData i, Color col, String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(i, color: col, size: 20), const SizedBox(width: 8), Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]));

  // ---------- gameweek history ----------
  Widget _history(List<Map<String, dynamic>> hist) {
    final maxPts = hist.fold<int>(1, (m, h) => jInt(h['pts']) > m ? jInt(h['pts']) : m);
    return Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.show_chart_rounded, Wz.cyan, 'Gameweek History'),
      if (hist.isEmpty) const Text('No gameweeks played yet.', style: TextStyle(color: Wz.muted))
      else ...[
        SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final h in hist) Expanded(child: Tooltip(message: 'GW ${h['gw']} v ${h['opp']} (${h['ha']}): ${h['pts']} pts', child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('${h['pts']}', style: TextStyle(color: jInt(h['pts']) >= 10 ? Wz.gold : Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Container(height: 100 * jInt(h['pts']).clamp(0, 999) / maxPts + 3, decoration: BoxDecoration(color: jInt(h['pts']) >= 10 ? Wz.gold : Wz.green.withValues(alpha: .75), borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
            const SizedBox(height: 4),
            Text('${h['gw']}', style: const TextStyle(color: Wz.muted, fontSize: 10.5)),
          ])))),
        ])),
        const SizedBox(height: 12),
        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Row(children: [
          SizedBox(width: 44, child: Text('GW', style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(child: Text('OPPONENT', style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 60, child: Text('MINS', textAlign: TextAlign.right, style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 50, child: Text('PTS', textAlign: TextAlign.right, style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w600))),
        ])),
        for (final h in hist.reversed) Container(padding: const EdgeInsets.symmetric(vertical: 7), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Wz.border))), child: Row(children: [
          SizedBox(width: 44, child: Text('${h['gw']}', style: const TextStyle(color: Colors.white70))),
          Expanded(child: Text('${h['opp'] ?? ''} (${h['ha'] ?? ''})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          SizedBox(width: 60, child: Text(h['minutes'] == null ? '—' : "${h['minutes']}'", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70))),
          SizedBox(width: 50, child: Text('${h['pts']}', textAlign: TextAlign.right, style: TextStyle(color: jInt(h['pts']) >= 10 ? Wz.gold : Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
        ])),
      ],
    ]));
  }

  // ---------- season stats ----------
  Widget _statsCard(Player p, Map<String, dynamic> j) {
    final items = <(String, String)>[
      ('Minutes', _k(p.minutes)), ('Goals', '${p.goals}'), ('Assists', '${p.assists}'), ('Bonus', '${p.bonus}'),
      ('xG', p.xg.toStringAsFixed(2)), ('xA', p.xa.toStringAsFixed(2)),
      if (j['shots'] != null) ('Shots', '${j['shots']}'), if (j['shots_on_target'] != null) ('On Target', '${j['shots_on_target']}'),
      if (p.minutes > 0) ('Pts / 90', (p.pts / p.minutes * 90).toStringAsFixed(1)),
    ];
    return Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.insights_rounded, Wz.green, 'Season Stats'),
      GridView.extent(maxCrossAxisExtent: 130, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.55, children: [
        for (final s in items) Container(decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(8), border: Border.all(color: Wz.border2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [FittedBox(child: Text(s.$2, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))), Text(s.$1, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 11))])),
      ]),
    ]));
  }

  // ---------- fixtures / market ----------
  Widget _fixtures(List<NextFixture> fx) => Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _title(Icons.calendar_month_outlined, Wz.gold, 'Upcoming Fixtures'),
    if (fx.isEmpty) const Text('No upcoming fixtures.', style: TextStyle(color: Wz.muted))
    else for (final n in fx) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(8), border: Border.all(color: Wz.border2)),
      child: Row(children: [
        SizedBox(width: 48, child: Text('GW ${n.gw}', style: const TextStyle(color: Wz.muted, fontSize: 12))),
        Expanded(child: Text(n.opp, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
        Text(n.ha == 'H' ? 'Home' : 'Away', style: const TextStyle(color: Colors.white70, fontSize: 12.5)), const SizedBox(width: 12),
        Container(width: 64, padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: PlayerCard.fdr(n.fdr), borderRadius: BorderRadius.circular(6)),
            child: Text('FDR ${n.fdr}', textAlign: TextAlign.center, style: TextStyle(color: n.fdr >= 4 ? Colors.white : Wz.bg, fontSize: 11.5, fontWeight: FontWeight.w700))),
      ])),
  ]));

  Widget _market(Player p) => Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _title(Icons.swap_vert_rounded, Wz.purple2, 'Transfer Market'),
    _kv('Transfers in (GW)', _k(p.tin), Wz.green), _kv('Transfers out (GW)', _k(p.tout), Wz.red),
    _kv('Net', '${p.tin - p.tout >= 0 ? '+' : '-'}${_k((p.tin - p.tout).abs())}', p.tin >= p.tout ? Wz.green : Wz.red),
    _kv('Selected by', '${p.own.toStringAsFixed(1)}%', Colors.white),
  ]));
  Widget _kv(String k, String v, Color col) => Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))),
      child: Row(children: [Text(k, style: const TextStyle(color: Wz.muted, fontSize: 13)), const Spacer(), Text(v, style: TextStyle(color: col, fontSize: 14.5, fontWeight: FontWeight.w700))]));
}
