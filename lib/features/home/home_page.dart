import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/config.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/fixture.dart';
import '../../models/player.dart';
import '../players/pitch.dart';

/// A11 — Home Dashboard (/home).
/// Signed in → GET /api/app/home {gw, summary, leagues, live} (+ /squad for the team preview).
/// Visitors → GET /api/app/public/home {gw, top_players, fixtures, top_managers, featured_leagues}.
/// No FPL team linked → summary is null and the hero offers the A06 connect flow instead.
class HomePage extends StatelessWidget { const HomePage({super.key});
  @override Widget build(BuildContext c) => Session.I.loggedIn ? const _Dashboard() : const _PublicHome(); }

// ======================================================================================
// shared pieces
// ======================================================================================

String _num(dynamic v) { final n = jIntN(v); if (n == null) return '—'; return '$n'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','); }
String? _abs(String? u) => Config.abs(u);
BoxDecoration _panel({Color? border}) => BoxDecoration(color: Wz.panel.withValues(alpha: .92), borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));

class _SectionHead extends StatelessWidget {
  final String title; final String? action; final VoidCallback? onAction; final Widget? leading;
  const _SectionHead(this.title, {this.action, this.onAction, this.leading});
  @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
    if (leading != null) ...[leading!, const SizedBox(width: 8)],
    Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const Spacer(),
    if (action != null) InkWell(onTap: onAction, child: Text('$action ›', style: const TextStyle(color: Wz.green, fontSize: 13, fontWeight: FontWeight.w600))),
  ]));
}

/// Cinematic hero: stadium + #10 player, content on the left.
class _Hero extends StatelessWidget {
  final Widget child; final String flourish; final double height;
  const _Hero({required this.child, required this.flourish, this.height = 260});
  @override Widget build(BuildContext c) {
    final wide = MediaQuery.of(c).size.width >= 760;
    return Container(height: wide ? height : null, clipBehavior: Clip.antiAlias, decoration: _panel(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
      Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .55), Wz.bg.withValues(alpha: .25)], stops: const [.3, .65, 1])))),
      if (wide) Positioned(right: 150, top: 10, bottom: -200, child: Image.asset(WzAssets.player10, fit: BoxFit.fitHeight, alignment: Alignment.topCenter)),
      if (wide) Positioned(right: 18, top: 26, child: Transform.rotate(angle: -.16, child: Column(children: [Text(flourish, textAlign: TextAlign.center, style: script(30)), const FfwCrown(size: 26, color: Wz.green)]))),
      Padding(padding: EdgeInsets.all(wide ? 26 : 18), child: child),
    ]));
  }
}

class _Stat extends StatelessWidget {
  final IconData icon; final Color color; final String value, label; final String? sub;
  const _Stat(this.icon, this.color, this.value, this.label, {this.sub});
  @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
    child: Row(children: [
      Icon(icon, color: color, size: 26), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700))),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5)),
        if (sub != null) Text(sub!, style: const TextStyle(color: Wz.green, fontSize: 11, fontWeight: FontWeight.w600)),
      ])),
    ]));
}

class _GwPill extends StatelessWidget {
  final Map<String, dynamic> gw; const _GwPill(this.gw);
  @override Widget build(BuildContext c) {
    final live = jBool(gw['live']);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: (live ? Wz.red : Wz.green).withValues(alpha: .15), borderRadius: BorderRadius.circular(20), border: Border.all(color: (live ? Wz.red : Wz.green).withValues(alpha: .6))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: live ? Wz.red : Wz.green)), const SizedBox(width: 7),
        Text('GAMEWEEK ${jInt(gw['gw'])}${live ? ' · LIVE' : ''}', style: TextStyle(color: live ? const Color(0xFFFF8EA0) : Wz.green, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ]));
  }
}

