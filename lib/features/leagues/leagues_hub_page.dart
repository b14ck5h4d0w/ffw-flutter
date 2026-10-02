import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/league.dart';
import 'join_league_page.dart' show joinByCode;

/// A21 — My Leagues (/leagues) and A22 — League Directory (/leagues/directory).
/// GET /api/app/leagues (mine, auth) · GET /api/app/leagues/directory?q=&public= (visitors: public only).
/// League item: slug, name, desc, season, public, joined, owner, official, modes[], managers, clans,
/// my_rank, my_survivor, my_clan_rank, logo.

const _modeMeta = {
  'ranking': ('Ranking', Wz.gold), 'civil-war': ('Civil War', Wz.red), 'survivor': ('Last Survivor', Wz.purple2), 'h2h': ('Head-to-Head', Wz.cyan),
};
BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
EdgeInsets _pad(BuildContext c) => Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28);

class _Banner extends StatelessWidget {
  final String title, sub, flourish; final List<Widget> actions;
  const _Banner({required this.title, required this.sub, required this.flourish, this.actions = const []});
  @override Widget build(BuildContext c) {
    final compact = Bp.compact(c);
    return Container(clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
      Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .5)], stops: const [.4, 1])))),
      if (!compact) Positioned(right: 26, top: 22, child: Transform.rotate(angle: -.14, child: Text(flourish, textAlign: TextAlign.center, style: script(30)))),
      Padding(padding: EdgeInsets.all(compact ? 18 : 26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: anton(compact ? 30 : 42, color: Colors.white, spacing: 1)),
        Text(sub, style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
        if (actions.isNotEmpty) ...[const SizedBox(height: 16), Wrap(spacing: 10, runSpacing: 10, children: actions)],
      ])),
    ]));
  }
}

class _ModeChips extends StatelessWidget {
  final List<String> modes; const _ModeChips(this.modes);
  @override Widget build(BuildContext c) => Wrap(spacing: 6, runSpacing: 6, children: [for (final m in modes) () {
    final meta = _modeMeta[m] ?? (m, Wz.muted);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: meta.$2.withValues(alpha: .12), borderRadius: BorderRadius.circular(20), border: Border.all(color: meta.$2.withValues(alpha: .5))),
        child: Text(meta.$1, style: TextStyle(color: meta.$2, fontSize: 11, fontWeight: FontWeight.w600)));
  }()]);
}

Widget _crest(League l, double size) => LeagueCrest(l.name, badgeColor: l.badgeColor, logo: l.logo, size: size);
Widget _privacy(League l) => Row(mainAxisSize: MainAxisSize.min, children: [
  Icon(l.public ? Icons.public_rounded : Icons.lock_outline_rounded, size: 13, color: Wz.muted), const SizedBox(width: 4),
  Text(l.public ? 'Public' : 'Private', style: const TextStyle(color: Wz.muted, fontSize: 12)),
]);

// ======================================================================================
// A21 — My Leagues
// ======================================================================================

class MyLeaguesPage extends StatefulWidget { const MyLeaguesPage({super.key}); @override State<MyLeaguesPage> createState() => _MyLeaguesState(); }

