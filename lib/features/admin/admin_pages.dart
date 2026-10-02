import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/brand.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import 'admin_repo.dart';

/// Admin panel (/admin/*) — its own shell, separate from the player-facing app shell.
/// Every screen talks to /api/admin/* through [AdminRepo] (g = GET, p = POST, d = DELETE, raw = POST returning JSON).

const _sections = [('/admin', 'Dashboard', Icons.dashboard_outlined), ('/admin/leagues', 'Leagues', Icons.emoji_events_outlined), ('/admin/users', 'Users', Icons.people_outline_rounded), ('/admin/clans', 'Clans', Icons.groups_outlined), ('/admin/hof', 'Hall of Fame', Icons.military_tech_outlined), ('/admin/live', 'Live', Icons.sensors_rounded), ('/admin/api', 'API Center', Icons.api_rounded), ('/admin/branding', 'Branding', Icons.palette_outlined), ('/admin/logs', 'Logs & Backups', Icons.receipt_long_outlined), ('/admin/settings', 'Settings', Icons.settings_outlined), ('/admin/broadcast', 'Broadcast', Icons.campaign_outlined)];
const _accent = Wz.purple2;
const _labels = {'name': 'Name', 'prize': 'Prize', 'desc': 'Description', 'start_gw': 'Start gameweek', 'surv_round_len': 'Survivor: gameweeks per round', 'surv_drop': 'Survivor: out per round', 'owner_email': 'Owner email', 'clan_size': 'Clan size (4–10)', 'players': 'Players (6–40, 0 = clear)',
  'league': 'League slug', 'rows': 'Rows (one per line)', 'email': 'Email', 'password': 'Password', 'team': 'Team name', 'fpl_id': 'FPL ID', 'role': 'Role (user / admin)', 'status': 'Status', 'code': 'Code', 'motto': 'Motto', 'season': 'Season', 'mode': 'Mode', 'champ': 'Champion', 'pts': 'Points',
  'min': 'Minute', 'hs': 'Home score', 'as': 'Away score', 'provider': 'Provider', 'host': 'Host', 'key': 'API key', 'enabled': 'Enabled (1 / 0)', 'path': 'Path', 'rapid_ep_fixtures': 'Fixtures path', 'rapid_ep_events': 'Events path', 'rapid_ep_lineups': 'Lineups path', 'brand_name': 'Brand name', 'brand_tagline': 'Tagline', 'hero_headline': 'Hero headline', 'hero_sub': 'Hero sub-line', 'hero_note': 'Hero note',
  'maintenance': 'Maintenance mode (1 / 0)', 'maintenance_msg': 'Maintenance message', 'google_client_id': 'Google client ID', 'google_client_secret': 'Google client secret (blank = keep)', 'current': 'Current password'};

Future<void> act(BuildContext c, Future<AdminResult> Function() f, [Future<void> Function()? reload]) async {
  try {
    final r = await f(); if (!c.mounted) return;
    for (final m in r.messages) { toast(c, m.$2, error: m.$1 == 'danger'); }
    if (r.messages.isEmpty) toast(c, r.ok ? 'Done' : 'Failed', error: !r.ok);
    if (reload != null) await reload();
  } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); }
}
Future<bool> confirmTyped(BuildContext c, String title, String word) async { final t = TextEditingController(); return (await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: Text(title), content: TextField(controller: t, autofocus: true, decoration: InputDecoration(labelText: 'Type $word to confirm')), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Wz.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(d, t.text.trim() == word), child: const Text('Confirm'))]))) ?? false; }
Future<Map<String, String>?> form(BuildContext c, String title, Map<String, String> fields) async {
  final ctrls = {for (final e in fields.entries) e.key: TextEditingController(text: e.value)};
  final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: Text(title), content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final e in ctrls.entries) Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: e.value, obscureText: e.key == 'password' || e.key == 'current', maxLines: e.key == 'rows' || e.key == 'rules_text' || e.key == 'desc' ? 5 : 1, decoration: InputDecoration(labelText: _labels[e.key] ?? e.key)))]))), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save'))]));
  return ok == true ? {for (final e in ctrls.entries) e.key: e.value.text} : null;
}

BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
Widget _card(List<Widget> children, {Color? border, EdgeInsets margin = const EdgeInsets.only(bottom: 12)}) => Container(margin: margin, padding: const EdgeInsets.all(16), decoration: _box(border: border), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
Widget _h(String t, {Widget? trailing}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))), if (trailing != null) trailing]));
Widget _pill(String t, Color col) => Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: col.withValues(alpha: .14), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withValues(alpha: .55))), child: Text(t, style: TextStyle(color: col, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .6)));
Widget _btn(String t, VoidCallback on, {Color? color, IconData? icon}) => OutlinedButton.icon(onPressed: on, style: OutlinedButton.styleFrom(foregroundColor: color ?? Colors.white, side: BorderSide(color: (color ?? Wz.border2).withValues(alpha: color == null ? 1 : .6)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), visualDensity: VisualDensity.compact), icon: Icon(icon ?? Icons.chevron_right_rounded, size: 16), label: Text(t, style: const TextStyle(fontSize: 13)));
Widget _stat(String k, String v, {Color color = Colors.white}) => Container(width: 168, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)), Text(k, style: const TextStyle(color: Wz.muted, fontSize: 12))]));
Widget _log(Map<String, dynamic> l) { final lvl = jStr(l['lvl']); return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('${l['t']}  [$lvl]  ${l['msg']}', style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: lvl == 'ERROR' ? Wz.red : lvl == 'WARN' ? Wz.gold : Wz.muted))); }
Widget _empty(String t) => Padding(padding: const EdgeInsets.all(18), child: Center(child: Text(t, style: const TextStyle(color: Wz.muted))));

