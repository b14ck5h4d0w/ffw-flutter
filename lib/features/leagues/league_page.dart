import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/assets.dart';
import '../../core/config.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/league.dart';
import '../modes/mode_views.dart';

/// League page (/league/:slug[/tab]) — one hero + tabs:
/// A25 Overview · A26 Standings · (mode tabs) · A27 Members · A28 Requests (owner) · A29 Rules · A30 History.
/// GET /api/app/leagues/<slug> → {league, me:{modes}, gw, rules, prize}; tabs load their own endpoints.

const kLeagueModes = {
  'ranking': ('Ranking', Wz.gold, Icons.leaderboard_rounded), 'civil-war': ('Civil War', Wz.red, Icons.shield_moon_outlined),
  'survivor': ('Last Survivor', Wz.purple2, Icons.dangerous_outlined), 'h2h': ('Head-to-Head', Wz.cyan, Icons.sports_kabaddi_rounded),
};
BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
EdgeInsets _pad(BuildContext c) => Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 16, 24, 28);
Widget _meta(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 15, color: Wz.green), const SizedBox(width: 5), Text(t, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13))]);
String _num(int n) => '$n'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
String _ini(String s) => s.trim().isEmpty ? '?' : s.trim().substring(0, s.trim().length >= 2 ? 2 : 1).toUpperCase();

Widget _title(IconData i, Color col, String t, {Widget? trailing}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(i, color: col, size: 20), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))), if (trailing != null) trailing]));

class LeaguePage extends StatefulWidget { final String slug; final String tab; const LeaguePage(this.slug, {super.key, this.tab = 'overview'}); @override State<LeaguePage> createState() => _LeagueState(); }

class _LeagueState extends State<LeaguePage> {
  late String tab = widget.tab == 'table' ? 'standings' : widget.tab;
  bool joining = false;