class _MyLeaguesState extends State<MyLeaguesPage> {
  int ver = 0;
  @override Widget build(BuildContext c) {
    if (!Session.I.loggedIn) return const LeagueDirectoryPage();
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(key: ValueKey(ver), load: Repo.I.myLeagues, builder: (c, leagues, reload) {
      final owned = leagues.where((l) => l.owner).length;
      final ranks = leagues.map((l) => l.myRank).whereType<int>().toList()..sort();
      return ListView(padding: _pad(c), children: [
        _Banner(title: 'MY LEAGUES', sub: 'Your battles, all in one place.', flourish: 'Your leagues.\nYour war.', actions: [
          FilledButton.icon(onPressed: () => c.push('/create-league'), icon: const Icon(Icons.add_rounded, size: 19), label: const Text('Create League')),
          OutlinedButton.icon(onPressed: () async { await joinByCode(c); if (mounted) setState(() => ver++); }, style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.key_rounded, size: 18), label: const Text('Join with Code')),
          OutlinedButton.icon(onPressed: () => c.go('/leagues/directory'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), icon: const Icon(Icons.travel_explore_rounded, size: 18), label: const Text('Discover')),
        ]),
        const SizedBox(height: 14),
        if (leagues.isNotEmpty) ...[
          Wrap(spacing: 10, runSpacing: 10, children: [
            _stat(c, Icons.emoji_events_rounded, Wz.gold, '${leagues.length}', 'Leagues Joined'),
            _stat(c, Icons.admin_panel_settings_outlined, Wz.purple2, '$owned', 'Leagues You Own'),
            if (ranks.isNotEmpty) _stat(c, Icons.leaderboard_outlined, Wz.green, '#${ranks.first}', 'Best Rank'),
          ]),
          const SizedBox(height: 14),
        ],
        if (leagues.isEmpty) _empty(c) else for (final l in leagues) _row(c, l),
      ]);
    })));
  }

  Widget _stat(BuildContext c, IconData i, Color col, String v, String label) => Container(width: Bp.compact(c) ? (MediaQuery.of(c).size.width - 38) / 2 : 210, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: _box(),
    child: Row(children: [Icon(i, color: col, size: 26), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)), Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5))]))]));

  Widget _empty(BuildContext c) => Container(padding: const EdgeInsets.all(28), decoration: _box(), child: Column(children: [
    const Icon(Icons.emoji_events_outlined, color: Wz.gold, size: 40), const SizedBox(height: 10),
    const Text("You haven't joined a league yet", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 6),
    const Text('Join a public league, enter a code from a friend, or start your own.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted)), const SizedBox(height: 16),
    FilledButton.icon(onPressed: () => c.go('/leagues/directory'), icon: const Icon(Icons.travel_explore_rounded), label: const Text('Discover Leagues')),
  ]));

  Widget _row(BuildContext c, League l) {
    final compact = Bp.compact(c);
    final mine = <Widget>[
      if (l.myRank != null) _kv('#${l.myRank}', 'Rank', Colors.white),
      if (l.myClanRank != null) _kv('#${l.myClanRank}', 'Clan', Wz.cyan),
      if (l.mySurvivor != null) StatusPill(l.mySurvivor!),
    ];
    return InkWell(onTap: () => c.go('/league/${l.slug}'), borderRadius: BorderRadius.circular(12), child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: _box(border: l.owner ? Wz.purple2.withValues(alpha: .4) : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _crest(l, compact ? 46 : 54), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700))),
              if (l.owner) Padding(padding: const EdgeInsets.only(left: 8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: Wz.purple.withValues(alpha: .2), borderRadius: BorderRadius.circular(5)), child: const Text('OWNER', style: TextStyle(color: Wz.purple2, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .8)))),
              if (l.official) const Padding(padding: EdgeInsets.only(left: 6), child: Tooltip(message: 'Official league', child: Icon(Icons.verified_rounded, color: Wz.green, size: 17))),
            ]),
            const SizedBox(height: 3),
            Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('${l.managers} managers', style: const TextStyle(color: Wz.muted, fontSize: 12)),
              if (l.clans > 0) Text('${l.clans} clans', style: const TextStyle(color: Wz.muted, fontSize: 12)),
              _privacy(l),
              if (l.season.isNotEmpty) Text(l.season, style: const TextStyle(color: Wz.muted, fontSize: 12)),
            ]),
          ])),
          if (!compact) ...[for (final w in mine) Padding(padding: const EdgeInsets.only(left: 18), child: w)],
          if (l.owner && !compact) Padding(padding: const EdgeInsets.only(left: 14), child: OutlinedButton(onPressed: () => c.push('/manage/${l.slug}'), style: OutlinedButton.styleFrom(foregroundColor: Wz.purple2, side: BorderSide(color: Wz.purple2.withValues(alpha: .6))), child: const Text('Manage'))),
          const Icon(Icons.chevron_right_rounded, color: Wz.muted),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ModeChips(l.modes)),
          if (compact) ...[for (final w in mine) Padding(padding: const EdgeInsets.only(left: 12), child: w)],
        ]),
        if (l.owner && compact) Padding(padding: const EdgeInsets.only(top: 10), child: OutlinedButton(onPressed: () => c.push('/manage/${l.slug}'), style: OutlinedButton.styleFrom(foregroundColor: Wz.purple2, side: BorderSide(color: Wz.purple2.withValues(alpha: .6))), child: const Text('Manage League'))),
      ])));
  }

  Widget _kv(String v, String k, Color col) => Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
    Text(v, style: TextStyle(color: col, fontSize: 17, fontWeight: FontWeight.w700)), Text(k, style: const TextStyle(color: Wz.muted, fontSize: 10.5))]);
}

// ======================================================================================
// A22 — League Directory / Discover
// ======================================================================================

class LeagueDirectoryPage extends StatefulWidget { const LeagueDirectoryPage({super.key}); @override State<LeagueDirectoryPage> createState() => _DirectoryState(); }

class _DirectoryState extends State<LeagueDirectoryPage> {
  final search = TextEditingController(); String q = '', filter = 'all'; int ver = 0; String? joining;

  @override void dispose() { search.dispose(); super.dispose(); }
  void _go() => setState(() { q = search.text.trim(); ver++; });