/// Page frame: title, subtitle, actions, scrolling body.
class _Page extends StatelessWidget {
  final String title, sub; final List<Widget> actions; final List<Widget> children;
  const _Page({required this.title, required this.sub, this.actions = const [], required this.children});
  @override Widget build(BuildContext c) => ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 14, 14, 24) : const EdgeInsets.fromLTRB(24, 22, 24, 28), children: [
    Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.end, runSpacing: 10, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title.toUpperCase(), style: anton(Bp.compact(c) ? 28 : 36, color: Colors.white, spacing: 1)), Text(sub, style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w600))]),
      if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
    ]),
    const SizedBox(height: 16), ...children,
  ]);
}

/// Admin shell: sidebar on wide screens, drawer on phones. Admin-only.
class AdminShell extends StatelessWidget {
  final Widget child; final String location; const AdminShell({super.key, required this.child, required this.location});
  @override Widget build(BuildContext c) {
    if (!Session.I.isAdmin) return Scaffold(backgroundColor: Wz.bg, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.lock_outline_rounded, color: _accent, size: 40), const SizedBox(height: 12), const Text('Admins only', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 14), FilledButton(onPressed: () => c.go(Session.I.loggedIn ? '/home' : '/login'), child: Text(Session.I.loggedIn ? 'Back to FFW' : 'Login'))])));
    final compact = MediaQuery.of(c).size.width < 950;
    Widget nav(BuildContext c) => Container(color: Wz.panel, child: ListView(padding: const EdgeInsets.fromLTRB(12, 18, 12, 16), children: [
      const Padding(padding: EdgeInsets.fromLTRB(8, 0, 8, 4), child: FfwWordmark(height: 22, full: false)),
      const Padding(padding: EdgeInsets.fromLTRB(8, 4, 8, 14), child: Row(children: [Icon(Icons.admin_panel_settings_outlined, color: _accent, size: 18), SizedBox(width: 6), Text('ADMIN PANEL', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.6))])),
      for (final s in _sections) () { final on = s.$1 == '/admin' ? location == '/admin' : location.startsWith(s.$1);
        return Padding(padding: const EdgeInsets.only(bottom: 2), child: InkWell(onTap: () { if (compact) Navigator.of(c).maybePop(); c.go(s.$1); }, borderRadius: BorderRadius.circular(8), child: Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: on ? _accent.withValues(alpha: .16) : null, borderRadius: BorderRadius.circular(8), border: on ? Border.all(color: _accent.withValues(alpha: .5)) : null),
          child: Row(children: [Icon(s.$3, size: 20, color: on ? _accent : Colors.white70), const SizedBox(width: 12), Text(s.$2, style: TextStyle(color: on ? _accent : Colors.white.withValues(alpha: .9), fontSize: 14, fontWeight: on ? FontWeight.w600 : FontWeight.w500))])))); }(),
      const Divider(color: Wz.border2, height: 22),
      InkWell(onTap: () => c.go('/home'), borderRadius: BorderRadius.circular(8), child: const SizedBox(height: 42, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Icon(Icons.arrow_back_rounded, size: 20, color: Wz.green), SizedBox(width: 12), Text('Back to FFW', style: TextStyle(color: Wz.green, fontSize: 14, fontWeight: FontWeight.w600))])))),
    ]));
    if (compact) { return Scaffold(backgroundColor: Wz.bg, drawer: Drawer(backgroundColor: Wz.panel, child: Builder(builder: nav)), body: SafeArea(child: Builder(builder: (c) => Column(children: [
      Container(height: 52, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))), child: Row(children: [IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: () => Scaffold.of(c).openDrawer()), const Icon(Icons.admin_panel_settings_outlined, color: _accent, size: 18), const SizedBox(width: 6), const Text('ADMIN PANEL', style: TextStyle(color: _accent, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 1.4))])),
      Expanded(child: child)])))); }
    return Scaffold(backgroundColor: Wz.bg, body: Row(children: [SizedBox(width: 236, child: nav(c)), const VerticalDivider(width: 1, color: Wz.border), Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1300), child: child)))]));
  }
}

class AdminDashboard extends StatelessWidget { const AdminDashboard({super.key});
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('dashboard'), builder: (c, j, reload) { final k = jMap(j['counts']); final sy = jMap(j['sync']);
    return _Page(title: 'Dashboard', sub: 'Gameweek ${j['gw'] ?? '–'}${jBool(j['gw_finished']) ? ' · finished' : ''}', actions: [
      PopupMenuButton<String>(color: Wz.panel2, onSelected: (w) async { try { final r = await AdminRepo.I.raw('sync', {'what': w}); if (c.mounted) toast(c, 'Synced ${r['what']} · GW${r['gw']}'); await reload(); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); } },
        itemBuilder: (_) => [for (final w in const ['all', 'bootstrap', 'fixtures', 'managers', 'live']) PopupMenuItem(value: w, child: Text('Sync $w'))],
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Wz.green, borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.sync_rounded, size: 18, color: Wz.onPrimary), SizedBox(width: 8), Text('Sync Now', style: TextStyle(color: Wz.onPrimary, fontWeight: FontWeight.w700)), Icon(Icons.arrow_drop_down_rounded, color: Wz.onPrimary)]))),
    ], children: [
      Wrap(spacing: 10, runSpacing: 10, children: [_stat('Users', '${k['users'] ?? 0}'), _stat('Leagues', '${k['leagues'] ?? 0}'), _stat('Clans', '${k['clans'] ?? 0}'), _stat('FPL linked', '${k['linked'] ?? 0}', color: Wz.green), _stat('Pending requests', '${k['pending'] ?? 0}', color: Wz.gold)]),
      const SizedBox(height: 14),
      _card([_h('Sync Status'), if (sy.isEmpty) const Text('No sync information.', style: TextStyle(color: Wz.muted)), for (final e in sy.entries) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 130, child: Text(e.key, style: const TextStyle(color: Wz.muted, fontSize: 13))), Expanded(child: Text('${e.value}', style: const TextStyle(color: Colors.white, fontSize: 13)))]))]),
      _card([_h('APIs', trailing: TextButton(onPressed: () => c.go('/admin/api'), child: const Text('API Center ›'))), for (final a in jList(j['apis'])) _apiRow(a)]),
      _card([_h('Recent Logs', trailing: TextButton(onPressed: () => c.go('/admin/logs'), child: const Text('All Logs ›'))), if (jList(j['logs']).isEmpty) const Text('No log entries.', style: TextStyle(color: Wz.muted)), for (final l in jList(j['logs'])) _log(l)]),
    ]); });
}
Widget _apiRow(Map<String, dynamic> a) { final ok = const ['ok', 'up', 'healthy', 'online'].contains(jStr(a['status']).toLowerCase());
  return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? Wz.green : Wz.gold)), const SizedBox(width: 10), Expanded(child: Text(jStr(a['name']), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
    Text([jStr(a['status']), if (a['latency'] != null) '${a['latency']} ms', if (a['last'] != null) 'last ${a['last']}', if (a['quota'] != null) '${a['quota']}'].join(' · '), style: const TextStyle(color: Wz.muted, fontSize: 12.5))])); }