  /// Shown to visitors when the server needs a login for this league (no public view link).
  Widget _gate(BuildContext c) => Center(child: Container(margin: const EdgeInsets.all(20), constraints: const BoxConstraints(maxWidth: 440), padding: const EdgeInsets.all(24), decoration: _box(), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.emoji_events_outlined, color: Wz.gold, size: 40), const SizedBox(height: 12),
    Text('LEAGUE', style: anton(28, color: Colors.white)), const SizedBox(height: 6),
    const Text('Log in to see this league, its standings and members.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted)), const SizedBox(height: 16),
    Row(mainAxisSize: MainAxisSize.min, children: [FilledButton(onPressed: () => c.go('/login'), child: const Text('Login')), const SizedBox(width: 10), OutlinedButton(onPressed: () => c.go('/register'), child: const Text('Create Account'))]),
  ])));

  /// Visitors load the league too: when its owner turned on the public view link the server answers without a token;
  /// otherwise it answers 401/403 and the login card is shown.
  @override Widget build(BuildContext c) {
    final guest = !Session.I.loggedIn;
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: () => Repo.I.league(widget.slug),
      onError: (c, e) => guest && e is ApiException && (e.kind == ErrKind.sessionExpired || e.kind == ErrKind.forbidden) ? _GuestLeague(widget.slug, gate: _gate(c)) : null,
      builder: (c, j, reload) {
      final l = League.fromJson(jMap(j['league'])); final me = jMap(jMap(j['me'])['modes']);
      final tabs = <(String, String)>[('overview', 'Overview'), ('standings', 'Standings'), if (l.has('survivor')) ('survivor', 'Last Survivor'), if (l.has('civil-war')) ('civil-war', 'Civil War'), if (l.has('h2h')) ('h2h', 'Head-to-Head'),
        ('members', 'Members'), if (l.owner) ('requests', 'Requests'), ('rules', 'Rules'), ('history', 'History')];
      final cur = tabs.any((t) => t.$1 == tab) ? tab : 'overview';
      return NestedScrollView(
        headerSliverBuilder: (c, _) => [
          SliverToBoxAdapter(child: Padding(padding: _pad(c).copyWith(bottom: 12), child: _hero(c, l, me, j, reload))),
          SliverPersistentHeader(pinned: true, delegate: _TabsDelegate(tabs: tabs, current: cur, onTap: (t) => setState(() => tab = t), pad: _pad(c).left)),
        ],
        body: switch (cur) {
          'standings' => LeagueStandings(widget.slug, padding: _pad(c)),
          'survivor' => SurvivorView(widget.slug),
          'civil-war' => CivilWarView(widget.slug),
          'h2h' => H2HView(widget.slug),
          'members' => _MembersTab(widget.slug, owner: l.owner),
          'requests' => _RequestsTab(widget.slug),
          'rules' => _RulesTab(j, l),
          'history' => _HistoryTab(widget.slug),
          _ => _OverviewTab(l: l, j: j, onTab: (t) => setState(() => tab = t)),
        });
    })));
  }

  /// Public view link dialog. Owner can switch the link on/off here (POST leagues/<slug>/settings {public_view});
  /// everyone else just copies it.
  Future<void> _share(League l, Future<void> Function() reload) async {
    final link = '${Config.baseUrl}/league/${l.slug}';
    var on = l.publicView == true; var busy = false;
    final changed = await showDialog<bool>(context: context, builder: (d) => StatefulBuilder(builder: (d, set) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Share League'), content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (l.owner) SwitchListTile(contentPadding: EdgeInsets.zero, value: on, activeThumbColor: Wz.green, title: const Text('Public view link'),
        subtitle: Text(on ? 'Anyone with the link can see standings and game modes without logging in.' : 'Off — only logged-in managers can see this league.', style: const TextStyle(color: Wz.muted, fontSize: 12.5)),
        onChanged: busy ? null : (v) async { set(() => busy = true); try { await Repo.I.saveSettings(l.slug, {'public_view': v}); set(() { on = v; busy = false; }); } catch (e) { set(() => busy = false); if (d.mounted) toast(d, e.toString(), error: true); } }),
      if (on) ...[
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Wz.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.green.withValues(alpha: .6))),
          child: Row(children: [const Icon(Icons.link_rounded, color: Wz.green, size: 20), const SizedBox(width: 10), Expanded(child: SelectableText(link, style: const TextStyle(color: Colors.white, fontSize: 14)))])),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: link)); toast(d, 'League link copied'); }, icon: const Icon(Icons.copy_rounded, size: 18), label: const Text('Copy Link')),
      ],
    ])), actions: [TextButton(onPressed: () => Navigator.pop(d, on != (l.publicView == true)), child: const Text('Done'))])));
    if (changed == true) await reload();
  }

  Future<void> _join(League l, Future<void> Function() reload) async {
    if (!Session.I.loggedIn) { context.go('/login'); return; }   // visitor on a public view link
    setState(() => joining = true);
    try { final r = await Repo.I.joinLeague(l.slug); if (mounted) toast(context, jStr(r['msg'], 'Request sent')); await reload(); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => joining = false); }
  }

  Widget _hero(BuildContext c, League l, Map<String, dynamic> me, Map<String, dynamic> j, Future<void> Function() reload) {
    final compact = Bp.compact(c);
    final rank = jMap(me['ranking'])['my_rank'] ?? l.myRank; final surv = jStrN(jMap(me['survivor'])['me']) ?? l.mySurvivor; final clanRank = jMap(me['civilwar'])['my_rank'] ?? l.myClanRank;
    final actions = <Widget>[
      if (!l.joined) FilledButton.icon(onPressed: joining ? null : () => _join(l, reload), icon: joining ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.onPrimary)) : const Icon(Icons.group_add_rounded, size: 19), label: Text(l.public ? 'Join League' : 'Request to Join')),
      if (l.code.isNotEmpty) OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: l.code)); toast(c, 'Invite code ${l.code} copied'); }, style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.copy_rounded, size: 17), label: Text('Code: ${l.code}')),
      // Share: anyone sees it when the league is public-view; the owner also sees it while off, to turn it on.
      if (l.publicView == true || (l.owner && l.publicView == false)) OutlinedButton.icon(onPressed: () => _share(l, reload), style: OutlinedButton.styleFrom(foregroundColor: Wz.cyan, side: BorderSide(color: Wz.cyan.withValues(alpha: .7))), icon: const Icon(Icons.share_rounded, size: 18), label: const Text('Share League')),
      if (l.owner) OutlinedButton.icon(onPressed: () => c.push('/manage/${l.slug}'), style: OutlinedButton.styleFrom(foregroundColor: Wz.purple2, side: BorderSide(color: Wz.purple2.withValues(alpha: .7))), icon: const Icon(Icons.settings_outlined, size: 18), label: const Text('Manage')),
      OutlinedButton.icon(onPressed: () => c.push('/league/${l.slug}/hof'), style: OutlinedButton.styleFrom(foregroundColor: Wz.gold, side: BorderSide(color: Wz.gold.withValues(alpha: .6))), icon: const Icon(Icons.military_tech_outlined, size: 18), label: const Text('Hall of Fame')),
    ];
    return Container(clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
      Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .95), Wz.bg.withValues(alpha: .55)], stops: const [.45, 1])))),
      if (!compact) Positioned(right: 26, top: 22, child: Transform.rotate(angle: -.14, child: Text('More than a league.\nA family.', textAlign: TextAlign.center, style: script(28)))),
      Padding(padding: EdgeInsets.all(compact ? 16 : 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(onTap: () => c.canPop() ? c.pop() : c.go('/leagues'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70), SizedBox(width: 6), Text('Leagues', style: TextStyle(color: Colors.white70, fontSize: 13))])),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          LeagueCrest(l.name, badgeColor: l.badgeColor, logo: l.logo, size: compact ? 58 : 80), SizedBox(width: compact ? 14 : 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Flexible(child: Text(l.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: anton(compact ? 28 : 42, color: Colors.white, spacing: .6))), if (l.official) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.verified_rounded, color: Wz.green, size: 22))]),
            const SizedBox(height: 6),
            Wrap(spacing: 14, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _meta(l.public ? Icons.public_rounded : Icons.lock_outline_rounded, l.public ? 'Public League' : 'Private League'),
              _meta(Icons.groups_rounded, '${_num(l.managers)} managers'),
              if (l.clans > 0) _meta(Icons.shield_outlined, '${l.clans} clans'),
              if (l.season.isNotEmpty) _meta(Icons.calendar_month_outlined, l.season),
              if (j['gw'] != null) _meta(Icons.bolt_rounded, 'GW ${j['gw']}'),
            ]),
          ])),
        ]),
        if (l.joined && (rank != null || surv != null || clanRank != null)) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: [
            if (rank != null) _mine('#$rank', 'Your Rank', Wz.gold),
            if (surv != null) _mine(surv, 'Last Survivor', surv == 'SAFE' ? Wz.green : surv == 'OUT' ? Wz.muted : Wz.red),
            if (clanRank != null) _mine('#$clanRank', 'Your Clan', Wz.cyan),
          ]),
        ],
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: actions),
      ])),
    ]));
  }

  Widget _mine(String v, String k, Color col) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .65), borderRadius: BorderRadius.circular(10), border: Border.all(color: col.withValues(alpha: .5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.w700)), Text(k, style: const TextStyle(color: Wz.muted, fontSize: 11))]));
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final List<(String, String)> tabs; final String current; final void Function(String) onTap; final double pad;
  _TabsDelegate({required this.tabs, required this.current, required this.onTap, required this.pad});
  @override double get minExtent => 54;
  @override double get maxExtent => 54;
  @override bool shouldRebuild(covariant _TabsDelegate o) => o.current != current || o.tabs.length != tabs.length;
  @override Widget build(BuildContext c, double shrink, bool overlaps) => Container(color: Wz.bg, padding: const EdgeInsets.only(bottom: 8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: pad), child: Row(children: [
    for (final t in tabs) Padding(padding: const EdgeInsets.only(right: 6), child: InkWell(onTap: () => onTap(t.$1), borderRadius: BorderRadius.circular(8), child: Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center,
      decoration: BoxDecoration(color: current == t.$1 ? Wz.green.withValues(alpha: .16) : Wz.panel, borderRadius: BorderRadius.circular(8), border: Border.all(color: current == t.$1 ? Wz.green.withValues(alpha: .55) : Wz.border2)),
      child: Text(t.$2, style: TextStyle(color: current == t.$1 ? Wz.green : Colors.white.withValues(alpha: .85), fontSize: 14, fontWeight: FontWeight.w600))))),
  ])));
}

