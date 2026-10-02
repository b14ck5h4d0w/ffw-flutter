import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/player.dart';
import '../fpl/fpl_client.dart';
import '../fpl/fpl_login_page.dart';
import '../players/pitch.dart';

/// Transfer workflow (/transfers[?in=<player id>]):
///   T01 Build Team → T02 Review Changes → T03 Slide to Confirm → T04 Success / Updated Team.
/// GET /api/app/transfers → {squad[], next_gw, deadline, free, bank}; POST /api/app/plan {out, in} validates the draft
/// ({ok, problems[], hit, bank_after}). Nothing is sent to FPL while building or reviewing.
/// The official write happens only after the slider is dragged to the end (or the accessible confirm dialog is accepted):
/// phone → POST plan/payload → FPL /api/transfers/ using the FPL session stored on the device.
/// Web has no FPL session, so T03 hands off to the FFW app instead of writing.
class TransfersPage extends StatefulWidget { final int? preIn; const TransfersPage({super.key, this.preIn}); @override State<TransfersPage> createState() => _TransfersState(); }

enum _Stage { build, review, confirm, success }

class _TransfersState extends State<TransfersPage> {
  Map<String, dynamic>? base; List<Player> squad = []; final out = <int>[], inn = <int>[]; final inPlayers = <int, Player>{};
  Map<String, dynamic>? plan; String? loadErr, writeErr; bool validating = false, writing = false; _Stage stage = _Stage.build;
  List<(Player?, Player?)> done = const []; int doneGw = 0, doneHit = 0;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { loadErr = null; base = null; });
    try {
      final b = await Repo.I.transfers(); final s = jListOf(b['squad'], Player.fromJson);
      if (widget.preIn != null && inn.isEmpty) { try { final p = Player.fromJson(await Repo.I.player(widget.preIn!)); inn.add(p.id); inPlayers[p.id] = p; } catch (_) {} }
      if (mounted) setState(() { base = b; squad = s; });
      if (inn.isNotEmpty) _validate();
    } on ApiException catch (e) { if (mounted) setState(() => loadErr = e.message); }
    catch (_) { if (mounted) setState(() => loadErr = 'Could not load your transfers.'); }
  }

  Future<void> _validate() async {
    if (out.isEmpty && inn.isEmpty) { setState(() => plan = null); return; }
    setState(() => validating = true);
    Map<String, dynamic> p;
    try { p = await Repo.I.plan(out, inn); } on ApiException catch (e) { p = {'ok': false, 'problems': e.problems.isEmpty ? [e.message] : e.problems}; } catch (_) { p = {'ok': false, 'problems': ['Could not check this draft. Try again.']}; }
    if (mounted) setState(() { plan = p; validating = false; });
  }

  void _toggleOut(Player p) { setState(() => out.contains(p.id) ? out.remove(p.id) : out.add(p.id)); _validate(); }
  void _removeIn(int id) { setState(() { inn.remove(id); inPlayers.remove(id); }); _validate(); }
  Future<void> _pick() async {
    final wide = MediaQuery.of(context).size.width >= 800;
    final p = wide ? await showDialog<Player>(context: context, builder: (_) => Dialog(backgroundColor: Wz.panel, child: SizedBox(width: 520, height: 620, child: _Picker(exclude: {for (final s in squad) s.id, ...inn}))))
                   : await showModalBottomSheet<Player>(context: context, isScrollControlled: true, backgroundColor: Wz.panel, builder: (s) => SizedBox(height: MediaQuery.of(s).size.height * .86, child: _Picker(exclude: {for (final x in squad) x.id, ...inn})));
    if (p != null) { setState(() { inn.add(p.id); inPlayers[p.id] = p; }); _validate(); }
  }
  void _reset() { setState(() { out.clear(); inn.clear(); inPlayers.clear(); plan = null; writeErr = null; }); }

  /// A draft can go forward only when the server accepts it and every player sold has a replacement.
  bool get _ok => plan != null && jBool(plan!['ok']) && out.isNotEmpty && out.length == inn.length;
  bool get _balanced => out.length == inn.length;
  int get _hit => jInt(plan?['hit']);
  List<String> get _problems => (plan?['problems'] as List? ?? const []).map((e) => '$e').toList();
  List<(Player?, Player?)> get _pairs { final o = [for (final id in out) squad.where((x) => x.id == id).firstOrNull], i = [for (final id in inn) inPlayers[id]]; return [for (var k = 0; k < (o.length > i.length ? o.length : i.length); k++) (k < o.length ? o[k] : null, k < i.length ? i[k] : null)]; }

  /// The only place that writes to FPL. Called after the slide (or the accessible confirm) completes.
  Future<void> _commit() async {
    final fpl = FplClient.I;
    if (!fpl.canWrite || writing) return;
    setState(() { writing = true; writeErr = null; });
    try {
      if (!await fpl.loggedIn()) {
        if (!mounted) return;
        final r = await Navigator.of(context).push<int?>(MaterialPageRoute(builder: (_) => const FplLoginPage()));
        if (r == null) { if (mounted) setState(() { writing = false; writeErr = 'Sign in to FPL to confirm your transfers.'; }); return; }
      }
      final entry = await fpl.entry() ?? Session.I.user?.fpl;
      if (entry == null) throw FplWriteUnavailable('Your FPL team is not connected.');
      final my = await fpl.myTeam(entry);
      final pl = await Repo.I.planPayload(my, out, inn);
      await fpl.transfer(jMap(pl['payload']));
      if (!mounted) return;
      setState(() { done = _pairs; doneGw = jInt(pl['event'], jInt(base?['next_gw'])); doneHit = _hit; writing = false; stage = _Stage.success; out.clear(); inn.clear(); inPlayers.clear(); plan = null; });
    } catch (e) {
      if (mounted) setState(() { writing = false; writeErr = e is ApiException ? e.message : e.toString(); });
    }
  }

  static BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
  static String _deadline(String s) { final d = DateTime.tryParse(s)?.toLocal(); if (d == null) return '—'; const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return '${d.day} ${m[d.month - 1]}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; }

  @override Widget build(BuildContext c) {
    final compact = Bp.compact(c);
    Widget body;
    if (Session.I.user?.fpl == null) { body = _info(Icons.link_rounded, 'Connect your FPL team', 'Link your Fantasy Premier League team to plan transfers.', 'Connect with FPL', () => c.go('/connect-fpl')); }
    else if (loadErr != null) { body = _info(Icons.wifi_off_rounded, 'Transfers unavailable', loadErr!, 'Try Again', _load); }
    else if (base == null) { body = const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: Wz.green))); }
    else { body = switch (stage) { _Stage.review => _review(c), _Stage.confirm => _confirm(c), _Stage.success => _success(c), _ => _build(c) }; }
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: compact ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TRANSFERS', style: anton(compact ? 30 : 40, color: Colors.white, spacing: 1)),
          Text(base == null ? 'Plan your next move' : 'Gameweek ${base!['next_gw'] ?? '–'} · deadline ${_deadline(jStr(base!['deadline']))}', style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
        ])),
      ]),
      const SizedBox(height: 14),
      if (base != null && Session.I.user?.fpl != null) ...[_steps(), const SizedBox(height: 14)],
      body,
    ])));
  }

  Widget _info(IconData i, String t, String s, String action, VoidCallback on) => Center(child: Container(constraints: const BoxConstraints(maxWidth: 460), padding: const EdgeInsets.all(26), decoration: _box(), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(i, color: Wz.green, size: 40), const SizedBox(height: 12), Text(t, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 6),
    Text(s, textAlign: TextAlign.center, style: const TextStyle(color: Wz.muted)), const SizedBox(height: 16), FilledButton(onPressed: on, child: Text(action))])));

  Widget _steps() { const names = ['Build Team', 'Review', 'Confirm', 'Done']; final cur = stage.index;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: _box(), child: Row(children: [for (final (i, n) in names.indexed) ...[
      if (i > 0) Expanded(child: Container(height: 2, color: i <= cur ? Wz.green : Wz.border2)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: i < cur ? Wz.green : Wz.bg, border: Border.all(color: i <= cur ? Wz.green : Wz.border2, width: 1.5)), child: i < cur ? const Icon(Icons.check_rounded, size: 15, color: Wz.onPrimary) : Text('${i + 1}', style: TextStyle(color: i == cur ? Wz.green : Wz.muted, fontSize: 12, fontWeight: FontWeight.w700))),
        if (!Bp.compact(context) || i == cur) ...[const SizedBox(width: 8), Text(n, style: TextStyle(color: i == cur ? Colors.white : Wz.muted, fontSize: 13, fontWeight: FontWeight.w600))],
      ])),
    ]])); }

  Widget _tiles() { final b = base!; final over = _hit > 0;
    Widget t(IconData i, Color col, String v, String k) => Container(width: Bp.compact(context) ? (MediaQuery.of(context).size.width - 38) / 2 : 190, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: _box(border: col == Wz.red ? Wz.red.withValues(alpha: .5) : null),
      child: Row(children: [Icon(i, color: col, size: 24), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: TextStyle(color: col == Wz.red ? Wz.red : Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), Text(k, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5))]))]));
    return Wrap(spacing: 10, runSpacing: 10, children: [
      t(Icons.swap_horiz_rounded, Wz.green, '${b['free'] ?? '–'}', 'Free Transfers'), t(Icons.account_balance_wallet_outlined, Wz.cyan, '£${b['bank'] ?? '–'}m', 'In the Bank'),
      t(Icons.remove_circle_outline_rounded, over ? Wz.red : Wz.muted, over ? '-$_hit pts' : '0', 'Points Hit'), t(Icons.savings_outlined, Wz.gold, plan?['bank_after'] == null ? '£${b['bank'] ?? '–'}m' : '£${plan!['bank_after']}m', 'Bank After'),
    ]); }

  Widget _swapRow((Player?, Player?) s) { Widget side(Player? p, bool isOut) => Expanded(child: p == null ? Text(isOut ? 'Pick a player to sell' : 'Pick a replacement', style: const TextStyle(color: Wz.faint, fontSize: 13)) : Row(children: [
      Container(width: 4, height: 34, color: Wz.hex(p.club.color)), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), Text('${p.pos} · ${p.club.code} · £${((isOut ? p.sell : null) ?? p.price).toStringAsFixed(1)}m', style: const TextStyle(color: Wz.muted, fontSize: 11.5))])),
    ]));
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Row(children: [
      const Icon(Icons.arrow_upward_rounded, color: Wz.red, size: 18), const SizedBox(width: 8), side(s.$1, true),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.swap_horiz_rounded, color: Wz.muted)),
      const Icon(Icons.arrow_downward_rounded, color: Wz.green, size: 18), const SizedBox(width: 8), side(s.$2, false),
    ])); }

  Widget _status() => plan == null ? const SizedBox.shrink() : Container(margin: const EdgeInsets.only(top: 4, bottom: 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (_ok ? Wz.green : Wz.red).withValues(alpha: .08), borderRadius: BorderRadius.circular(10), border: Border.all(color: (_ok ? Wz.green : Wz.red).withValues(alpha: .5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(_ok ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: _ok ? Wz.green : Wz.red, size: 18), const SizedBox(width: 8), Text(_ok ? 'This draft is within the rules' : !_balanced ? (out.length > inn.length ? 'Add a replacement for each player you sell' : 'Choose who to sell for each player you add') : 'This draft is not allowed yet', style: TextStyle(color: _ok ? Wz.green : Wz.red, fontWeight: FontWeight.w700))]),
    for (final p in _problems) Padding(padding: const EdgeInsets.only(top: 5, left: 26), child: Text('• $p', style: const TextStyle(color: Wz.text, fontSize: 13))),
  ]));

  // ---------- T01 ----------
  Widget _build(BuildContext c) {
    final draft = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [const Icon(Icons.edit_note_rounded, color: Wz.green, size: 22), const SizedBox(width: 8), const Expanded(child: Text('Your Draft', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))), if (validating) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.green))]),
      const SizedBox(height: 4), const Text('A draft only. Nothing is sent to FPL until you slide to confirm.', style: TextStyle(color: Wz.muted, fontSize: 12.5)), const SizedBox(height: 12),
      if (_pairs.isEmpty) Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10)), child: const Text('Tap a player on the pitch to sell them, then add a replacement.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted, fontSize: 13)))
      else for (final s in _pairs) _swapRow(s),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final id in out) InputChip(label: Text('OUT ${squad.where((x) => x.id == id).firstOrNull?.name ?? id}'), backgroundColor: Wz.red.withValues(alpha: .15), side: BorderSide(color: Wz.red.withValues(alpha: .5)), labelStyle: const TextStyle(color: Colors.white, fontSize: 12), onDeleted: () { setState(() => out.remove(id)); _validate(); }),
        for (final id in inn) InputChip(label: Text('IN ${inPlayers[id]?.name ?? id}'), backgroundColor: Wz.green.withValues(alpha: .15), side: BorderSide(color: Wz.green.withValues(alpha: .5)), labelStyle: const TextStyle(color: Colors.white, fontSize: 12), onDeleted: () => _removeIn(id)),
      ]),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: _pick, style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green), minimumSize: const Size.fromHeight(44)), icon: const Icon(Icons.person_add_alt_1_rounded, size: 18), label: const Text('Add Player In')),
      _status(), const SizedBox(height: 10),
      Row(children: [
        if (out.isNotEmpty || inn.isNotEmpty) TextButton(onPressed: _reset, style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text('Reset')), const Spacer(),
        FilledButton.icon(onPressed: _ok && !validating ? () => setState(() => stage = _Stage.review) : null, style: FilledButton.styleFrom(minimumSize: const Size(170, 46)), icon: const Icon(Icons.arrow_forward_rounded, size: 19), label: const Text('Review Changes')),
      ]),
    ]));
    final pitch = Container(padding: const EdgeInsets.all(14), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Tap a player to sell', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 4),
      Text(out.isEmpty ? 'Selected players are marked for transfer out.' : '${out.length} selected to sell — tap again to undo.', style: const TextStyle(color: Wz.muted, fontSize: 12.5)), const SizedBox(height: 12),
      Pitch(picks: squad, mode: 'team', onTap: _toggleOut, selected: out.toSet()),
    ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_tiles(), const SizedBox(height: 14),
      MediaQuery.of(c).size.width >= 1100 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: pitch), const SizedBox(width: 16), Expanded(flex: 2, child: draft)])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [pitch, const SizedBox(height: 14), draft])]);
  }

  // ---------- T02 ----------
  Widget _review(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_tiles(), const SizedBox(height: 14),
    Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Container(padding: const EdgeInsets.all(18), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Review Changes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 4),
      Text('${_pairs.length} transfer${_pairs.length == 1 ? '' : 's'} for Gameweek ${base!['next_gw'] ?? '–'}. Check everything before you confirm.', style: const TextStyle(color: Wz.muted, fontSize: 13)), const SizedBox(height: 14),
      for (final s in _pairs) _swapRow(s),
      const SizedBox(height: 6),
      for (final r in [('Free transfers available', '${base!['free'] ?? '–'}'), ('Transfers in this draft', '${_pairs.length}'), ('Points hit', _hit > 0 ? '-$_hit pts' : 'None'), ('Bank after', plan?['bank_after'] == null ? '—' : '£${plan!['bank_after']}m')])
        Container(padding: const EdgeInsets.symmetric(vertical: 9), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))), child: Row(children: [Text(r.$1, style: const TextStyle(color: Wz.muted, fontSize: 13.5)), const Spacer(), Text(r.$2, style: TextStyle(color: r.$1 == 'Points hit' && _hit > 0 ? Wz.red : Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700))])),
      if (_hit > 0) Padding(padding: const EdgeInsets.only(top: 12), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Wz.gold, size: 18), const SizedBox(width: 8), Expanded(child: Text('These transfers cost $_hit points. The hit is taken from your next gameweek score.', style: const TextStyle(color: Wz.gold, fontSize: 13)))])),
      const SizedBox(height: 18),
      Row(children: [
        OutlinedButton(onPressed: () => setState(() => stage = _Stage.build), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2), minimumSize: const Size(120, 46)), child: const Text('Edit Draft')), const Spacer(),
        FilledButton.icon(onPressed: () => setState(() { writeErr = null; stage = _Stage.confirm; }), style: FilledButton.styleFrom(minimumSize: const Size(190, 46)), icon: const Icon(Icons.arrow_forward_rounded, size: 19), label: const Text('Continue to Confirm')),
      ]),
    ]))))]);

  // ---------- T03 ----------
  Widget _confirm(BuildContext c) { final canWrite = FplClient.I.canWrite;
    return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Container(padding: const EdgeInsets.all(20), decoration: _box(border: Wz.green.withValues(alpha: .45)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [const Icon(Icons.verified_user_outlined, color: Wz.green, size: 26), const SizedBox(width: 10), Expanded(child: Text(canWrite ? 'Confirm on your official FPL team' : 'Confirm in the FFW app', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)))]),
      const SizedBox(height: 8),
      Text(canWrite ? 'Sliding the bar applies these transfers to your Fantasy Premier League team for Gameweek ${base!['next_gw'] ?? '–'}. This cannot be undone.'
                    : 'Official transfers are made from the FFW mobile app, where your FPL login stays on your phone. Your draft is not saved on the web — repeat it in the app, or make the transfers on the FPL site.', style: const TextStyle(color: Wz.muted, fontSize: 13.5, height: 1.45)),
      const SizedBox(height: 14),
      for (final s in _pairs) _swapRow(s),
      if (_hit > 0) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Points hit: -$_hit', style: const TextStyle(color: Wz.red, fontWeight: FontWeight.w700))),
      if (writeErr != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.red.withValues(alpha: .1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.red.withValues(alpha: .5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.error_outline_rounded, color: Wz.red, size: 18), SizedBox(width: 8), Text('Transfers were not confirmed', style: TextStyle(color: Wz.red, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 4), Text(writeErr!, style: const TextStyle(color: Wz.text, fontSize: 13)), const SizedBox(height: 4),
        const Text('Nothing changed on your FPL team. You can try again.', style: TextStyle(color: Wz.muted, fontSize: 12.5)),
      ])),
      const SizedBox(height: 4),
      if (canWrite) ...[
        SlideToConfirm(label: writeErr == null ? 'Slide to confirm transfers' : 'Slide to try again', busy: writing, onConfirmed: _commit),
        const SizedBox(height: 6),
        Center(child: TextButton(onPressed: writing ? null : () async {
          final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Confirm transfers?'), content: Text('${_pairs.length} transfer${_pairs.length == 1 ? '' : 's'} will be applied to your FPL team${_hit > 0 ? ' for a $_hit point hit' : ''}. This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Confirm Transfers'))]));
          if (ok == true) _commit();
        }, style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text("Can't slide? Confirm with a button"))),
      ] else Wrap(spacing: 10, runSpacing: 10, children: [
        FilledButton.icon(onPressed: () => launchUrl(Uri.parse('https://fantasy.premierleague.com/transfers'), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new_rounded, size: 18), label: const Text('Open FPL Transfers')),
      ]),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: writing ? null : () => setState(() => stage = _Stage.review), style: TextButton.styleFrom(foregroundColor: Wz.green), icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('Back to Review'))),
    ])))); }

  // ---------- T04 ----------
  Widget _success(BuildContext c) => Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Container(padding: const EdgeInsets.all(24), decoration: _box(border: Wz.green.withValues(alpha: .5)), child: Column(children: [
    Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Wz.green, width: 3), boxShadow: [BoxShadow(color: Wz.green.withValues(alpha: .35), blurRadius: 24)]), child: const Icon(Icons.check_rounded, color: Wz.green, size: 50)),
    const SizedBox(height: 16),
    Text('TRANSFERS CONFIRMED', textAlign: TextAlign.center, style: anton(30, color: Colors.white, spacing: 1)), const SizedBox(height: 6),
    Text('Your FPL team is updated for Gameweek $doneGw.${doneHit > 0 ? ' Points hit: -$doneHit.' : ''}', textAlign: TextAlign.center, style: const TextStyle(color: Wz.green, fontSize: 14.5, fontWeight: FontWeight.w600)),
    const SizedBox(height: 18),
    for (final s in done) _swapRow(s),
    const SizedBox(height: 14),
    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
      FilledButton.icon(onPressed: () => c.go('/squad'), icon: const Icon(Icons.shield_outlined, size: 18), label: const Text('View Updated Team')),
      OutlinedButton(onPressed: () { setState(() => stage = _Stage.build); _load(); }, style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), child: const Text('Make More Transfers')),
    ]),
  ]))));
}