class AdminLeagues extends StatelessWidget { const AdminLeagues({super.key});
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('leagues'), builder: (c, j, reload) { final items = jList(j['items']);
    return _Page(title: 'Leagues', sub: '${items.length} leagues', children: [
      if (items.isEmpty) _card([_empty('No leagues yet.')]),
      for (final l in items) _card([
        Row(children: [Expanded(child: Text(jStr(l['name']), style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700))), if (jBool(l['locked'])) _pill('LOCKED', Wz.red), _pill(jBool(l['public']) ? 'PUBLIC' : 'PRIVATE', jBool(l['public']) ? Wz.green : Wz.muted)]),
        const SizedBox(height: 6),
        Wrap(spacing: 16, runSpacing: 4, children: [for (final t in ['${l['members']} members', '${l['pending']} pending', 'Owner ${l['owner']}', 'Code ${l['join_code']}', 'Modes: ${(l['modes'] as List? ?? const []).join(', ')}', 'Civil War size ${l['cw_clan_size']}', 'Survivor ${l['surv_round_len']} GW / ${l['surv_drop']} out${jBool(l['surv_schedule']) ? ' (auto schedule)' : ''}']) Text(t, style: const TextStyle(color: Wz.muted, fontSize: 12.5))]),
        if (jList(l['overrides']).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Elimination overrides: ${jList(l['overrides']).map((o) => '${o['name']} → R${o['round']}').join(', ')}', style: const TextStyle(color: Wz.gold, fontSize: 12.5))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _btn('Edit', icon: Icons.edit_outlined, () async { final f = await form(c, 'Edit league', {'name': jStr(l['name']), 'prize': jStr(l['prize']), 'desc': jStr(l['desc']), 'start_gw': '${l['start_gw']}', 'surv_round_len': '${l['surv_round_len']}', 'surv_drop': '${l['surv_drop']}', 'owner_email': jStr(l['owner_email'])}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('leagues/${l['id']}/edit', f), reload); }),
          _btn(jBool(l['locked']) ? 'Unlock' : 'Lock', icon: jBool(l['locked']) ? Icons.lock_open_rounded : Icons.lock_outline_rounded, () => act(c, () => AdminRepo.I.p('leagues/${l['id']}/${jBool(l['locked']) ? 'unlock' : 'lock'}'), reload)),
          _btn('Modes', icon: Icons.sports_mma_rounded, () async { final ms = (l['modes'] as List? ?? const []).map((e) => e.toString()).toList(); final sel = {'ranking': ms.contains('Ranking'), 'civil_war': ms.contains('Civil War'), 'last_survivor': ms.contains('Last Survivor'), 'head_to_head': ms.contains('Head to Head')}; const names = {'ranking': 'Ranking', 'civil_war': 'Civil War', 'last_survivor': 'Last Survivor', 'head_to_head': 'Head to Head'};
            final ok = await showDialog<bool>(context: c, builder: (d) => StatefulBuilder(builder: (d, set) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Game modes'), content: Column(mainAxisSize: MainAxisSize.min, children: [for (final k in sel.keys) CheckboxListTile(value: sel[k], title: Text(names[k]!), activeColor: Wz.green, onChanged: (v) => set(() => sel[k] = v ?? false))]), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save'))])));
            if (ok == true && c.mounted) act(c, () => AdminRepo.I.p('leagues/${l['id']}/modes', sel), reload); }),
          _btn('Civil War size', icon: Icons.groups_outlined, () async { final f = await form(c, 'Civil War clan size', {'clan_size': '${l['cw_clan_size']}'}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('leagues/${l['id']}/civil-war', {'clan_size': int.tryParse(f['clan_size']!) ?? 4}), reload); }),
          _btn('Survivor schedule', icon: Icons.view_timeline_outlined, () async { final f = await form(c, 'Survivor auto-schedule', {'players': '17'}); if (f != null && c.mounted) { final n = int.tryParse(f['players']!) ?? 0; act(c, () => AdminRepo.I.p('leagues/${l['id']}/survivor-schedule', n == 0 ? {'clear': true} : {'players': n}), reload); } }),
          _btn('Override elimination', icon: Icons.gavel_rounded, color: Wz.gold, () => _override(c, l, reload)),
          _btn('Delete', icon: Icons.delete_outline_rounded, color: Wz.red, () async { if (await confirmTyped(c, 'Delete ${l['name']}?', 'DELETE') && c.mounted) act(c, () => AdminRepo.I.p('leagues/${l['id']}/delete'), reload); }),
        ]),
      ]),
    ]); });
  Future<void> _override(BuildContext c, Map<String, dynamic> l, Future<void> Function() reload) async {
    Map<String, dynamic> st; try { st = await AdminRepo.I.g('survivor/${l['slug']}'); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); return; }
    if (!c.mounted) return; final alive = jList(st['alive']); int? uid; final rd = TextEditingController(text: '${jList(st['rounds']).length}'), note = TextEditingController();
    final ok = await showDialog<bool>(context: c, builder: (d) => StatefulBuilder(builder: (d, set) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Survivor elimination override'), content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Marks a manager as eliminated in a round. The correction is recorded with your note.', style: TextStyle(color: Wz.muted, fontSize: 12.5)), const SizedBox(height: 10),
      DropdownButtonFormField<int>(initialValue: uid, dropdownColor: Wz.panel2, items: [for (final a in alive) DropdownMenuItem(value: jInt(a['user_id']), child: Text(jStr(a['team'])))], onChanged: (v) => set(() => uid = v), decoration: const InputDecoration(labelText: 'Manager')), const SizedBox(height: 10),
      TextField(controller: rd, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Out in round')), const SizedBox(height: 10), TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (reason)')), const SizedBox(height: 6),
      for (final o in jList(l['overrides'])) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text('${o['name']} → Round ${o['round']}'), trailing: IconButton(tooltip: 'Remove override', icon: const Icon(Icons.close_rounded, color: Wz.red), onPressed: () { Navigator.pop(d, false); act(c, () => AdminRepo.I.p('survivor/${l['slug']}/eliminate', {'remove': o['user_id']}), reload); })),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, uid != null), style: FilledButton.styleFrom(backgroundColor: Wz.gold, foregroundColor: Wz.bg), child: const Text('Mark Out'))])));
    if (ok == true && c.mounted) act(c, () => AdminRepo.I.p('survivor/${l['slug']}/eliminate', {'user_id': uid, 'round': int.tryParse(rd.text) ?? 1, 'note': note.text}), reload);
  }
}