// ======================================================================================
// A25 — Overview
// ======================================================================================

class _OverviewTab extends StatelessWidget {
  final League l; final Map<String, dynamic> j; final void Function(String) onTab;
  const _OverviewTab({required this.l, required this.j, required this.onTab});
  @override Widget build(BuildContext c) {
    final prize = jStrN(jMap(j['prize'])['total']) ?? (l.prize.isEmpty ? null : l.prize);
    final about = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.info_outline_rounded, Wz.green, 'About ${l.name}'),
      Text(l.desc.isEmpty ? 'No description yet.' : l.desc, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 14, height: 1.45)),
      if (prize != null) ...[const SizedBox(height: 14), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.gold.withValues(alpha: .08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.gold.withValues(alpha: .45))),
        child: Row(children: [const Icon(Icons.emoji_events_rounded, color: Wz.gold), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('PRIZE', style: TextStyle(color: Wz.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)), Text(prize, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600))]))]))],
    ]));
    final modes = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.sports_mma_rounded, Wz.green, 'Active Modes'),
      if (l.modes.isEmpty) const Text('No modes enabled yet.', style: TextStyle(color: Wz.muted)),
      for (final m in l.modes) () {
        final meta = kLeagueModes[m] ?? (m, Wz.muted, Icons.circle);
        final target = m == 'ranking' ? 'standings' : m;
        return InkWell(onTap: () => onTab(target), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: meta.$2, width: 3))),
          child: Row(children: [Icon(meta.$3, color: meta.$2, size: 22), const SizedBox(width: 12), Expanded(child: Text(meta.$1, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600))), const Icon(Icons.chevron_right_rounded, color: Wz.muted)])));
      }(),
    ]));
    final top = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.leaderboard_rounded, Wz.gold, 'Top Managers', trailing: InkWell(onTap: () => onTab('standings'), child: const Text('Full Standings ›', style: TextStyle(color: Wz.green, fontSize: 13, fontWeight: FontWeight.w600)))),
      Async(load: () => Repo.I.standings(l.slug, 'overall'), builder: (c, s, _) {
        final rows = jListOf(s['rows'], StandingRow.fromJson);
        if (rows.isEmpty) return const Text('No standings yet.', style: TextStyle(color: Wz.muted));
        return Column(children: [for (final r in rows.take(5)) StandingTile(r)]);
      }),
    ]));
    final wide = MediaQuery.of(c).size.width >= 1100;
    return ListView(padding: _pad(c).copyWith(top: 6), children: [
      wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: Column(children: [about, const SizedBox(height: 14), top])), const SizedBox(width: 16), Expanded(flex: 2, child: modes)])
           : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [about, const SizedBox(height: 14), modes, const SizedBox(height: 14), top]),
    ]);
  }
}

