import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/league.dart';

/// Clans.
/// Directory (/clans) — GET /api/app/clans → items[Clan].
/// A56 Clan Hub · A57 Members · A58 Performance · A59 Requests & Invites · A60 Settings (/clan/:slug[?tab=]) —
/// GET /api/app/clans/<slug> → {clan, members[{user_id,name,team,role,gw,avatar}], my_role, position_by_gw{gw: pos},
/// rank_pts (War Points), wins, gw_pts, chat, pending, invite_code}. Captain actions use the clan endpoints in Repo.

BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
EdgeInsets _pad(BuildContext c) => Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28);
String _ini(String s) => s.trim().isEmpty ? '?' : s.trim().substring(0, s.trim().length >= 2 ? 2 : 1).toUpperCase();
Widget _title(IconData i, Color col, String t, {Widget? trailing}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(i, color: col, size: 20), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))), if (trailing != null) trailing]));
(String, Color) _role(String r) => switch (r.toLowerCase()) { 'leader' || 'owner' || 'captain' => ('CAPTAIN', Wz.gold), 'co-leader' => ('CO-CAPTAIN', Wz.cyan), _ => ('MEMBER', Wz.muted) };

Widget _banner(BuildContext c, {required String title, required String sub, required String flourish, List<Widget> actions = const [], Widget? back}) {
  final compact = Bp.compact(c);
  return Container(clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
    Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .5)], stops: const [.4, 1])))),
    if (!compact) Positioned(right: 26, top: 22, child: Transform.rotate(angle: -.14, child: Text(flourish, textAlign: TextAlign.center, style: script(30)))),
    Padding(padding: EdgeInsets.all(compact ? 18 : 26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (back != null) ...[back, const SizedBox(height: 10)],
      Text(title, style: anton(compact ? 30 : 42, color: Colors.white, spacing: 1)),
      Text(sub, style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
      if (actions.isNotEmpty) ...[const SizedBox(height: 16), Wrap(spacing: 10, runSpacing: 10, children: actions)],
    ])),
  ]));
}

// ======================================================================================
// Clans directory
// ======================================================================================

class ClansPage extends StatefulWidget { const ClansPage({super.key}); @override State<ClansPage> createState() => _ClansState(); }
class _ClansState extends State<ClansPage> {
  String q = '', filter = 'all'; int ver = 0;