/// Horizontal slide-to-confirm. [onConfirmed] fires only when the thumb is dragged to the end;
/// releasing early springs it back. Shows a spinner while [busy].
class SlideToConfirm extends StatefulWidget { final String label; final bool busy; final VoidCallback onConfirmed; const SlideToConfirm({super.key, required this.label, required this.onConfirmed, this.busy = false}); @override State<SlideToConfirm> createState() => _SlideState(); }
class _SlideState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  double x = 0; bool fired = false;
  static const _h = 60.0, _thumb = 52.0;
  @override void didUpdateWidget(covariant SlideToConfirm o) { super.didUpdateWidget(o); if (o.busy && !widget.busy) setState(() { x = 0; fired = false; }); }
  @override Widget build(BuildContext c) => LayoutBuilder(builder: (c, box) {
    final max = box.maxWidth - _thumb - 8; final t = max <= 0 ? 0.0 : (x / max).clamp(0.0, 1.0);
    return Semantics(label: '${widget.label}. Drag the handle to the right end to confirm.', child: Container(height: _h, decoration: BoxDecoration(color: Wz.bg, borderRadius: BorderRadius.circular(_h / 2), border: Border.all(color: Wz.green.withValues(alpha: .7), width: 1.4)), child: Stack(children: [
      Positioned(left: 0, top: 0, bottom: 0, width: x + _thumb + 4, child: DecoratedBox(decoration: BoxDecoration(color: Wz.green.withValues(alpha: .22), borderRadius: BorderRadius.circular(_h / 2)))),
      Center(child: Opacity(opacity: (1 - t * 1.6).clamp(0.0, 1.0), child: Text(widget.busy ? 'Confirming with FPL…' : widget.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)))),
      Positioned(left: 4 + x, top: 4, child: GestureDetector(
        onHorizontalDragUpdate: widget.busy || fired ? null : (d) => setState(() => x = (x + d.delta.dx).clamp(0.0, max)),
        onHorizontalDragEnd: widget.busy || fired ? null : (_) { if (x >= max * .96) { setState(() { x = max; fired = true; }); widget.onConfirmed(); } else { setState(() => x = 0); } },
        child: Container(width: _thumb, height: _thumb, decoration: BoxDecoration(shape: BoxShape.circle, color: Wz.green, boxShadow: [BoxShadow(color: Wz.green.withValues(alpha: .5), blurRadius: 14)]),
          child: widget.busy ? const Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator(strokeWidth: 2.4, color: Wz.onPrimary)) : const Icon(Icons.double_arrow_rounded, color: Wz.onPrimary, size: 26)))),
    ])));
  });
}