// ======================================================================================
// A26 — Standings
// ======================================================================================

/// One standings row (rank · movement · avatar · team/manager · GW · total).
class StandingTile extends StatelessWidget {
  final StandingRow r; const StandingTile(this.r, {super.key});
  @override Widget build(BuildContext c) {
    final medal = r.rank == 1 ? Wz.gold : r.rank == 2 ? const Color(0xFFC9D3D8) : r.rank == 3 ? const Color(0xFFCD8B52) : null;
    return InkWell(onTap: () => c.push('/manager/${r.userId}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: r.me ? Wz.green.withValues(alpha: .1) : Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: r.me ? Wz.green.withValues(alpha: .5) : Wz.border2)),
      child: Row(children: [
        SizedBox(width: 34, child: Text('${r.rank}', style: TextStyle(color: medal ?? Colors.white70, fontSize: 16, fontWeight: FontWeight.w700))),
        SizedBox(width: 34, child: r.mv == 0 ? const Text('–', style: TextStyle(color: Wz.faint)) : Row(mainAxisSize: MainAxisSize.min, children: [Icon(r.mv > 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, size: 18, color: r.mv > 0 ? Wz.green : Wz.red), Text('${r.mv.abs()}', style: TextStyle(color: r.mv > 0 ? Wz.green : Wz.red, fontSize: 11, fontWeight: FontWeight.w700))])),
        HexAvatar(_ini(r.team.isEmpty ? r.name : r.team), url: r.avatar, size: 34, color: medal ?? Wz.green), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Flexible(child: Text(r.team.isEmpty ? r.name : r.team, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600))), if (r.me) const Padding(padding: EdgeInsets.only(left: 6), child: Text('YOU', style: TextStyle(color: Wz.green, fontSize: 10, fontWeight: FontWeight.w800)))]),
          Text('${r.name}${r.clan != null ? ' · ${r.clan}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
        ])),
        SizedBox(width: 44, child: Text('${r.gw}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 13.5))),
        SizedBox(width: 62, child: Text(_num(r.total), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
      ])));
  }
}