class AdminUsers extends StatefulWidget { const AdminUsers({super.key}); @override State<AdminUsers> createState() => _AdminUsersState(); }
class _AdminUsersState extends State<AdminUsers> {
  String q = ''; bool unclaimed = false; int page = 1, ver = 0;
  Future<void> _bump() async => setState(() => ver++);
  @override Widget build(BuildContext c) => Async(key: ValueKey(ver), load: () => AdminRepo.I.g('users', {'q': q, 'page': page, if (unclaimed) 'unclaimed': '1'}), builder: (c, j, reload) { final items = jList(j['items']);
    return _Page(title: 'Users', sub: '${j['total'] ?? items.length} users', actions: [
      _btn('Import managers', icon: Icons.upload_file_rounded, () async { String slug = ''; try { slug = (await Repo.I.directory()).firstOrNull?.slug ?? ''; } catch (_) {} if (!c.mounted) return; final f = await form(c, 'Import managers — Name, FPL ID[, Team] per line', {'league': slug, 'rows': ''}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('users/import', {...f, 'sync': true}), _bump); }),
      FilledButton.icon(onPressed: () async { final f = await form(c, 'Create user', {'name': '', 'email': '', 'password': '', 'team': '', 'fpl_id': ''}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('users/create', f), _bump); }, icon: const Icon(Icons.person_add_alt_1_rounded, size: 18), label: const Text('Create User')),
    ], children: [
      Row(children: [Expanded(child: TextField(onSubmitted: (v) => setState(() { q = v.trim(); page = 1; ver++; }), textInputAction: TextInputAction.search, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded, color: Wz.muted), hintText: 'Search name, email, team or FPL ID', isDense: true))), const SizedBox(width: 10),
        FilterChip(label: const Text('Unclaimed'), selected: unclaimed, showCheckmark: false, selectedColor: _accent, labelStyle: TextStyle(color: unclaimed ? Wz.bg : Colors.white, fontWeight: FontWeight.w600), backgroundColor: Wz.panel, side: const BorderSide(color: Wz.border2), onSelected: (v) => setState(() { unclaimed = v; page = 1; ver++; }))]),
      const SizedBox(height: 12),
      if (items.isEmpty) _card([_empty('No users match.')]),
      for (final u in items) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(12, 10, 4, 10), decoration: _box(), child: Row(children: [
        HexAvatar(jStr(u['name']).isEmpty ? '?' : jStr(u['name']).substring(0, 1).toUpperCase(), url: jStrN(u['avatar']), size: 38, color: jStr(u['role']) == 'admin' ? _accent : Wz.green), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Flexible(child: Text('${u['name']}${jStr(u['team']).isEmpty ? '' : ' · ${u['team']}'}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600))), if (jStr(u['role']) == 'admin') _pill('ADMIN', _accent), if (jStr(u['status']) == 'banned') _pill('BANNED', Wz.red), if (jBool(u['unclaimed'])) _pill('UNCLAIMED', Wz.gold)]),
          Text([jStr(u['email']), 'FPL ${u['fpl'] ?? '–'}', if ((u['leagues'] as List? ?? const []).isNotEmpty) (u['leagues'] as List).join(', ')].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 12)),
        ])),
        PopupMenuButton<String>(color: Wz.panel2, icon: const Icon(Icons.more_vert_rounded, color: Wz.muted), onSelected: (a) async {
          if (a == 'edit') { final f = await form(c, 'Edit user', {'name': jStr(u['name']), 'team': jStr(u['team']), 'email': jStr(u['email']), 'role': jStr(u['role']), 'status': jStr(u['status']), 'fpl_id': jStr(u['fpl'])}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('users/${u['id']}/edit', f), reload); }
          else if (a == 'delete') { if (await confirmTyped(c, 'Delete ${u['email']}?', 'DELETE') && c.mounted) act(c, () => AdminRepo.I.p('users/${u['id']}/delete'), reload); }
          else { act(c, () => AdminRepo.I.p('users/${u['id']}/$a'), reload); } },
          itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), const PopupMenuItem(value: 'sync', child: Text('Sync FPL')), PopupMenuItem(value: jStr(u['status']) == 'banned' ? 'unban' : 'ban', child: Text(jStr(u['status']) == 'banned' ? 'Unban' : 'Ban')), const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Wz.red)))]),
      ])),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: page > 1 ? () => setState(() { page--; ver++; }) : null, icon: const Icon(Icons.chevron_left_rounded)), Text('Page ${j['page'] ?? page} of ${j['pages'] ?? 1}', style: const TextStyle(color: Colors.white70)), IconButton(onPressed: jInt(j['page'], page) < jInt(j['pages'], 1) ? () => setState(() { page++; ver++; }) : null, icon: const Icon(Icons.chevron_right_rounded))]),
    ]); });
}