/// Compact fixture row for the dashboard.
class _MatchRow extends StatelessWidget {
  final Fixture f; const _MatchRow(this.f);
  Widget _team(Club t, {bool right = false}) => Expanded(child: Row(mainAxisAlignment: right ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
    if (!right) _badge(t), if (!right) const SizedBox(width: 8),
    Flexible(child: Text(t.code.isEmpty ? t.name : t.code, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))),
    if (right) const SizedBox(width: 8), if (right) _badge(t),
  ]));
  Widget _badge(Club t) => t.badgeUrl == null ? HexAvatar(t.code, size: 24, color: Wz.hex(t.color)) : Image.network(t.badgeUrl!, width: 24, height: 24, errorBuilder: (_, __, ___) => HexAvatar(t.code, size: 24, color: Wz.hex(t.color)));
  @override Widget build(BuildContext c) {
    final live = f.status == 'live';
    final mid = f.status == 'up' ? ((f.ko != null && f.ko!.length >= 16) ? f.ko!.substring(11, 16) : 'vs') : '${f.hs ?? 0} – ${f.as_ ?? 0}';
    return InkWell(onTap: () => c.push('/match/${f.id}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: live ? Wz.red.withValues(alpha: .45) : Wz.border2)),
      child: Row(children: [
        _team(f.home),
        SizedBox(width: 86, child: Column(children: [
          Text(mid, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          Text(live ? "${f.min}'" : f.status == 'ft' ? 'FT' : 'GW ${f.gw}', style: TextStyle(color: live ? Wz.red : Wz.muted, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        _team(f.away, right: true),
      ])));
  }
}

class _Quick extends StatelessWidget {
  final IconData icon; final String label; final String route; final Color color;
  const _Quick(this.icon, this.label, this.route, {this.color = Wz.green});
  @override Widget build(BuildContext c) => InkWell(onTap: () => c.go(route), borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
    child: Column(children: [Icon(icon, color: color, size: 26), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600))])));
}

/// Lays out [a] and [b] side by side on wide screens, stacked on narrow ones.
Widget _split(BuildContext c, Widget a, Widget b, {int fa = 3, int fb = 2}) => MediaQuery.of(c).size.width >= 1100
    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: fa, child: a), const SizedBox(width: 14), Expanded(flex: fb, child: b)])
    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 14), b]);

EdgeInsets _pad(BuildContext c) => Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28);

// ======================================================================================
// signed in
// ======================================================================================