class LeagueStandings extends StatefulWidget { final String slug; final EdgeInsets padding; final String title; const LeagueStandings(this.slug, {super.key, this.padding = const EdgeInsets.all(16), this.title = 'Standings'}); @override State<LeagueStandings> createState() => _StandingsState(); }
class _StandingsState extends State<LeagueStandings> {
  String view = 'overall';
  static const _views = [('overall', 'Overall'), ('gw', 'This Gameweek'), ('month', 'This Month')];
  @override Widget build(BuildContext c) => Async(key: ValueKey(view), load: () => Repo.I.standings(widget.slug, view), builder: (c, j, _) {
    final rows = jListOf(j['rows'], StandingRow.fromJson);
    return ListView(padding: widget.padding.copyWith(top: 6), children: [
      Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.leaderboard_rounded, Wz.gold, widget.title, trailing: Text('${rows.length} managers', style: const TextStyle(color: Wz.muted, fontSize: 12))),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final v in _views) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(selected: view == v.$1, onSelected: (_) => setState(() => view = v.$1), showCheckmark: false, label: Text(v.$2),
            labelStyle: TextStyle(color: view == v.$1 ? Wz.onPrimary : Colors.white, fontWeight: FontWeight.w600), selectedColor: Wz.green, backgroundColor: Wz.bg, side: const BorderSide(color: Wz.border2)))])),
        const SizedBox(height: 12),
        const Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 6), child: Row(children: [
          SizedBox(width: 68, child: Text('#', style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w700))),
          Expanded(child: Text('MANAGER', style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w700))),
          SizedBox(width: 44, child: Text('GW', textAlign: TextAlign.right, style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w700))),
          SizedBox(width: 62, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(color: Wz.muted, fontSize: 11, fontWeight: FontWeight.w700))),
        ])),
        if (rows.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No standings yet.', style: TextStyle(color: Wz.muted))))
        else for (final r in rows) StandingTile(r),
      ])),
    ]);
  });
}

// ======================================================================================
// A27 — Members & Managers
// ======================================================================================

class _MembersTab extends StatefulWidget { final String slug; final bool owner; const _MembersTab(this.slug, {required this.owner}); @override State<_MembersTab> createState() => _MembersState(); }
class _MembersState extends State<_MembersTab> {
  String q = '';
  static (String, Color) _role(String r) => switch (r.toLowerCase()) { 'owner' => ('OWNER', Wz.purple2), 'manager' || 'admin' => ('MANAGER', Wz.cyan), _ => ('MEMBER', Wz.muted) };
  @override Widget build(BuildContext c) => Async(load: () => Repo.I.members(widget.slug), builder: (c, ms, reload) {
    final list = q.isEmpty ? ms : ms.where((m) => jStr(m['name']).toLowerCase().contains(q.toLowerCase())).toList();
    return ListView(padding: _pad(c).copyWith(top: 6), children: [
      Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.groups_rounded, Wz.green, 'Members', trailing: Text('${ms.length} total', style: const TextStyle(color: Wz.muted, fontSize: 12))),
        TextField(onChanged: (v) => setState(() => q = v.trim()), style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'Search members…', prefixIcon: Icon(Icons.search_rounded, color: Wz.muted), isDense: true)),
        const SizedBox(height: 12),
        if (list.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No members found.', style: TextStyle(color: Wz.muted)))),
        for (final m in list) () {
          final role = _role(jStr(m['role'], 'member'));
          return InkWell(onTap: () => c.push('/manager/${m['user_id']}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.fromLTRB(12, 9, 6, 9), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
            child: Row(children: [
              HexAvatar(_ini(jStr(m['name'])), url: jStrN(m['avatar']), size: 36), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(jStr(m['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
                Text('${_num(jInt(m['points']))} pts', style: const TextStyle(color: Wz.muted, fontSize: 12)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: role.$2.withValues(alpha: .14), borderRadius: BorderRadius.circular(5)), child: Text(role.$1, style: TextStyle(color: role.$2, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .8))),
              SizedBox(width: 58, child: Text(m['rank'] == null ? '—' : '#${m['rank']}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
              if (widget.owner && role.$1 != 'OWNER') IconButton(tooltip: 'Remove from league', icon: const Icon(Icons.person_remove_outlined, color: Wz.red, size: 20), onPressed: () async {
                final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: Text('Remove ${m['name']}?'), content: const Text('They will lose their place in this league.'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), style: FilledButton.styleFrom(backgroundColor: Wz.red, foregroundColor: Colors.white), child: const Text('Remove'))]));
                if (ok == true) { try { await Repo.I.kick(widget.slug, jInt(m['user_id'])); await reload(); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); } }
              }) else const SizedBox(width: 8),
            ])));
        }(),
      ])),
    ]);
  });
}

// ======================================================================================
// A28 — Join Requests (owner)
// ======================================================================================