  Future<void> _create() async {
    List<League> leagues;
    try { leagues = await Repo.I.myLeagues(); } catch (e) { if (mounted) toast(context, e.toString(), error: true); return; }
    if (!mounted) return;
    if (leagues.isEmpty) { toast(context, 'Join a league first — clans live inside a league.', error: true); return; }
    final name = TextEditingController(), motto = TextEditingController(); String league = leagues.first.slug; bool open = true;
    final ok = await showDialog<bool>(context: context, builder: (d) => StatefulBuilder(builder: (d, set) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Create Clan'), content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, maxLength: 30, decoration: const InputDecoration(labelText: 'Clan name', counterText: '')), const SizedBox(height: 10),
      TextField(controller: motto, maxLength: 60, decoration: const InputDecoration(labelText: 'Motto (optional)', counterText: '')), const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: league, dropdownColor: Wz.panel2, items: [for (final l in leagues) DropdownMenuItem(value: l.slug, child: Text(l.name))], onChanged: (v) => set(() => league = v ?? league), decoration: const InputDecoration(labelText: 'League')),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: open, activeThumbColor: Wz.green, title: const Text('Open clan'), subtitle: const Text('Anyone in the league can join without approval'), onChanged: (v) => set(() => open = v)),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, name.text.trim().length >= 2), child: const Text('Create'))])));
    if (ok != true) return;
    try { final k = await Repo.I.createClan(name.text.trim(), league, motto: motto.text.trim(), open: open); if (mounted) context.go('/clan/${k.slug}'); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
  }

  @override Widget build(BuildContext c) {
    if (!Session.I.loggedIn) { return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: _pad(c), children: [
      _banner(c, title: 'CLANS', sub: 'Find your squad. Build your legacy.', flourish: 'Stronger\ntogether.', actions: [FilledButton(onPressed: () => c.go('/login'), child: const Text('Login to see clans')), OutlinedButton(onPressed: () => c.go('/register'), child: const Text('Create Account'))]),
    ]))); }
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(key: ValueKey(ver), load: () => Repo.I.clans(), builder: (c, all, _) {
      final mine = all.where((k) => k.me).toList();
      final list = all.where((k) => (q.isEmpty || k.name.toLowerCase().contains(q.toLowerCase())) && switch (filter) { 'open' => k.open, 'mine' => k.me, _ => true }).toList();
      return ListView(padding: _pad(c), children: [
        _banner(c, title: 'CLANS', sub: 'Find your squad. Build your legacy.', flourish: 'Stronger\ntogether.', actions: [
          FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add_rounded, size: 19), label: const Text('Create Clan')),
          OutlinedButton.icon(onPressed: () async { await c.push('/join'); if (mounted) setState(() => ver++); }, style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.key_rounded, size: 18), label: const Text('Join with Code')),
        ]),
        const SizedBox(height: 14),
        if (mine.isNotEmpty) ...[
          Container(padding: const EdgeInsets.all(16), decoration: _box(border: Wz.green.withValues(alpha: .4)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _title(Icons.shield_rounded, Wz.green, mine.length == 1 ? 'Your Clan' : 'Your Clans'), for (final k in mine) _row(c, k)])),
          const SizedBox(height: 14),
        ],
        TextField(onChanged: (v) => setState(() => q = v.trim()), style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'Search clans…', prefixIcon: Icon(Icons.search_rounded, color: Wz.muted))),
        const SizedBox(height: 12),
        Row(children: [for (final o in [('all', 'All', all.length), ('open', 'Open', all.where((k) => k.open).length), ('mine', 'Mine', mine.length)]) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(selected: filter == o.$1, onSelected: (_) => setState(() => filter = o.$1), showCheckmark: false, label: Text('${o.$2}  ${o.$3}'),
            labelStyle: TextStyle(color: filter == o.$1 ? Wz.onPrimary : Colors.white, fontWeight: FontWeight.w600), selectedColor: Wz.green, backgroundColor: Wz.panel, side: const BorderSide(color: Wz.border2)))]),
        const SizedBox(height: 14),
        if (list.isEmpty) Container(padding: const EdgeInsets.all(28), decoration: _box(), child: const Center(child: Text('No clans found.', style: TextStyle(color: Wz.muted))))
        else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: list.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 460, mainAxisExtent: 92, crossAxisSpacing: 12, mainAxisSpacing: 10), itemBuilder: (c, i) => _row(c, list[i], boxed: true)),
      ]);
    })));
  }

  Widget _row(BuildContext c, Clan k, {bool boxed = false}) => InkWell(onTap: () => c.go('/clan/${k.slug}'), borderRadius: BorderRadius.circular(10), child: Container(margin: EdgeInsets.only(bottom: boxed ? 0 : 6), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: boxed ? Wz.panel : Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: k.me ? Wz.green.withValues(alpha: .5) : Wz.border2)),
    child: Row(children: [
      HexAvatar(_ini(k.name), url: k.logo, size: 46, color: Wz.red), const SizedBox(width: 12),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
        Text(['${k.members}/${k.maxMembers} members', if (k.league.isNotEmpty) k.league, k.open ? 'Open' : 'Invite only'].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 12)),
        if (k.motto.isNotEmpty) Text('"${k.motto}"', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12, fontStyle: FontStyle.italic)),
      ])),
      if (k.rank != null) Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('#${k.rank}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const Text('Rank', style: TextStyle(color: Wz.muted, fontSize: 10.5))]),
      const Icon(Icons.chevron_right_rounded, color: Wz.muted),
    ])));
}