class AdminClans extends StatelessWidget { const AdminClans({super.key});
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('clans'), builder: (c, j, reload) { final items = jList(j['items']);
    return _Page(title: 'Clans', sub: '${items.length} clans', actions: [
      _btn('Import clans', icon: Icons.upload_file_rounded, () async { String slug = ''; try { slug = (await Repo.I.directory()).firstOrNull?.slug ?? ''; } catch (_) {} if (!c.mounted) return; final f = await form(c, 'Import clans — "# Clan" then Name, FPL ID[, Captain] per line', {'league': slug, 'rows': ''}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('clans/import', f), reload); }),
    ], children: [
      if (items.isEmpty) _card([_empty('No clans yet.')]),
      for (final k in items) _card([
        Row(children: [Expanded(child: Text(jStr(k['name']), style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700))), _pill(jStr(k['league']), Wz.gold), _pill(jBool(k['open']) ? 'OPEN' : 'INVITE ONLY', jBool(k['open']) ? Wz.green : Wz.muted)]),
        const SizedBox(height: 6),
        Text('Captain ${k['leader']} · ${k['members']} members · ${k['pts']} pts', style: const TextStyle(color: Wz.muted, fontSize: 12.5)),
        if (jList(k['member_list']).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(jList(k['member_list']).map((m) => jStr(m['name'])).join(', '), style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 13))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _btn('Edit', icon: Icons.edit_outlined, () async { final f = await form(c, 'Edit clan', {'name': jStr(k['name']), 'code': jStr(k['code']), 'motto': jStr(k['motto']), 'league': jStr(k['league_slug'])}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('clans/${k['id']}/edit', {...f, 'open': jBool(k['open'])}), reload); }),
          _btn('Transfer captain', icon: Icons.swap_horiz_rounded, () async { final f = await form(c, 'Transfer captaincy to', {'email': ''}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('clans/${k['id']}/transfer', f), reload); }),
          _btn('Dissolve', icon: Icons.delete_outline_rounded, color: Wz.red, () async { if (await confirmTyped(c, 'Dissolve ${k['name']}?', 'DISSOLVE') && c.mounted) act(c, () => AdminRepo.I.p('clans/${k['id']}/delete'), reload); }),
        ]),
      ]),
    ]); });
}

class AdminHof extends StatelessWidget { const AdminHof({super.key});
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('hof'), builder: (c, j, reload) { final items = jList(j['items']);
    return _Page(title: 'Hall of Fame', sub: '${items.length} entries', actions: [
      FilledButton.icon(onPressed: () async { final f = await form(c, 'Add Hall of Fame entry', {'season': '2025/26', 'mode': 'Ranking', 'champ': '', 'name': '', 'pts': '0', 'league': ''}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('hof', f), reload); }, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add Entry')),
    ], children: [
      if (items.isEmpty) _card([_empty('No entries yet.')]),
      for (final h in items) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(14, 10, 4, 10), decoration: _box(border: jBool(h['published']) ? Wz.gold.withValues(alpha: .4) : null), child: Row(children: [
        Icon(Icons.emoji_events_rounded, color: jBool(h['published']) ? Wz.gold : Wz.faint), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Flexible(child: Text(jStr(h['champ']), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))), _pill('${h['mode']}', Wz.cyan), _pill('${h['season']}', Wz.gold), if (!jBool(h['published'])) _pill('HIDDEN', Wz.muted)]),
          Text([jStr(h['name']), '${h['pts']} pts', jStr(h['league'])].where((x) => x.isNotEmpty).join(' · '), style: const TextStyle(color: Wz.muted, fontSize: 12.5)),
        ])),
        IconButton(tooltip: jBool(h['published']) ? 'Hide' : 'Publish', icon: Icon(jBool(h['published']) ? Icons.visibility_rounded : Icons.visibility_off_outlined, color: Colors.white70), onPressed: () => act(c, () => AdminRepo.I.p('hof/${h['id']}/toggle'), reload)),
        IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline_rounded, color: Wz.red), onPressed: () async { if (await confirmTyped(c, 'Delete this entry?', 'DELETE') && c.mounted) act(c, () => AdminRepo.I.p('hof/${h['id']}/delete'), reload); }),
      ])),
    ]); });
}