class _Dashboard extends StatelessWidget { const _Dashboard();
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: Repo.I.home, poll: const Duration(seconds: 60), builder: (c, j, reload) {
    final u = Session.I.user!;
    final gw = jMap(j['gw']); final sm = jMap(j['summary']); final live = jListOf(j['live'], Fixture.fromJson); final leagues = jList(j['leagues']);
    final linked = u.fpl != null && sm['total'] != null;
    final compact = Bp.compact(c);
    return ListView(padding: _pad(c), children: [
      if (compact) Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [const FfwWordmark(height: 22), const Spacer(),
        IconButton(onPressed: () => c.go('/notifications'), icon: const Icon(Icons.notifications_none_rounded, color: Colors.white))])),
      _Hero(flourish: 'Your team.\nYour war.', child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _GwPill(gw), const SizedBox(height: 12),
        Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: compact ? 14 : 16)),
        Text(u.name.split(' ').first.toUpperCase(), style: anton(compact ? 34 : 44, color: Colors.white, spacing: 1)),
        if (u.team.isNotEmpty) Text(u.team, style: const TextStyle(color: Wz.green, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (linked) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: GridView.count(crossAxisCount: compact ? 2 : 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: compact ? 2.4 : 2.5, children: [
          _Stat(Icons.bolt_rounded, Wz.green, _num(sm['gw_pts']), 'GW ${jInt(gw['gw'])} Points'),
          _Stat(Icons.emoji_events_rounded, Wz.gold, _num(sm['total']), 'Total Points'),
          _Stat(Icons.bar_chart_rounded, Wz.cyan, _num(sm['orank']), 'Overall Rank'),
          _Stat(Icons.account_balance_wallet_outlined, Wz.purple2, sm['bank'] == null ? '—' : '£${sm['bank']}m', 'Bank', sub: sm['free'] == null ? null : '${sm['free']} free transfer${jInt(sm['free']) == 1 ? '' : 's'}'),
        ]))
        else ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .7), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.gold.withValues(alpha: .5))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Connect your FPL team', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 4),
            const Text('Link your Fantasy Premier League team to see your points, squad, transfers and league status.', style: TextStyle(color: Wz.muted, fontSize: 13, height: 1.4)), const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => c.go('/connect-fpl'), icon: const Icon(Icons.link_rounded), label: const Text('Connect with FPL')),
          ]))),
      ])),
      const SizedBox(height: 16),
      _split(c, _leaguesCard(c, leagues), _liveCard(c, live)),
      const SizedBox(height: 16),
      _split(c, linked ? _teamCard(c) : _modesCard(c), _quickCard(c), fa: 3, fb: 2),
    ]);
  })));

  Widget _leaguesCard(BuildContext c, List<Map<String, dynamic>> leagues) => Container(padding: const EdgeInsets.all(16), decoration: _panel(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _SectionHead('My Leagues', action: 'View All', onAction: () => c.go('/leagues'), leading: const Icon(Icons.emoji_events_rounded, color: Wz.gold, size: 20)),
    if (leagues.isEmpty) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .5), borderRadius: BorderRadius.circular(10)), child: Column(children: [
      const Text("You haven't joined a league yet.", style: TextStyle(color: Wz.muted)), const SizedBox(height: 10),
      Wrap(spacing: 8, children: [FilledButton(onPressed: () => c.go('/leagues'), child: const Text('Find a League')), OutlinedButton(onPressed: () => c.go('/create-league'), child: const Text('Create One'))]),
    ]))
    else for (final l in leagues.take(5)) InkWell(onTap: () => c.go('/league/${l['slug']}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
      child: Row(children: [
        LeagueCrest(jStr(l['name']), badgeColor: jStrN(l['badge_color']), logo: _abs(jStrN(l['logo'])), size: 38),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(jStr(l['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
          Text([if (l['members'] != null) '${l['members']} managers', if (l['clan'] != null) '${l['clan']}${l['clan_rank'] != null ? ' · clan #${l['clan_rank']}' : ''}'].join(' · '),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 12)),
        ])),
        if (l['survivor'] != null) ...[StatusPill(jStr(l['survivor'])), const SizedBox(width: 10)],
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(l['rank'] == null ? '—' : '#${l['rank']}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const Text('Rank', style: TextStyle(color: Wz.muted, fontSize: 11)),
        ]),
        const Icon(Icons.chevron_right_rounded, color: Wz.muted),
      ]))),
  ]));

  Widget _liveCard(BuildContext c, List<Fixture> live) => Container(padding: const EdgeInsets.all(16), decoration: _panel(border: live.isEmpty ? null : Wz.red.withValues(alpha: .4)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _SectionHead(live.isEmpty ? 'Matches' : 'Live Now', action: 'Match Centre', onAction: () => c.go('/live'), leading: Icon(Icons.sensors_rounded, color: live.isEmpty ? Wz.muted : Wz.red, size: 20)),
    if (live.isEmpty) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.stadium_outlined, color: Colors.white.withValues(alpha: .4), size: 40), const SizedBox(height: 8),
      const Text('No matches live right now.', style: TextStyle(color: Wz.muted)), const SizedBox(height: 8),
      OutlinedButton(onPressed: () => c.go('/live'), child: const Text('See Fixtures')),
    ])))
    else for (final f in live.take(5)) _MatchRow(f),
  ]));

  Widget _teamCard(BuildContext c) => Container(padding: const EdgeInsets.all(16), decoration: _panel(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _SectionHead('My Team', action: 'Full Team', onAction: () => c.go('/squad'), leading: const Icon(Icons.shield_outlined, color: Wz.green, size: 20)),
    Async(load: () => Repo.I.squad(), builder: (c, s, _) {
      final picks = jListOf(s['picks'], Player.fromJson);
      if (picks.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Your squad is still syncing.', style: TextStyle(color: Wz.muted))));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Pitch(picks: picks, mode: 'team', onTap: (p) => c.push('/players/${p.id}')),
        const SizedBox(height: 8),
        Text([if (s['chip'] != null) 'Chip: ${s['chip']}', if (s['hits'] != null) 'Hits: ${s['hits']}', if (s['bench_pts'] != null) 'Bench: ${s['bench_pts']} pts'].join('  ·  '), textAlign: TextAlign.center, style: const TextStyle(color: Wz.muted, fontSize: 12)),
      ]);
    }),
  ]));

  Widget _modesCard(BuildContext c) => Container(padding: const EdgeInsets.all(16), decoration: _panel(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _SectionHead('Game Modes', action: 'Explore', onAction: () => c.go('/modes'), leading: const Icon(Icons.sports_mma_rounded, color: Wz.green, size: 20)),
    for (final m in const [('Ranking', 'Pure points. Climb the table.', Wz.gold), ('Civil War', 'Clan vs clan every gameweek.', Wz.red), ('Last Survivor', 'Survive each round or you are out.', Wz.purple2), ('Head-to-Head', 'Manager vs manager fixtures.', Wz.cyan)])
      Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: m.$3, width: 3))),
        child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), Text(m.$2, style: const TextStyle(color: Wz.muted, fontSize: 12))]))])),
  ]));

  Widget _quickCard(BuildContext c) => Container(padding: const EdgeInsets.all(16), decoration: _panel(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const _SectionHead('Quick Actions', leading: Icon(Icons.flash_on_rounded, color: Wz.gold, size: 20)),
    GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: MediaQuery.of(c).size.width >= 1100 ? 1.7 : 1.25, children: const [
      _Quick(Icons.swap_horiz_rounded, 'Transfers', '/transfers'),
      _Quick(Icons.bolt_rounded, 'Chips', '/chips', color: Wz.purple2),
      _Quick(Icons.leaderboard_outlined, 'Rankings', '/rankings', color: Wz.cyan),
      _Quick(Icons.sports_mma_rounded, 'Modes', '/modes'),
      _Quick(Icons.groups_outlined, 'Clans', '/clans', color: Wz.cyan),
      _Quick(Icons.military_tech_outlined, 'Hall of Fame', '/hof', color: Wz.gold),
    ]),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.green.withValues(alpha: .3))),
      child: Row(children: [const FfwCrown(size: 24), const SizedBox(width: 12), Expanded(child: Text('Play. Survive. Conquer.', style: script(24)))])),
  ]));
}