// ======================================================================================
// Clan hub
// ======================================================================================

class ClanPage extends StatefulWidget { final String slug; final String? tab; const ClanPage(this.slug, {super.key, this.tab}); @override State<ClanPage> createState() => _ClanState(); }
class _ClanState extends State<ClanPage> {
  late String tab = widget.tab ?? 'overview'; bool busy = false;

  Future<void> _do(Future<dynamic> Function() f, Future<void> Function() reload, {String? ok}) async {
    setState(() => busy = true);
    try { final r = await f(); if (mounted) toast(context, ok ?? (r is Map ? jStr(r['msg'], 'Done') : 'Done')); await reload(); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override Widget build(BuildContext c) {
    if (!Session.I.loggedIn) return Scaffold(backgroundColor: Wz.bg, body: Center(child: FilledButton(onPressed: () => c.go('/login'), child: const Text('Login to see this clan'))));
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: () => Repo.I.clan(widget.slug), builder: (c, j, reload) {
      final k = Clan.fromJson(jMap(j['clan'])); final members = jList(j['members']); final role = jStrN(j['my_role']);
      final captain = role == 'leader' || role == 'co-leader' || Session.I.isAdmin;
      final tabs = <(String, String)>[('overview', 'Overview'), ('members', 'Members'), ('performance', 'Performance'), if (captain) ('requests', 'Requests & Invites'), if (captain) ('settings', 'Settings')];
      final cur = tabs.any((t) => t.$1 == tab) ? tab : 'overview';
      final compact = Bp.compact(c);
      final chat = jBool(j['chat']) && Session.I.flag('CLAN_CHAT') && role != null;
      return ListView(padding: _pad(c), children: [
        Container(clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.red.withValues(alpha: .4)), child: Stack(children: [
          Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .95), Wz.bg.withValues(alpha: .5)], stops: const [.45, 1])))),
          if (!compact) Positioned(right: 26, top: 22, child: Transform.rotate(angle: -.14, child: Text('Same players.\nBigger stories.', textAlign: TextAlign.center, style: script(28)))),
          Padding(padding: EdgeInsets.all(compact ? 16 : 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(onTap: () => c.canPop() ? c.pop() : c.go('/clans'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70), SizedBox(width: 6), Text('Clans', style: TextStyle(color: Colors.white70, fontSize: 13))])),
            const SizedBox(height: 12),
            Row(children: [
              HexAvatar(_ini(k.name), url: k.logo, size: compact ? 60 : 84, color: Wz.red), SizedBox(width: compact ? 14 : 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: anton(compact ? 28 : 42, color: Colors.white, spacing: .6)),
                if (k.motto.isNotEmpty) Text(k.motto, style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(spacing: 14, runSpacing: 4, children: [
                  if (k.league.isNotEmpty) InkWell(onTap: k.leagueSlug.isEmpty ? null : () => c.go('/league/${k.leagueSlug}'), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.emoji_events_outlined, size: 15, color: Wz.gold), const SizedBox(width: 5), Text(k.league, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13))])),
                  Row(mainAxisSize: MainAxisSize.min, children: [Icon(k.open ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 15, color: Wz.green), const SizedBox(width: 5), Text(k.open ? 'Open clan' : 'Invite only', style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13))]),
                ]),
              ])),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _stat('${k.members}/${k.maxMembers}', 'Members', Colors.white),
              if (j['rank_pts'] != null) _stat('${j['rank_pts']}', 'War Points', Wz.red),
              if (k.rank != null) _stat('#${k.rank}', 'League Rank', Wz.gold),
              if (j['wins'] != null) _stat('${j['wins']}', 'GW Wins', Wz.green),
              if (j['gw_pts'] != null) _stat('${j['gw_pts']}', 'This GW', Wz.cyan),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              if (role == null) FilledButton.icon(onPressed: busy ? null : () => _do(() => Repo.I.joinClan(widget.slug), reload), icon: const Icon(Icons.group_add_rounded, size: 19), label: Text(k.open ? 'Join Clan' : 'Request to Join')),
              if (chat) FilledButton.icon(onPressed: () => c.push('/chat/clan/${widget.slug}'), icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18), label: const Text('Clan Chat')),
              if (k.leagueSlug.isNotEmpty) OutlinedButton.icon(onPressed: () => c.go('/league/${k.leagueSlug}/civil-war'), style: OutlinedButton.styleFrom(foregroundColor: Wz.red, side: BorderSide(color: Wz.red.withValues(alpha: .7))), icon: const Icon(Icons.close_rounded, size: 18), label: const Text('Civil War')),
              if (role != null) OutlinedButton(onPressed: busy ? null : () async {
                final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: Text('Leave ${k.name}?'), content: const Text('Your points stop counting for this clan.'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), style: FilledButton.styleFrom(backgroundColor: Wz.red, foregroundColor: Colors.white), child: const Text('Leave'))]));
                if (ok == true) await _do(() => Repo.I.leaveClan(widget.slug), reload, ok: 'You left the clan');
              }, style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Wz.border2)), child: const Text('Leave Clan')),
            ]),
          ])),
        ])),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final t in tabs) Padding(padding: const EdgeInsets.only(right: 6), child: InkWell(onTap: () => setState(() => tab = t.$1), borderRadius: BorderRadius.circular(8), child: Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center,
          decoration: BoxDecoration(color: cur == t.$1 ? Wz.green.withValues(alpha: .16) : Wz.panel, borderRadius: BorderRadius.circular(8), border: Border.all(color: cur == t.$1 ? Wz.green.withValues(alpha: .55) : Wz.border2)),
          child: Row(children: [Text(t.$2, style: TextStyle(color: cur == t.$1 ? Wz.green : Colors.white.withValues(alpha: .85), fontSize: 14, fontWeight: FontWeight.w600)), if (t.$1 == 'requests' && jInt(j['pending']) > 0) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1), decoration: BoxDecoration(color: Wz.red, borderRadius: BorderRadius.circular(10)), child: Text('${j['pending']}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))]))))])),
        const SizedBox(height: 14),
        switch (cur) {
          'members' => _members(c, members, captain: captain, leader: role == 'leader' || Session.I.isAdmin, reload: reload),
          'performance' => _performance(c, j, members),
          'requests' => _requests(c, j, reload),
          'settings' => _ClanSettings(slug: widget.slug, clan: k, leader: role == 'leader' || Session.I.isAdmin, onSaved: reload),
          _ => _overview(c, j, k, members),
        },
      ]);
    })));
  }

  Widget _stat(String v, String k, Color col) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .65), borderRadius: BorderRadius.circular(10), border: Border.all(color: col.withValues(alpha: .45))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.w700)), Text(k, style: const TextStyle(color: Wz.muted, fontSize: 11))]));

  Widget _memberRow(BuildContext c, int i, Map<String, dynamic> m, {Widget? trailing}) { final r = _role(jStr(m['role'], 'member')); return InkWell(onTap: () => c.push('/manager/${m['user_id']}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.fromLTRB(12, 9, 6, 9), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
    child: Row(children: [
      SizedBox(width: 26, child: Text('${i + 1}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))),
      HexAvatar(_ini(jStr(m['name'])), url: jStrN(m['avatar']), size: 36), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(jStr(m['team'], jStr(m['name'])), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
        Row(children: [Flexible(child: Text(jStr(m['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 12))), const SizedBox(width: 8), Text(r.$1, style: TextStyle(color: r.$2, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .6))]),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${m['gw'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const Text('GW pts', style: TextStyle(color: Wz.muted, fontSize: 10.5))]),
      trailing ?? const SizedBox(width: 8),
    ]))); }

  // A56
  Widget _overview(BuildContext c, Map<String, dynamic> j, Clan k, List<Map<String, dynamic>> members) {
    final sorted = [...members]..sort((a, b) => jInt(b['gw']).compareTo(jInt(a['gw'])));
    final list = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.groups_rounded, Wz.green, 'Members (${members.length}/${k.maxMembers})', trailing: InkWell(onTap: () => setState(() => tab = 'members'), child: const Text('See All ›', style: TextStyle(color: Wz.green, fontSize: 13, fontWeight: FontWeight.w600)))),
      if (members.isEmpty) const Text('No members yet.', style: TextStyle(color: Wz.muted)),
      for (final (i, m) in sorted.take(5).indexed) _memberRow(c, i, m),
    ]));
    final about = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.info_outline_rounded, Wz.cyan, 'About ${k.name}'),
      for (final r in [('League', k.league.isEmpty ? '—' : k.league), ('Member limit', '${k.maxMembers} players'), ('Joining', k.open ? 'Open to league members' : 'Captain approval or invite code'), ('Season total', '${k.total} FPL pts')])
        Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))), child: Row(children: [Text(r.$1, style: const TextStyle(color: Wz.muted, fontSize: 13)), const Spacer(), Flexible(child: Text(r.$2, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)))])),
      if (k.motto.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14), child: Text('"${k.motto}"', textAlign: TextAlign.center, style: script(24))),
    ]));
    return MediaQuery.of(c).size.width >= 1100 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: list), const SizedBox(width: 16), Expanded(flex: 2, child: about)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [list, const SizedBox(height: 14), about]);
  }

  // A57
  Widget _members(BuildContext c, List<Map<String, dynamic>> members, {required bool captain, required bool leader, required Future<void> Function() reload}) {
    final sorted = [...members]..sort((a, b) => jInt(b['gw']).compareTo(jInt(a['gw'])));
    return Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.groups_rounded, Wz.green, 'Members', trailing: Text('${members.length} total', style: const TextStyle(color: Wz.muted, fontSize: 12))),
      if (members.isEmpty) const Text('No members yet.', style: TextStyle(color: Wz.muted)),
      for (final (i, m) in sorted.indexed) _memberRow(c, i, m, trailing: !captain || _role(jStr(m['role'])).$1 == 'CAPTAIN' ? null : PopupMenuButton<String>(color: Wz.panel2, icon: const Icon(Icons.more_vert_rounded, color: Wz.muted), onSelected: (a) async {
        final uid = jInt(m['user_id']);
        if (a == 'kick' || a == 'transfer') {
          final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: Text(a == 'kick' ? 'Remove ${m['name']}?' : 'Make ${m['name']} captain?'), content: Text(a == 'kick' ? 'They leave the clan immediately.' : 'You will become a regular member.'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), style: FilledButton.styleFrom(backgroundColor: a == 'kick' ? Wz.red : Wz.green, foregroundColor: a == 'kick' ? Colors.white : Wz.onPrimary), child: Text(a == 'kick' ? 'Remove' : 'Transfer'))]));
          if (ok != true) return;
        }
        await _do(() => a == 'kick' ? Repo.I.clanKick(widget.slug, uid) : a == 'transfer' ? Repo.I.clanTransfer(widget.slug, uid) : Repo.I.clanRole(widget.slug, uid, a), reload, ok: 'Updated');
      }, itemBuilder: (_) => [
        const PopupMenuItem(value: 'co-leader', child: Text('Make co-captain')), const PopupMenuItem(value: 'member', child: Text('Make member')),
        if (leader) const PopupMenuItem(value: 'transfer', child: Text('Transfer captaincy')),
        const PopupMenuItem(value: 'kick', child: Text('Remove from clan', style: TextStyle(color: Wz.red))),
      ])),
    ]));
  }

  // A58
  Widget _performance(BuildContext c, Map<String, dynamic> j, List<Map<String, dynamic>> members) {
    final pos = jMap(j['position_by_gw']); final gws = pos.keys.map(int.tryParse).whereType<int>().toList()..sort();
    final worst = gws.fold<int>(1, (m, g) => jInt(pos['$g']) > m ? jInt(pos['$g']) : m);
    final total = members.fold<int>(0, (s, m) => s + jInt(m['gw']));
    final chart = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.show_chart_rounded, Wz.cyan, 'Gameweek Position'),
      if (gws.isEmpty) const Text('No finished gameweeks yet.', style: TextStyle(color: Wz.muted))
      else ...[
        SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [for (final g in gws) () { final p = jInt(pos['$g']);
          return Expanded(child: Tooltip(message: 'GW $g: position $p', child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('#$p', style: TextStyle(color: p == 1 ? Wz.gold : Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)), const SizedBox(height: 3),
            Container(height: 100 * (worst - p + 1) / worst + 4, decoration: BoxDecoration(color: p == 1 ? Wz.gold : Wz.red.withValues(alpha: .7), borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
            const SizedBox(height: 4), Text('$g', style: const TextStyle(color: Wz.muted, fontSize: 10.5)),
          ])))); }()])),
        const SizedBox(height: 8), const Text('Taller bar = better position. Gold = the clan won that gameweek.', style: TextStyle(color: Wz.muted, fontSize: 12)),
      ],
    ]));
    final contrib = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.pie_chart_outline_rounded, Wz.green, 'This Gameweek', trailing: Text('$total pts', style: const TextStyle(color: Wz.green, fontWeight: FontWeight.w700))),
      for (final m in [...members]..sort((a, b) => jInt(b['gw']).compareTo(jInt(a['gw'])))) Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(jStr(m['name']), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5))), Text('${m['gw'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: total == 0 ? 0 : jInt(m['gw']) / total, minHeight: 5, color: Wz.green, backgroundColor: Wz.border2)),
      ])),
    ]));
    return MediaQuery.of(c).size.width >= 1100 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: chart), const SizedBox(width: 16), Expanded(flex: 2, child: contrib)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chart, const SizedBox(height: 14), contrib]);
  }

  // A59
  Widget _requests(BuildContext c, Map<String, dynamic> j, Future<void> Function() reload) {
    final code = jStrN(j['invite_code']);
    final invite = Container(padding: const EdgeInsets.all(16), decoration: _box(border: Wz.green.withValues(alpha: .4)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.key_rounded, Wz.green, 'Invite Code'),
      if (code != null) InkWell(onTap: () { Clipboard.setData(ClipboardData(text: code)); toast(c, 'Code copied'); }, borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: Wz.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.green)),
        child: Row(children: [Text(code, style: anton(26, color: Colors.white, spacing: 5)), const Spacer(), const Icon(Icons.copy_rounded, color: Wz.green, size: 20)])))
      else const Text('No invite code yet.', style: TextStyle(color: Wz.muted)),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: busy ? null : () => _do(() => Repo.I.codeCreate(clan: widget.slug), reload, ok: 'New invite code created'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Create New Code')),
      const SizedBox(height: 8), const Text('Share the code — members enter it under Leagues → Join with Code.', style: TextStyle(color: Wz.muted, fontSize: 12.5)),
    ]));
    final reqs = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Async(load: () => Repo.I.clanRequests(widget.slug), builder: (c, rs, rel) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title(Icons.how_to_reg_outlined, Wz.green, 'Join Requests', trailing: Text('${rs.length} pending', style: const TextStyle(color: Wz.muted, fontSize: 12))),
      if (rs.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No pending requests.', style: TextStyle(color: Wz.muted)))),
      for (final r in rs) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Row(children: [
        HexAvatar(_ini(jStr(r['name'])), url: jStrN(r['avatar']), size: 38), const SizedBox(width: 12),
        Expanded(child: Text(jStr(r['name']), style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600))),
        IconButton.filled(onPressed: busy ? null : () async { await _do(() => Repo.I.clanRequestAction(widget.slug, jInt(r['id']), true), reload, ok: 'Approved'); }, tooltip: 'Approve', style: IconButton.styleFrom(backgroundColor: Wz.green, foregroundColor: Wz.onPrimary), icon: const Icon(Icons.check_rounded)),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: busy ? null : () async { await _do(() => Repo.I.clanRequestAction(widget.slug, jInt(r['id']), false), reload, ok: 'Rejected'); }, tooltip: 'Reject', style: IconButton.styleFrom(backgroundColor: Wz.red.withValues(alpha: .2), foregroundColor: Wz.red), icon: const Icon(Icons.close_rounded)),
      ])),
    ])));
    return MediaQuery.of(c).size.width >= 1100 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: reqs), const SizedBox(width: 16), Expanded(flex: 2, child: invite)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [invite, const SizedBox(height: 14), reqs]);
  }
}