class AdminLive extends StatelessWidget { const AdminLive({super.key});
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('live'), poll: const Duration(seconds: 30), builder: (c, j, reload) { final ms = jList(j['matches']);
    return _Page(title: 'Live Matches', sub: '${ms.where((m) => jStr(m['status']) == 'live').length} live · ${ms.length} matches', actions: [
      FilledButton.icon(onPressed: () => act(c, () => AdminRepo.I.p('live/refresh'), reload), icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Refresh from provider')),
    ], children: [
      if (ms.isEmpty) _card([_empty('No matches in the current gameweek.')]),
      for (final m in ms) () { final st = jStr(m['status']); final live = st == 'live';
        return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(14, 10, 10, 10), decoration: _box(border: live ? Wz.red.withValues(alpha: .5) : null), child: Row(children: [
          Expanded(child: Text('${m['hn']}  ${m['hs'] ?? '–'} – ${m['as'] ?? '–'}  ${m['an']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
          _pill(live ? "LIVE ${m['min']}'" : st == 'ft' ? 'FT' : 'UPCOMING', live ? Wz.red : st == 'ft' ? Wz.muted : Wz.green), const SizedBox(width: 10),
          _btn('Override', icon: Icons.tune_rounded, color: Wz.gold, () async { final f = await form(c, 'Override ${m['hn']} v ${m['an']} (status: up / live / ft)', {'status': live ? 'live' : st == 'ft' ? 'ft' : 'up', 'min': '${m['min'] ?? 0}', 'hs': '${m['hs'] ?? 0}', 'as': '${m['as'] ?? 0}'}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('live/${m['id']}/override', f), reload); }),
        ])); }(),
    ]); });
}

/// API Center — GET api-center → {apis[], live_provider{provider, host, key ("•••1234" or ""), enabled, ep_*}, rapid_endpoints{rapid_ep_*}}.
/// POST api-center/live-provider {provider, host?, key?, enabled?, clear?} — saved in the server's settings table.
///   The server treats any `enabled` value as on, so it is only sent when on; a blank key keeps the stored one; `clear` removes it.
///   {action:'test', provider, host} tests the stored key. GET api-center/probe?path= calls the provider.
/// POST api-center/rapid-endpoints {rapid_ep_fixtures, rapid_ep_events, rapid_ep_lineups, host} — RapidAPI paths.
const _providers = {'rapidapi': 'RapidAPI (premier-league18)', 'api-football': 'API-Football (api-sports.io)', 'football-data': 'football-data.org'};
class AdminApi extends StatelessWidget { const AdminApi({super.key});
  static Widget _kv(String k, String v, {Color color = Colors.white, bool mono = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(k, style: const TextStyle(color: Wz.muted, fontSize: 13))), Expanded(child: Text(v, style: TextStyle(color: color, fontSize: 13, fontFamily: mono ? 'monospace' : null)))]));
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('api-center'), builder: (c, j, reload) {
    final lp = jMap(j['live_provider']); final on = jBool(lp['enabled']); final keySet = jStr(lp['key']).isNotEmpty; final prov = jStr(lp['provider'], 'rapidapi'); final ep = jMap(j['rapid_endpoints']);
    Future<void> probe() async { final f = await form(c, 'Probe provider path', {'path': prov == 'rapidapi' ? '/' : '/fixtures?league=39&season=2026'}); if (f == null) return;
      try { final r = await AdminRepo.I.g('api-center/probe', {'path': f['path']}); if (c.mounted) showDialog(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: Text('Probe ${f['path']}'), content: SizedBox(width: 600, child: SingleChildScrollView(child: SelectableText((r['result'] ?? r).toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5)))), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))])); }
      catch (e) { if (c.mounted) toast(c, e.toString(), error: true); } }
    return _Page(title: 'API Center', sub: 'Data providers, keys and health', children: [
      _card([_h('APIs'), if (jList(j['apis']).isEmpty) const Text('No providers registered.', style: TextStyle(color: Wz.muted)), for (final a in jList(j['apis'])) _apiRow(a)]),
      _card([
        _h('Live Match Provider', trailing: _pill(on ? 'ENABLED' : 'DISABLED', on ? Wz.green : Wz.muted)),
        const Text('Feeds live lineups, positions, ratings and match stats. Settings are saved on the server, so they survive restarts and can be changed here at any time.', style: TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.4)),
        const SizedBox(height: 10),
        _kv('Provider', _providers[prov] ?? prov), if (prov == 'rapidapi') _kv('Host', jStr(lp['host'], '—')),
        if (jStr(lp['host']).contains('premier-league18')) _kv('Endpoints', 'Built in (matches by date, match detail)'),
        _kv('API key', keySet ? jStr(lp['key']) : 'Not set', color: keySet ? Colors.white : Wz.gold, mono: keySet),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () async { final f = await showDialog<Map<String, String>>(context: c, builder: (_) => _ProviderDialog(lp)); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('api-center/live-provider', f), reload); }, icon: const Icon(Icons.vpn_key_outlined, size: 18), label: Text(keySet ? 'Change provider / key' : 'Set up provider')),
          _btn('Test connection', icon: Icons.wifi_tethering_rounded, color: Wz.green, () => act(c, () => AdminRepo.I.p('api-center/live-provider', {'action': 'test', 'provider': prov, 'host': jStr(lp['host'])}))),
          _btn('Probe a path', icon: Icons.search_rounded, probe),
          if (keySet) _btn('Remove key', icon: Icons.key_off_outlined, color: Wz.red, () async { if (await confirmTyped(c, 'Remove the stored API key? Live lineups and stats stop until a new key is set.', 'REMOVE') && c.mounted) act(c, () => AdminRepo.I.p('api-center/live-provider', {'provider': prov, 'clear': '1'}), reload); }),
        ]),
      ]),
      // premier-league18 has built-in paths (matches?date=, matches/{id}); the editable paths only apply to other RapidAPI hosts.
      if (prov == 'rapidapi' && !jStr(lp['host']).contains('premier-league18')) _card([
        _h('RapidAPI Endpoint Paths', trailing: _btn('Edit paths', icon: Icons.edit_outlined, () async {
          final f = await form(c, 'RapidAPI endpoint paths', {'host': jStr(lp['host'], 'premier-league18.p.rapidapi.com'), 'rapid_ep_fixtures': jStr(ep['rapid_ep_fixtures']), 'rapid_ep_events': jStr(ep['rapid_ep_events']), 'rapid_ep_lineups': jStr(ep['rapid_ep_lineups'])});
          if (f != null && c.mounted) act(c, () => AdminRepo.I.p('api-center/rapid-endpoints', f), reload); })),
        const Text('Paths from the "Endpoints" tab of the API on rapidapi.com. Use "Probe a path" to check a path before saving it.', style: TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.4)),
        const SizedBox(height: 8),
        for (final k in const [('rapid_ep_fixtures', 'Fixtures'), ('rapid_ep_events', 'Events / timeline'), ('rapid_ep_lineups', 'Lineups')]) _kv(k.$2, jStr(ep[k.$1]).isEmpty ? 'Not set' : jStr(ep[k.$1]), color: jStr(ep[k.$1]).isEmpty ? Wz.gold : Colors.white, mono: jStr(ep[k.$1]).isNotEmpty),
      ]),
    ]); });
}

class _ProviderDialog extends StatefulWidget { final Map<String, dynamic> current; const _ProviderDialog(this.current);
  @override State<_ProviderDialog> createState() => _ProviderDialogState(); }