// ======================================================================================
// visitors
// ======================================================================================

class _PublicHome extends StatelessWidget { const _PublicHome();
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: Repo.I.publicHome, builder: (c, j, _) {
    final tp = jList(j['top_players']); final fx = jListOf(j['fixtures'], Fixture.fromJson); final gw = jMap(j['gw']); final tm = jList(j['top_managers']); final fl = jList(j['featured_leagues']);
    final compact = Bp.compact(c);
    return ListView(padding: _pad(c), children: [
      if (compact) const Padding(padding: EdgeInsets.only(bottom: 12), child: FfwWordmark(height: 22)),
      _Hero(flourish: 'Play.\nSurvive.\nConquer.', height: 280, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (gw.isNotEmpty) _GwPill(gw), const SizedBox(height: 12),
        Text('PLAY. COMPETE.', style: anton(compact ? 34 : 48, color: Colors.white, spacing: 1)),
        Text('DOMINATE.', style: anton(compact ? 34 : 48, color: Wz.green, spacing: 1)),
        const SizedBox(height: 8),
        Text('Private-league tournaments for Fantasy Premier League managers.', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: compact ? 13.5 : 15)),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(onPressed: () => c.go('/register'), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Join the Warzone')),
          OutlinedButton(onPressed: () => c.go('/login'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), child: const Text('Login')),
        ]),
      ])),
      const SizedBox(height: 16),
      if (tp.isNotEmpty) Container(padding: const EdgeInsets.all(16), decoration: _panel(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _SectionHead('Top of the Week · GW ${jInt(gw['gw'])}', action: 'Players', onAction: () => c.go('/players'), leading: const Icon(Icons.local_fire_department_rounded, color: Wz.gold, size: 20)),
        Row(children: [for (final p in tp.take(compact ? 3 : 5)) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: InkWell(onTap: () => c.push('/players/${p['id']}'), borderRadius: BorderRadius.circular(10),
          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Column(children: [
            SizedBox(height: compact ? 70 : 90, child: _abs(jStrN(p['photo'])) == null ? const Icon(Icons.person_rounded, color: Wz.faint, size: 50)
                : Image.network(_abs(jStrN(p['photo']))!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Wz.faint, size: 50))),
            const SizedBox(height: 6),
            Text(jStr(p['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(jStr(p['club_code'], jStr(p['club'])), style: const TextStyle(color: Wz.muted, fontSize: 11)),
            Text('${p['pts']} pts', style: const TextStyle(color: Wz.green, fontSize: 14, fontWeight: FontWeight.w700)),
          ]))))),
        ]),
      ])),
      const SizedBox(height: 16),
      _split(c,
        Container(padding: const EdgeInsets.all(16), decoration: _panel(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SectionHead(fx.any((f) => f.status == 'live') ? 'Live Now' : 'Fixtures', action: 'Match Centre', onAction: () => c.go('/live'), leading: const Icon(Icons.sensors_rounded, color: Wz.red, size: 20)),
          if (fx.isEmpty) const Text('No fixtures right now.', style: TextStyle(color: Wz.muted)) else for (final f in fx.take(6)) _MatchRow(f),
        ])),
        Container(padding: const EdgeInsets.all(16), decoration: _panel(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SectionHead('Top Managers', action: 'Rankings', onAction: () => c.go('/rankings'), leading: const Icon(Icons.leaderboard_outlined, color: Wz.cyan, size: 20)),
          for (final (i, m) in tm.take(5).indexed) InkWell(onTap: () => c.push('/manager/${m['id']}'), child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
            SizedBox(width: 26, child: Text('${i + 1}', style: TextStyle(color: i == 0 ? Wz.gold : Wz.muted, fontWeight: FontWeight.w700))),
            HexAvatar(jStr(m['name']).isEmpty ? '?' : jStr(m['name']).substring(0, 1), url: _abs(jStrN(m['avatar'])), size: 32), const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(jStr(m['team']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(jStr(m['name']), style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
            ])),
            Text(_num(m['total']), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ]))),
        ]))),
      if (fl.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: _panel(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SectionHead('Featured Leagues', action: 'All Leagues', onAction: () => c.go('/leagues'), leading: const Icon(Icons.emoji_events_rounded, color: Wz.gold, size: 20)),
          for (final l in fl) InkWell(onTap: () => c.go('/league/${l['slug']}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
            child: Row(children: [
              LeagueCrest(jStr(l['name']), badgeColor: jStrN(l['badge_color']), logo: _abs(jStrN(l['logo'])), size: 40), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(jStr(l['name']), style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
                Text('${l['members'] ?? 0} managers · ${l['modes'] is List ? (l['modes'] as List).join(', ') : jStr(l['modes']).replaceAll(' ', ', ')}', style: const TextStyle(color: Wz.muted, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right_rounded, color: Wz.muted),
            ]))),
        ])),
      ],
    ]);
  })));
}