class _RequestsTab extends StatefulWidget { final String slug; const _RequestsTab(this.slug); @override State<_RequestsTab> createState() => _RequestsState(); }
class _RequestsState extends State<_RequestsTab> {
  int? busy;
  @override Widget build(BuildContext c) => Async(load: () => Repo.I.requests(widget.slug), builder: (c, rs, reload) {
    Future<void> act(int id, bool accept) async {
      setState(() => busy = id);
      try { await Repo.I.requestAction(widget.slug, id, accept); if (c.mounted) toast(c, accept ? 'Request approved' : 'Request rejected'); await reload(); }
      catch (e) { if (c.mounted) toast(c, e.toString(), error: true); }
      finally { if (mounted) setState(() => busy = null); }
    }
    return ListView(padding: _pad(c).copyWith(top: 6), children: [
      Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.how_to_reg_outlined, Wz.green, 'Join Requests', trailing: Text('${rs.length} pending', style: const TextStyle(color: Wz.muted, fontSize: 12))),
        if (rs.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Column(children: [Icon(Icons.inbox_outlined, color: Wz.faint, size: 36), SizedBox(height: 8), Text('No pending requests.', style: TextStyle(color: Wz.muted))]))),
        for (final r in rs) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Row(children: [
          HexAvatar(_ini(jStr(r['name'])), url: jStrN(r['avatar']), size: 38), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(jStr(r['name']), style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
            Text([if (jStr(r['handle']).isNotEmpty) jStr(r['handle']), if (r['points'] != null) '${r['points']} pts'].join(' · '), style: const TextStyle(color: Wz.muted, fontSize: 12)),
          ])),
          if (busy == jInt(r['id'])) const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.green))
          else ...[
            IconButton.filled(onPressed: () => act(jInt(r['id']), true), tooltip: 'Approve', style: IconButton.styleFrom(backgroundColor: Wz.green, foregroundColor: Wz.onPrimary), icon: const Icon(Icons.check_rounded)),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: () => act(jInt(r['id']), false), tooltip: 'Reject', style: IconButton.styleFrom(backgroundColor: Wz.red.withValues(alpha: .2), foregroundColor: Wz.red), icon: const Icon(Icons.close_rounded)),
          ],
        ])),
      ])),
    ]);
  });
}

// ======================================================================================
// A29 — Rules
// ======================================================================================

class _RulesTab extends StatelessWidget {
  final Map<String, dynamic> j; final League l; const _RulesTab(this.j, this.l);
  @override Widget build(BuildContext c) {
    final r = jMap(j['rules']); final house = jStr(r['rules_text']); final prize = jStrN(jMap(j['prize'])['total']) ?? (l.prize.isEmpty ? null : l.prize);
    Widget rule(String key, List<String> lines) { final m = kLeagueModes[key]!; return Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: _box(border: m.$2.withValues(alpha: .4)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(m.$3, m.$2, m.$1),
      for (final t in lines) Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 6), child: Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: m.$2))), const SizedBox(width: 10), Expanded(child: Text(t, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13.5, height: 1.4)))])),
    ])); }
    return ListView(padding: _pad(c).copyWith(top: 6), children: [
      Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.gavel_rounded, Wz.green, 'General'),
        Text('Official FPL points only.${r['start_gw'] != null ? ' Points count from Gameweek ${r['start_gw']}.' : ''}', style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13.5, height: 1.4)),
      ])),
      if (l.has('ranking')) rule('ranking', const ['Every manager is ranked by total FPL points.', 'Most points at the end of the season wins.']),
      if (l.has('survivor')) rule('survivor', [
        if (r['surv_round_len'] != null) 'Rounds last ${r['surv_round_len']} gameweek${jInt(r['surv_round_len']) == 1 ? '' : 's'}.',
        if (r['surv_drop'] != null) 'The lowest ${r['surv_drop']} manager${jInt(r['surv_drop']) == 1 ? ' is' : 's are'} eliminated when a round ends.',
        'Nobody is OUT until the round is final — until then the bottom places are AT RISK.',
        'The last manager standing wins.',
      ]),
      if (l.has('civil-war')) rule('civil-war', const [
        "A clan's gameweek score is the total of every eligible member's official FPL points.",
        'The top-scoring clan earns 10 War Points and the lowest earns 1; the rest follow the scale in between.',
        'During a live gameweek War Points are PROJECTED. They are locked when the gameweek is official.',
        'There is no elimination in Civil War.',
      ]),
      if (l.has('h2h')) rule('h2h', const ['The top managers are seeded into a knockout bracket.', 'Each round is one gameweek — outscore your opponent to advance.']),
      if (house.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.menu_book_outlined, Wz.cyan, 'House Rules'), Text(house, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13.5, height: 1.5))])),
      if (prize != null) Container(padding: const EdgeInsets.all(16), decoration: _box(border: Wz.gold.withValues(alpha: .45)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.emoji_events_rounded, Wz.gold, 'Prize'), Text(prize, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))])),
    ]);
  }
}

// ======================================================================================
// A30 — History
// ======================================================================================