/// Searchable player picker (GET /api/app/players).
class _Picker extends StatefulWidget { final Set<int> exclude; const _Picker({required this.exclude}); @override State<_Picker> createState() => _PickerState(); }
class _PickerState extends State<_Picker> {
  String q = '', sort = 'form'; String? pos; int ver = 0;
  @override Widget build(BuildContext c) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 8), child: Column(children: [
      Row(children: [const Expanded(child: Text('Add Player In', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close_rounded, color: Wz.muted))]),
      TextField(autofocus: true, onSubmitted: (v) => setState(() { q = v.trim(); ver++; }), textInputAction: TextInputAction.search, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'Search players…', prefixIcon: Icon(Icons.search_rounded, color: Wz.muted), isDense: true)),
      const SizedBox(height: 8),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (final p in [null, 'GK', 'DEF', 'MID', 'FWD']) Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(p ?? 'All'), selected: pos == p, showCheckmark: false, onSelected: (_) => setState(() { pos = p; ver++; }), selectedColor: Wz.green, labelStyle: TextStyle(color: pos == p ? Wz.onPrimary : Colors.white, fontWeight: FontWeight.w600), backgroundColor: Wz.bg, side: const BorderSide(color: Wz.border2))),
        const SizedBox(width: 8),
        for (final s in const [('form', 'Form'), ('pts', 'Points'), ('price', 'Price')]) Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(s.$2), selected: sort == s.$1, showCheckmark: false, onSelected: (_) => setState(() { sort = s.$1; ver++; }), selectedColor: Wz.cyan, labelStyle: TextStyle(color: sort == s.$1 ? Wz.bg : Colors.white70, fontWeight: FontWeight.w600), backgroundColor: Wz.bg, side: const BorderSide(color: Wz.border2))),
      ])),
    ])),
    Expanded(child: Async(key: ValueKey('$ver'), load: () => Repo.I.players(pos: pos, q: q, sort: sort, limit: 60), builder: (c, all, _) { final ps = all.where((p) => !widget.exclude.contains(p.id)).toList();
      if (ps.isEmpty) return const Center(child: Text('No players found.', style: TextStyle(color: Wz.muted)));
      return ListView.builder(itemCount: ps.length, itemBuilder: (c, i) { final p = ps[i];
        return ListTile(onTap: () => Navigator.pop(c, p), leading: HexAvatar(p.club.code, size: 40, color: Wz.hex(p.club.color), url: p.photoUrl),
          title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), subtitle: Text('${p.pos} · ${p.club.code} · form ${p.form.toStringAsFixed(1)} · ${p.pts} pts', style: const TextStyle(color: Wz.muted, fontSize: 12)),
          trailing: Text('£${p.price.toStringAsFixed(1)}m', style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w700))); }); })),
  ]);
}
