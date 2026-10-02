import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/theme.dart';
import 'league_page.dart' show kLeagueModes;

/// League Settings / Manage (/manage/:slug) — owner tools.
/// GET/POST /api/app/leagues/<slug>/settings → {name, prize, desc, rules_text, public, locked, modes{ranking,survivor,civil_war,h2h},
/// surv_round_len, surv_drop, start_gw, cw_clan_size, join_code}; invite codes via /api/app/codes.
/// Switches and steppers save immediately; text fields save with their button.
class ManageLeaguePage extends StatefulWidget { final String slug; const ManageLeaguePage(this.slug, {super.key}); @override State<ManageLeaguePage> createState() => _ManageState(); }

class _ManageState extends State<ManageLeaguePage> {
  static const _secs = [('general', 'General Information', Icons.info_outline_rounded), ('access', 'Privacy & Access', Icons.lock_outline_rounded), ('modes', 'Modes & Rules', Icons.sports_mma_rounded)];
  String sec = 'general';
  Map<String, dynamic>? s; String? loadErr; bool busy = false;
  final ctrls = {for (final k in ['name', 'prize', 'desc', 'rules_text']) k: TextEditingController()};

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { for (final t in ctrls.values) { t.dispose(); } super.dispose(); }

  Future<void> _load() async {
    setState(() => loadErr = null);
    try { final v = await Repo.I.settings(widget.slug); if (mounted) setState(() { s = v; for (final e in ctrls.entries) { e.value.text = jStr(v[e.key]); } }); }
    catch (e) { if (mounted) setState(() => loadErr = e.toString()); }
  }