/// Visitor view while the league itself needs a login: only public data — the league card from the public list
/// (GET leagues?public=1) and per-gameweek points (GET leagues/<slug>/history), summed into a points table.
/// Falls back to the login card when the league has no public history (e.g. private league).
class _GuestLeague extends StatefulWidget { final String slug; final Widget gate; const _GuestLeague(this.slug, {required this.gate}); @override State<_GuestLeague> createState() => _GuestLeagueState(); }
class _GuestLeagueState extends State<_GuestLeague> {
  String tab = 'table';
  static const _medals = [Wz.gold, Color(0xFFC9D3D8), Color(0xFFCD8B52)];

  Future<(League?, Map<String, dynamic>)> _load() async {
    final h = await Repo.I.leagueHistory(widget.slug);
    League? l; try { l = (await Repo.I.publicLeagues()).where((x) => x.slug == widget.slug).firstOrNull; } catch (_) {}
    return (l, h);
  }

  @override Widget build(BuildContext c) => Async(load: _load, onError: (c, e) => widget.gate, builder: (c, d, _) {
    final (l, h) = d; final gws = jList(h['gws']).where((g) => jList(g['rows']).isNotEmpty).toList();
    if (gws.isEmpty && l == null) return widget.gate;
    final name = l?.name ?? widget.slug.split('-').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    // Season points table: sum of every gameweek in the history.
    final tot = <int, ({String name, int pts, int last})>{};
    for (final g in gws) { for (final r in jList(g['rows'])) { final id = jInt(r['user_id']); final p = tot[id];
      tot[id] = (name: jStr(r['name']), pts: (p?.pts ?? 0) + jInt(r['pts']), last: jInt(r['pts'])); } }
    final table = tot.entries.toList()..sort((a, b) => b.value.pts.compareTo(a.value.pts));
    final lastGw = gws.isEmpty ? null : jInt(gws.last['gw']); final compact = Bp.compact(c);
    final head = Container(margin: _pad(c).copyWith(bottom: 12), clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
      Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .95), Wz.bg.withValues(alpha: .55)], stops: const [.45, 1])))),
      Padding(padding: EdgeInsets.all(compact ? 16 : 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          LeagueCrest(name, badgeColor: l?.badgeColor, logo: l?.logo, size: compact ? 54 : 72), SizedBox(width: compact ? 14 : 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: anton(compact ? 26 : 38, color: Colors.white, spacing: .6)),
            const SizedBox(height: 4),
            Wrap(spacing: 14, runSpacing: 4, children: [
              if (l != null) _meta(Icons.groups_rounded, '${_num(l.managers)} managers'),
              if (lastGw != null) _meta(Icons.bolt_rounded, 'Up to GW $lastGw'),
              if (l != null && l.season.isNotEmpty) _meta(Icons.calendar_month_outlined, l.season),
            ]),
          ])),
        ]),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .7), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('Viewing points only. Log in to see game modes, clans and to join.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          FilledButton(onPressed: () => c.go('/login'), child: const Text('Login')),
          OutlinedButton(onPressed: () => c.go('/register'), child: const Text('Create Account')),
        ])),
      ])),
    ]));
    final chips = Padding(padding: EdgeInsets.symmetric(horizontal: _pad(c).left).copyWith(bottom: 8), child: Wrap(spacing: 8, children: [
      for (final t in const [('table', 'Points Table'), ('gws', 'Gameweeks')]) ChoiceChip(label: Text(t.$2), selected: tab == t.$1, showCheckmark: false, selectedColor: Wz.green.withValues(alpha: .18), side: BorderSide(color: tab == t.$1 ? Wz.green : Wz.border2), labelStyle: TextStyle(color: tab == t.$1 ? Wz.green : Colors.white, fontWeight: FontWeight.w600), onSelected: (_) => setState(() => tab = t.$1)),
    ]));
    final points = ListView(padding: _pad(c).copyWith(top: 6), children: [
      Container(padding: const EdgeInsets.all(14), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.leaderboard_rounded, Wz.gold, 'Points Table', trailing: lastGw == null ? null : Text('GW $lastGw', style: const TextStyle(color: Wz.muted, fontSize: 12.5))),
        const Padding(padding: EdgeInsets.only(bottom: 6), child: Row(children: [SizedBox(width: 30), Expanded(child: Text('MANAGER', style: TextStyle(color: Wz.muted, fontSize: 11, letterSpacing: 1))), SizedBox(width: 72, child: Text('LAST GW', textAlign: TextAlign.right, style: TextStyle(color: Wz.muted, fontSize: 11, letterSpacing: 1))), SizedBox(width: 64, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(color: Wz.muted, fontSize: 11, letterSpacing: 1)))])),
        if (table.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No finished gameweeks yet.', style: TextStyle(color: Wz.muted)))),
        for (final (i, e) in table.indexed) Container(padding: const EdgeInsets.symmetric(vertical: 9), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Wz.border))), child: Row(children: [
          SizedBox(width: 30, child: Text('${i + 1}', style: TextStyle(color: i < 3 ? _medals[i] : Wz.muted, fontWeight: FontWeight.w700))),
          Expanded(child: Text(e.value.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500))),
          SizedBox(width: 72, child: Text('${e.value.last}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 13.5))),
          SizedBox(width: 64, child: Text(_num(e.value.pts), textAlign: TextAlign.right, style: TextStyle(color: i == 0 ? Wz.gold : Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
        ])),
      ])),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [head, chips, Expanded(child: tab == 'table' ? points : _HistoryTab(widget.slug))]);
  });
}