// A60
class _ClanSettings extends StatefulWidget { final String slug; final Clan clan; final bool leader; final Future<void> Function() onSaved; const _ClanSettings({required this.slug, required this.clan, required this.leader, required this.onSaved}); @override State<_ClanSettings> createState() => _ClanSettingsState(); }
class _ClanSettingsState extends State<_ClanSettings> {
  late final name = TextEditingController(text: widget.clan.name), motto = TextEditingController(text: widget.clan.motto); late bool open = widget.clan.open; bool busy = false;
  @override void dispose() { name.dispose(); motto.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (name.text.trim().length < 2) { toast(context, 'Clan name is too short.', error: true); return; }
    setState(() => busy = true);
    try { await Repo.I.clanSettings(widget.slug, {'name': name.text.trim(), 'motto': motto.text.trim(), 'open': open}); if (mounted) toast(context, 'Clan settings saved'); await widget.onSaved(); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Container(padding: const EdgeInsets.all(18), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('General Information', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 14),
      const Text('Clan Name', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
      TextField(controller: name, maxLength: 30, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(counterText: '')), const SizedBox(height: 12),
      const Text('Motto', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
      TextField(controller: motto, maxLength: 60, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'Legends never retire', counterText: '')), const SizedBox(height: 12),
      Container(padding: const EdgeInsets.fromLTRB(14, 8, 6, 8), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Open clan', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)), Text('League members can join without approval.', style: TextStyle(color: Wz.muted, fontSize: 12.5))])),
        Switch(value: open, onChanged: (v) => setState(() => open = v), activeThumbColor: Colors.white, activeTrackColor: Wz.green, inactiveThumbColor: Colors.white, inactiveTrackColor: Wz.border2, trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent))])),
      const SizedBox(height: 16),
      Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: busy ? null : _save, icon: const Icon(Icons.save_rounded, size: 18), label: Text(busy ? 'Saving…' : 'Save Changes'))),
    ])),
    if (widget.leader) ...[const SizedBox(height: 14), Container(padding: const EdgeInsets.all(18), decoration: _box(border: Wz.red.withValues(alpha: .5)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Danger Zone', style: TextStyle(color: Wz.red, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 6),
      const Text('Dissolving a clan removes every member and cannot be undone.', style: TextStyle(color: Wz.muted, fontSize: 13)), const SizedBox(height: 12),
      OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Wz.red, side: const BorderSide(color: Wz.red)), icon: const Icon(Icons.delete_forever_rounded, size: 19), label: const Text('Dissolve Clan'), onPressed: () async {
        final t = TextEditingController();
        final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: Text('Dissolve ${widget.clan.name}?'), content: TextField(controller: t, autofocus: true, decoration: const InputDecoration(labelText: 'Type DISSOLVE to confirm')), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, t.text.trim() == 'DISSOLVE'), style: FilledButton.styleFrom(backgroundColor: Wz.red, foregroundColor: Colors.white), child: const Text('Dissolve'))]));
        if (ok != true) return;
        try { await Repo.I.clanDissolve(widget.slug); if (c.mounted) c.go('/clans'); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); }
      }),
    ]))],
  ]);
}