class _ProviderDialogState extends State<_ProviderDialog> {
  late String provider = _providers.containsKey(jStr(widget.current['provider'])) ? jStr(widget.current['provider']) : 'rapidapi';
  late final host = TextEditingController(text: jStr(widget.current['host'], 'premier-league18.p.rapidapi.com')), key = TextEditingController();
  // First-time setup (no key yet) defaults to on; afterwards the stored state is kept.
  late bool enabled = !_hasKey || jBool(widget.current['enabled']); bool show = false; String? err;
  bool get _hasKey => jStr(widget.current['key']).isNotEmpty;
  @override void dispose() { host.dispose(); key.dispose(); super.dispose(); }
  void _save() {
    if (provider == 'rapidapi' && host.text.trim().isEmpty) { setState(() => err = 'Enter the RapidAPI host'); return; }
    if (!_hasKey && key.text.trim().isEmpty) { setState(() => err = 'Enter the API key'); return; }
    Navigator.pop(context, {'provider': provider, if (provider == 'rapidapi') 'host': host.text.trim(), if (enabled) 'enabled': '1', if (key.text.trim().isNotEmpty) 'key': key.text.trim()});
  }
  @override Widget build(BuildContext c) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Live match provider'), content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    DropdownButtonFormField<String>(initialValue: provider, dropdownColor: Wz.panel2, decoration: const InputDecoration(labelText: 'Provider'), items: [for (final e in _providers.entries) DropdownMenuItem(value: e.key, child: Text(e.value))], onChanged: (v) => setState(() => provider = v ?? provider)),
    const SizedBox(height: 12),
    if (provider == 'rapidapi') ...[TextField(controller: host, decoration: const InputDecoration(labelText: 'Host', helperText: 'X-RapidAPI-Host, e.g. premier-league18.p.rapidapi.com')), const SizedBox(height: 12)],
    TextField(controller: key, obscureText: !show, autocorrect: false, enableSuggestions: false, style: const TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(labelText: _hasKey ? 'New API key' : 'API key', helperText: _hasKey ? 'Leave blank to keep the current key (${jStr(widget.current['key'])})' : 'Saved on the server; never shown again in full', helperMaxLines: 2,
        suffixIcon: IconButton(tooltip: show ? 'Hide' : 'Show', icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => show = !show)))),
    const SizedBox(height: 6),
    SwitchListTile(value: enabled, onChanged: (v) => setState(() => enabled = v), activeThumbColor: Wz.green, contentPadding: EdgeInsets.zero, title: const Text('Enabled'), subtitle: const Text('Turn off to stop all calls to this provider.', style: TextStyle(color: Wz.muted, fontSize: 12))),
    if (err != null) Text(err!, style: const TextStyle(color: Wz.red, fontSize: 12.5)),
  ]))), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), FilledButton(onPressed: _save, child: const Text('Save'))]);
}

class AdminBranding extends StatelessWidget { const AdminBranding({super.key});
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('branding'), builder: (c, j, reload) { final b = jMap(j['brand']);
    return _Page(title: 'Branding', sub: 'Name, tagline and hero text', children: [
      _card([
        _h('Brand Text', trailing: _btn('Edit text', icon: Icons.edit_outlined, color: Wz.green, () async { final f = await form(c, 'Branding text', {'brand_name': jStr(b['name']), 'brand_tagline': jStr(b['tagline']), 'hero_headline': jStr(b['headline']), 'hero_sub': jStr(b['sub']), 'hero_note': jStr(b['note'])}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('branding', f), reload); })),
        for (final r in [('Brand name', jStr(b['name'])), ('Tagline', jStr(b['tagline'])), ('Hero headline', jStr(b['headline'])), ('Hero sub-line', jStr(b['sub'])), ('Hero note', jStr(b['note']))]) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 130, child: Text(r.$1, style: const TextStyle(color: Wz.muted, fontSize: 13))), Expanded(child: Text(r.$2.isEmpty ? '—' : r.$2, style: const TextStyle(color: Colors.white, fontSize: 13.5)))])),
      ]),
      _card([
        _h('Images'),
        const Text('Logo (512×512), favicon (64×64) and hero (1920×800) are uploaded from the web admin file picker (POST /api/admin/branding/upload). From here you can restore the defaults.', style: TextStyle(color: Wz.muted, fontSize: 13, height: 1.4)), const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final k in const ['logo', 'favicon', 'hero']) _btn('Reset $k', icon: Icons.restore_rounded, () async { if (await confirmTyped(c, 'Reset the $k to the default?', 'RESET') && c.mounted) act(c, () => AdminRepo.I.p('branding/remove/$k'), reload); })]),
      ]),
    ]); });
}

class AdminLogs extends StatelessWidget { const AdminLogs({super.key});
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('logs'), poll: const Duration(seconds: 10), builder: (c, j, reload) { final bs = jList(j['backups']);
    return _Page(title: 'Logs & Backups', sub: 'Refreshes every 10 seconds', actions: [
      _btn('Export logs', icon: Icons.download_rounded, () => launchUrl(Uri.parse(AdminRepo.I.url('logs/export')))),
      FilledButton.icon(onPressed: () => act(c, () => AdminRepo.I.p('backup'), reload), icon: const Icon(Icons.backup_outlined, size: 18), label: const Text('Backup Now')),
    ], children: [
      _card([_h('Backups'), if (bs.isEmpty) const Text('No backups yet.', style: TextStyle(color: Wz.muted)),
        for (final b in bs) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 18), const SizedBox(width: 10), Expanded(child: Text(jStr(b['name']), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5))), Text('${b['size']} KB · ${b['t']}', style: const TextStyle(color: Wz.muted, fontSize: 12)),
          IconButton(tooltip: 'Download', icon: const Icon(Icons.download_rounded, color: Wz.green, size: 20), onPressed: () => launchUrl(Uri.parse(AdminRepo.I.url('backup/${b['name']}/download')))),
          IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline_rounded, color: Wz.red, size: 20), onPressed: () async { if (await confirmTyped(c, 'Delete backup ${b['name']}?', 'DELETE') && c.mounted) act(c, () => AdminRepo.I.d('backup/${b['name']}'), reload); })]))]),
      _card([_h('Logs'), if (jList(j['items']).isEmpty) const Text('No log entries.', style: TextStyle(color: Wz.muted)), for (final l in jList(j['items'])) _log(l)]),
    ]); });
}