class _HistoryTab extends StatefulWidget { final String slug; const _HistoryTab(this.slug); @override State<_HistoryTab> createState() => _HistoryState(); }
class _HistoryState extends State<_HistoryTab> {
  final open = <int>{};
  static const _medals = [Wz.gold, Color(0xFFC9D3D8), Color(0xFFCD8B52)];
  @override Widget build(BuildContext c) => Async(load: () => Repo.I.leagueHistory(widget.slug), builder: (c, j, _) {
    final gws = jList(j['gws']).where((g) => jList(g['rows']).isNotEmpty).toList();
    if (gws.isEmpty) return ListView(padding: _pad(c).copyWith(top: 6), children: [Container(padding: const EdgeInsets.all(28), decoration: _box(), child: const Center(child: Text('No finished gameweeks yet.', style: TextStyle(color: Wz.muted))))]);
    // Gameweek wins per manager (finished gameweeks only).
    final wins = <String, int>{}; var best = (name: '', pts: 0, gw: 0);
    for (final g in gws.where((g) => jBool(g['finished']))) {
      final top = jList(g['rows']).first; wins[jStr(top['name'])] = (wins[jStr(top['name'])] ?? 0) + 1;
      if (jInt(top['pts']) > best.pts) best = (name: jStr(top['name']), pts: jInt(top['pts']), gw: jInt(g['gw']));
    }
    final board = wins.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final summary = Container(padding: const EdgeInsets.all(16), decoration: _box(border: Wz.gold.withValues(alpha: .35)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.military_tech_rounded, Wz.gold, 'Gameweek Winners'),
      if (best.pts > 0) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Highest score: ${best.name} — ${best.pts} pts (GW ${best.gw})', style: const TextStyle(color: Wz.green, fontSize: 13, fontWeight: FontWeight.w600))),
      for (final (i, e) in board.take(6).indexed) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
        SizedBox(width: 26, child: Text('${i + 1}', style: TextStyle(color: i < 3 ? _medals[i] : Wz.muted, fontWeight: FontWeight.w700))),
        Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14))),
        Text('${e.value} win${e.value == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      ])),
    ]));
    final list = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final g in gws.reversed) () {
      final rows = jList(g['rows']); final gw = jInt(g['gw']); final all = open.contains(gw);
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Text('GAMEWEEK $gw', style: const TextStyle(color: Wz.green, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)), const Spacer(), StatusPill(jBool(g['finished']) ? 'FINISHED' : 'LIVE')]),
        const SizedBox(height: 10),
        for (final (i, r) in (all ? rows : rows.take(3)).indexed) InkWell(onTap: r['user_id'] == null ? null : () => c.push('/manager/${r['user_id']}'), child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
          SizedBox(width: 28, child: i < 3 ? Icon(Icons.emoji_events_rounded, size: 17, color: _medals[i]) : Text('${i + 1}', style: const TextStyle(color: Wz.muted, fontSize: 12.5))),
          Expanded(child: Text(jStr(r['name']), overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400))),
          Text('${r['pts']}', style: TextStyle(color: i == 0 ? Wz.gold : Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ]))),
        if (rows.length > 3) Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => setState(() => all ? open.remove(gw) : open.add(gw)), style: TextButton.styleFrom(foregroundColor: Wz.green, padding: EdgeInsets.zero), child: Text(all ? 'Show top 3' : 'Show all ${rows.length}'))),
      ]));
    }()]);
    final wide = MediaQuery.of(c).size.width >= 1100;
    return ListView(padding: _pad(c).copyWith(top: 6), children: [
      wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: list), const SizedBox(width: 16), Expanded(flex: 2, child: summary)])
           : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [summary, const SizedBox(height: 14), list]),
    ]);
  });
}