  Future<void> _join(League l) async {
    if (!Session.I.loggedIn) { context.go('/login'); return; }
    setState(() => joining = l.slug);
    try { final r = await Repo.I.joinLeague(l.slug); if (mounted) { toast(context, jStr(r['msg'], 'Request sent')); setState(() { joining = null; ver++; }); } }
    catch (e) { if (mounted) { toast(context, e.toString(), error: true); setState(() => joining = null); } }
  }

  @override Widget build(BuildContext c) {
    final logged = Session.I.loggedIn;
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: _pad(c), children: [
      _Banner(title: 'LEAGUE DIRECTORY', sub: 'Find your next battle.', flourish: 'United by\nFPL rivalry.', actions: [
        if (logged) OutlinedButton.icon(onPressed: () => c.go('/leagues'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), icon: const Icon(Icons.emoji_events_outlined, size: 18), label: const Text('My Leagues')),
        if (logged) OutlinedButton.icon(onPressed: () async { await joinByCode(c); if (mounted) setState(() => ver++); }, style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.key_rounded, size: 18), label: const Text('Join with Code')),
        if (!logged) FilledButton.icon(onPressed: () => c.go('/register'), icon: const Icon(Icons.arrow_forward_rounded, size: 18), label: const Text('Join the Warzone')),
      ]),
      const SizedBox(height: 14),
      TextField(controller: search, onSubmitted: (_) => _go(), textInputAction: TextInputAction.search, style: const TextStyle(color: Wz.text),
          decoration: InputDecoration(hintText: 'Search leagues by name…', prefixIcon: const Icon(Icons.search_rounded, color: Wz.muted),
              suffixIcon: q.isEmpty ? IconButton(onPressed: _go, icon: const Icon(Icons.arrow_forward_rounded, color: Wz.green)) : IconButton(onPressed: () { search.clear(); _go(); }, tooltip: 'Clear', icon: const Icon(Icons.close_rounded, color: Wz.muted)))),
      const SizedBox(height: 12),
      Async(key: ValueKey('$q/$ver'), load: () => Repo.I.directory(q: q, public: !logged), builder: (c, all, _) {
        final opts = [('all', 'All', all.length), ('public', 'Public', all.where((l) => l.public).length), ('private', 'Private', all.where((l) => !l.public).length), if (logged) ('joined', 'Joined', all.where((l) => l.joined).length)];
        final list = all.where((l) => switch (filter) { 'public' => l.public, 'private' => !l.public, 'joined' => l.joined, _ => true }).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final o in opts) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            selected: filter == o.$1, onSelected: (_) => setState(() => filter = o.$1), showCheckmark: false, label: Text('${o.$2}  ${o.$3}'),
            labelStyle: TextStyle(color: filter == o.$1 ? Wz.onPrimary : Colors.white, fontWeight: FontWeight.w600), selectedColor: Wz.green, backgroundColor: Wz.panel, side: const BorderSide(color: Wz.border2)))])),
          const SizedBox(height: 14),
          if (list.isEmpty) Container(padding: const EdgeInsets.all(28), decoration: _box(), child: Center(child: Text(q.isEmpty ? 'No leagues here yet.' : 'No leagues match "$q".', style: const TextStyle(color: Wz.muted))))
          else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 420, mainAxisExtent: 214, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemBuilder: (c, i) => _card(c, list[i])),
        ]);
      }),
    ])));
  }

  Widget _card(BuildContext c, League l) => InkWell(onTap: () => c.go('/league/${l.slug}'), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(14), decoration: _box(border: l.joined ? Wz.green.withValues(alpha: .4) : null),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        _crest(l, 50), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Flexible(child: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
            if (l.official) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: Wz.green, size: 16))]),
          const SizedBox(height: 3),
          Wrap(spacing: 10, children: [Text('${l.managers} managers', style: const TextStyle(color: Wz.muted, fontSize: 12)), if (l.clans > 0) Text('${l.clans} clans', style: const TextStyle(color: Wz.muted, fontSize: 12)), _privacy(l)]),
        ])),
      ]),
      const SizedBox(height: 10),
      Expanded(child: Text(l.desc.isEmpty ? 'No description yet.' : l.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 13, height: 1.35))),
      _ModeChips(l.modes),
      const SizedBox(height: 10),
      SizedBox(height: 38, child: l.joined
          ? OutlinedButton.icon(onPressed: () => c.go('/league/${l.slug}'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.check_rounded, size: 17), label: const Text('Joined · Open'))
          : FilledButton(onPressed: joining == l.slug ? null : () => _join(l), child: joining == l.slug ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.onPrimary)) : Text(l.public ? 'Join' : 'Request to Join'))),
    ])));
}