class AdminSettings extends StatelessWidget { const AdminSettings({super.key});
  @override Widget build(BuildContext c) => Async(load: () => AdminRepo.I.g('settings'), builder: (c, j, reload) { final s = jMap(j['settings']); final flags = s.keys.where((k) => k.startsWith('flag:')).toList()..sort();
    return _Page(title: 'Settings', sub: 'Feature flags, season and admin account', children: [
      _card([
        _h('Feature Flags'), const Text('Switch FPL features on or off in the app instantly.', style: TextStyle(color: Wz.muted, fontSize: 12.5)), const SizedBox(height: 8),
        if (flags.isEmpty) const Text('No flags defined.', style: TextStyle(color: Wz.muted)),
        for (final k in flags) Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.fromLTRB(14, 4, 6, 4), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Row(children: [Expanded(child: Text(k.substring(5), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          Switch(value: jStr(s[k]) == '1', onChanged: (v) => act(c, () => AdminRepo.I.p('settings', {k: v}), reload), activeThumbColor: Colors.white, activeTrackColor: Wz.green, inactiveThumbColor: Colors.white, inactiveTrackColor: Wz.border2, trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent))])),
      ]),
      _card([
        _h('General', trailing: _btn('Edit', icon: Icons.edit_outlined, color: Wz.green, () async { final f = await form(c, 'General settings', {'season': jStr(s['season']), 'maintenance': jStr(s['maintenance']), 'maintenance_msg': jStr(s['maintenance_msg']), 'google_client_id': jStr(s['google_client_id']), 'google_client_secret': ''}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('settings', f), reload); })),
        for (final r in [('Season', jStr(s['season'], '—')), ('Maintenance mode', jStr(s['maintenance']) == '1' ? 'ON' : 'Off'), ('Maintenance message', jStr(s['maintenance_msg'], '—')), ('Google sign-in', jStr(s['google_client_id']).isEmpty ? 'Not configured' : 'Configured')]) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 170, child: Text(r.$1, style: const TextStyle(color: Wz.muted, fontSize: 13))), Expanded(child: Text(r.$2, style: const TextStyle(color: Colors.white, fontSize: 13.5)))])),
      ]),
      _card([
        _h('Admin Account', trailing: _btn('Change', icon: Icons.key_rounded, () async { final f = await form(c, 'Admin account', {'current': '', 'email': jStr(jMap(j['admin'])['email']), 'name': jStr(jMap(j['admin'])['name']), 'password': ''}); if (f != null && c.mounted) act(c, () => AdminRepo.I.p('settings/account', f), reload); })),
        Text('${jMap(j['admin'])['name'] ?? ''} · ${jMap(j['admin'])['email'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 13.5)),
      ]),
      _card([
        _h('Danger Zone'), const Text('Wiping demo data removes all demo users, leagues and clans. It cannot be undone.', style: TextStyle(color: Wz.muted, fontSize: 13)), const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: _btn('Wipe demo data', icon: Icons.delete_forever_rounded, color: Wz.red, () async { if (await confirmTyped(c, 'Wipe ALL demo data?', 'WIPE') && c.mounted) act(c, () => AdminRepo.I.p('wipe-demo', {'confirm': 'WIPE'}), reload); })),
      ], border: Wz.red.withValues(alpha: .5)),
    ]); });
}

class AdminBroadcast extends StatefulWidget { const AdminBroadcast({super.key}); @override State<AdminBroadcast> createState() => _AdminBroadcastState(); }
class _AdminBroadcastState extends State<AdminBroadcast> {
  final t = TextEditingController(), b = TextEditingController(), l = TextEditingController(); bool busy = false;
  @override void dispose() { t.dispose(); b.dispose(); l.dispose(); super.dispose(); }
  Future<void> _send() async {
    if (t.text.trim().isEmpty) { toast(context, 'Add a title first.', error: true); return; }
    final target = l.text.trim().isEmpty ? 'EVERY user' : 'everyone in "${l.text.trim()}"';
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Send broadcast?'), content: Text('This notification goes to $target and cannot be recalled.'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Send'))]));
    if (ok != true) return;
    setState(() => busy = true);
    try { final r = await AdminRepo.I.raw('notifications/broadcast', {'title': t.text.trim(), 'body': b.text.trim(), if (l.text.trim().isNotEmpty) 'league': l.text.trim()}); if (mounted) toast(context, 'Sent to ${r['sent']} users'); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext c) => _Page(title: 'Broadcast', sub: 'Send a notification to everyone, or one league', children: [
    Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: _card([
      TextField(controller: t, maxLength: 80, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(labelText: 'Title', counterText: '')), const SizedBox(height: 10),
      TextField(controller: b, maxLines: 4, maxLength: 400, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(labelText: 'Message')), const SizedBox(height: 4),
      TextField(controller: l, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(labelText: 'League slug (optional)', helperText: 'Leave empty to send to every user.')), const SizedBox(height: 16),
      Row(children: [
        OutlinedButton.icon(onPressed: busy ? null : () => act(c, () => AdminRepo.I.p('notifications/test', {'title': t.text.trim().isEmpty ? 'Test' : t.text.trim(), 'body': b.text.trim()})), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.science_outlined, size: 18), label: const Text('Send test to me')), const Spacer(),
        FilledButton.icon(onPressed: busy ? null : _send, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Wz.onPrimary)) : const Icon(Icons.campaign_rounded, size: 19), label: Text(busy ? 'Sending…' : 'Send Broadcast')),
      ]),
    ]))),
  ]);
}