  Future<void> _save(Map<String, dynamic> f, {String ok = 'Saved'}) async {
    setState(() => busy = true);
    try { final v = await Repo.I.saveSettings(widget.slug, f); if (mounted) { setState(() => s = v); toast(context, ok); } }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => busy = false); }
  }

  static BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));

  @override Widget build(BuildContext c) {
    final compact = Bp.compact(c); final wide = MediaQuery.of(c).size.width >= 1000;
    final head = Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(onTap: () => c.canPop() ? c.pop() : c.go('/league/${widget.slug}'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70), SizedBox(width: 6), Text('Back to league', style: TextStyle(color: Colors.white70, fontSize: 13))])),
        const SizedBox(height: 8),
        Text('LEAGUE SETTINGS', style: anton(compact ? 28 : 40, color: Colors.white, spacing: 1)),
        Text(s == null ? 'Manage your league' : jStr(s!['name']), style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
      ])),
      if (busy) const Padding(padding: EdgeInsets.only(bottom: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.green))),
    ]);
    Widget body;
    if (loadErr != null) { body = Container(padding: const EdgeInsets.all(24), decoration: _box(), child: Column(children: [Text(loadErr!, style: const TextStyle(color: Wz.muted)), const SizedBox(height: 10), OutlinedButton(onPressed: _load, child: const Text('Retry'))])); }
    else if (s == null) { body = const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Wz.green))); }
    else {
      final nav = wide
          ? Container(width: 250, padding: const EdgeInsets.all(8), decoration: _box(), child: Column(children: [
              for (final t in _secs) _navItem(t, vertical: true),
              const Divider(color: Wz.border2, height: 18),
              _link(Icons.groups_rounded, 'Members', '/league/${widget.slug}/members'), _link(Icons.how_to_reg_outlined, 'Join Requests', '/league/${widget.slug}/requests'),
            ]))
          : SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final t in _secs) Padding(padding: const EdgeInsets.only(right: 6), child: _navItem(t, vertical: false))]));
      final content = switch (sec) { 'access' => _access(c), 'modes' => _modes(c), _ => _general(c) };
      body = wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [nav, const SizedBox(width: 16), Expanded(child: content)])
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [nav, const SizedBox(height: 12), content,
                      const SizedBox(height: 12), Wrap(spacing: 10, children: [OutlinedButton(onPressed: () => c.go('/league/${widget.slug}/members'), child: const Text('Members')), OutlinedButton(onPressed: () => c.go('/league/${widget.slug}/requests'), child: const Text('Join Requests'))])]);
    }
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: compact ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [head, const SizedBox(height: 16), body])));
  }

  Widget _navItem((String, String, IconData) t, {required bool vertical}) { final on = sec == t.$1; return InkWell(onTap: () => setState(() => sec = t.$1), borderRadius: BorderRadius.circular(8), child: Container(height: 44, margin: EdgeInsets.only(bottom: vertical ? 2 : 0), padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: on ? Wz.green.withValues(alpha: .14) : (vertical ? null : Wz.panel), borderRadius: BorderRadius.circular(8), border: on ? Border.all(color: Wz.green.withValues(alpha: .5)) : (vertical ? null : Border.all(color: Wz.border2))),
    child: Row(mainAxisSize: vertical ? MainAxisSize.max : MainAxisSize.min, children: [Icon(t.$3, size: 19, color: on ? Wz.green : Colors.white70), const SizedBox(width: 12), Text(t.$2, style: TextStyle(color: on ? Wz.green : Colors.white.withValues(alpha: .9), fontSize: 14, fontWeight: FontWeight.w600))]))); }
  Widget _link(IconData i, String t, String route) => InkWell(onTap: () => context.go(route), borderRadius: BorderRadius.circular(8), child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [Icon(i, size: 19, color: Colors.white70), const SizedBox(width: 12), Expanded(child: Text(t, style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 14, fontWeight: FontWeight.w600))), const Icon(Icons.open_in_new_rounded, size: 15, color: Wz.muted)])));

  Widget _card(String title, List<Widget> children, {Color? border}) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(18), decoration: _box(border: border), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 14), ...children]));
  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8, top: 4), child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)));
  Widget _switch(String title, String sub, bool v, void Function(bool) on, {Color color = Wz.green, IconData? icon}) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(14, 8, 6, 8), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
    child: Row(children: [if (icon != null) ...[Icon(icon, size: 22, color: v ? color : Wz.muted), const SizedBox(width: 12)], Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)), Text(sub, style: const TextStyle(color: Wz.muted, fontSize: 12.5))])),
      Switch(value: v, onChanged: busy ? null : on, activeThumbColor: Colors.white, activeTrackColor: color, inactiveThumbColor: Colors.white, inactiveTrackColor: Wz.border2, trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent))]));
  Widget _step(String label, int v, int lo, int hi, void Function(int) on) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
    Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
    IconButton(onPressed: !busy && v > lo ? () => on(v - 1) : null, icon: const Icon(Icons.remove_circle_outline_rounded), color: Wz.green, disabledColor: Wz.faint),
    SizedBox(width: 36, child: Text('$v', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
    IconButton(onPressed: !busy && v < hi ? () => on(v + 1) : null, icon: const Icon(Icons.add_circle_outline_rounded), color: Wz.green, disabledColor: Wz.faint),
  ]));
  Widget _saveBtn(String label, VoidCallback on) => Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: busy ? null : on, icon: const Icon(Icons.save_rounded, size: 18), label: Text(label)));

  // ---------- sections ----------
  Widget _general(BuildContext c) => _card('General Information', [
    _label('League Name'), TextField(controller: ctrls['name'], maxLength: 40, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(counterText: '')),
    const SizedBox(height: 10), _label('Description'), TextField(controller: ctrls['desc'], maxLines: 3, maxLength: 200, style: const TextStyle(color: Wz.text)),
    _label('Prize'), TextField(controller: ctrls['prize'], maxLength: 80, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'Optional', counterText: '')),
    const SizedBox(height: 16),
    _saveBtn('Save Changes', () => _save({'name': ctrls['name']!.text.trim(), 'desc': ctrls['desc']!.text.trim(), 'prize': ctrls['prize']!.text.trim()})),
  ]);

  Widget _access(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _card('Privacy & Access', [
      // 1) found in search + join requests  2) viewable without login  3) closed to new members
      _switch('Public league', jBool(s!['public']) ? 'Shown in league search — anyone can find it and send a join request.' : 'Private — hidden from search. Managers join with an invite code only.', jBool(s!['public']), (v) => _save({'public': v}), icon: Icons.travel_explore_rounded),
      _publicView(c),
      _switch('Lock league', jBool(s!['locked']) ? 'Locked — no new joins or join requests.' : 'Open — new managers can join or send requests.', jBool(s!['locked']), (v) => _save({'locked': v}), color: Wz.red, icon: Icons.lock_outline_rounded),
      if (jStr(s!['join_code']).isNotEmpty) ...[
        const SizedBox(height: 6), _label('Main invite code'),
        InkWell(onTap: () { Clipboard.setData(ClipboardData(text: jStr(s!['join_code']))); toast(c, 'Code copied'); }, borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: Wz.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.green)),
          child: Row(children: [Text(jStr(s!['join_code']), style: anton(26, color: Colors.white, spacing: 5)), const Spacer(), const Icon(Icons.copy_rounded, color: Wz.green, size: 20)]))),
      ],
    ]),
    _codes(c),
  ]);

  /// Public view link: settings.public_view lets visitors open /league/<slug> (overview, standings, modes) without logging in.
  /// Older servers don't send the field yet — the switch then stays off and says so.
  Widget _publicView(BuildContext c) {
    final supported = s!.containsKey('public_view'); final on = jBool(s!['public_view']); final link = '${Config.baseUrl}/league/${widget.slug}';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Opacity(opacity: supported ? 1 : .55, child: IgnorePointer(ignoring: !supported, child: _switch('Public view link', !supported ? 'Needs a server update before it can be turned on.' : on ? 'Visible — anyone with the link can see standings and game modes without logging in.' : 'Hidden — only logged-in members can see this league.', on, (v) => _save({'public_view': v}), icon: Icons.visibility_outlined))),
      if (supported && on) Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(onTap: () { Clipboard.setData(ClipboardData(text: link)); toast(c, 'Public link copied'); }, borderRadius: BorderRadius.circular(10),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Wz.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.green.withValues(alpha: .6))),
          child: Row(children: [const Icon(Icons.link_rounded, color: Wz.green, size: 20), const SizedBox(width: 10), Expanded(child: Text(link, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14))), const Icon(Icons.copy_rounded, color: Wz.green, size: 19)])))),
    ]);
  }

  Widget _codes(BuildContext c) => Async(load: () => Repo.I.codes(widget.slug), builder: (c, cs, reload) => _card('Invite Codes', [
    for (final k in cs) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(14, 8, 4, 8), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SelectableText(jStr(k['code']), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 2)),
        Text([jStr(k['kind']), if (k['clan'] != null) jStr(k['clan']), if (jStr(k['label']).isNotEmpty) jStr(k['label']), '${k['uses']}/${jInt(k['max_uses']) == 0 ? '∞' : k['max_uses']} uses'].join(' · '), style: const TextStyle(color: Wz.muted, fontSize: 12)),
      ])),
      IconButton(tooltip: 'Copy', onPressed: () { Clipboard.setData(ClipboardData(text: jStr(k['code']))); toast(c, 'Code copied'); }, icon: const Icon(Icons.copy_rounded, color: Wz.green, size: 19)),
      Switch(value: jBool(k['active']), onChanged: (_) async { try { await Repo.I.codeToggle(jInt(k['id'])); await reload(); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); } }, activeThumbColor: Colors.white, activeTrackColor: Wz.green, inactiveThumbColor: Colors.white, inactiveTrackColor: Wz.border2, trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent)),
      IconButton(tooltip: 'Delete', onPressed: () async {
        final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: Text('Delete code ${k['code']}?'), content: const Text('Managers can no longer join with it.'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), style: FilledButton.styleFrom(backgroundColor: Wz.red, foregroundColor: Colors.white), child: const Text('Delete'))]));
        if (ok == true) { try { await Repo.I.codeDelete(jInt(k['id'])); await reload(); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); } }
      }, icon: const Icon(Icons.delete_outline_rounded, color: Wz.red, size: 20)),
    ])),
    if (cs.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('No extra invite codes yet.', style: TextStyle(color: Wz.muted))),
    Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Create Code'), onPressed: () async {
      final label = TextEditingController(), max = TextEditingController(text: '0');
      final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: const Text('New invite code'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: label, decoration: const InputDecoration(labelText: 'Label (optional)')), const SizedBox(height: 10), TextField(controller: max, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Max uses (0 = unlimited)'))]), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Create'))]));
      if (ok == true) { try { await Repo.I.codeCreate(league: widget.slug, label: label.text.trim(), maxUses: int.tryParse(max.text) ?? 0); await reload(); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); } }
    })),
  ]));

  Widget _modes(BuildContext c) {
    final m = jMap(s!['modes']);
    const keys = {'ranking': 'ranking', 'survivor': 'survivor', 'civil_war': 'civil-war', 'h2h': 'h2h'};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _card('Game Modes', [for (final e in keys.entries) () { final meta = kLeagueModes[e.value]!; return _switch(meta.$1, jBool(m[e.key]) ? 'Enabled' : 'Disabled', jBool(m[e.key]), (v) => _save({'modes': {...m, e.key: v}}), color: meta.$2); }()]),
      _card('Scoring', [_step('Points count from gameweek', jInt(s!['start_gw'], 1), 1, 38, (v) => _save({'start_gw': v}))]),
      if (jBool(m['survivor'])) _card('Last Survivor', [
        _step('Gameweeks per round', jInt(s!['surv_round_len'], 1), 1, 10, (v) => _save({'surv_round_len': v})),
        _step('Eliminated per round', jInt(s!['surv_drop'], 1), 1, 5, (v) => _save({'surv_drop': v})),
      ], border: Wz.purple2.withValues(alpha: .4)),
      if (jBool(m['civil_war'])) _card('Civil War', [
        _step('Scoring members per clan', jInt(s!['cw_clan_size'], 4), 4, 10, (v) => _save({'cw_clan_size': v})),
        const Text('Every clan uses the same member count. Highest clan each gameweek earns 10 War Points, lowest earns 1.', style: TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.4)),
      ], border: Wz.red.withValues(alpha: .4)),
      _card('House Rules', [
        TextField(controller: ctrls['rules_text'], maxLines: 5, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'Anything your members should know…')),
        const SizedBox(height: 14), _saveBtn('Save Rules', () => _save({'rules_text': ctrls['rules_text']!.text.trim()})),
      ]),
    ]);
  }
}
