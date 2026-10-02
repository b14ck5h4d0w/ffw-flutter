import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/assets.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/theme.dart';
import '../../models/league.dart';
import 'league_page.dart' show kLeagueModes;

/// A24 — Create League (/create-league), three steps: Basic → Modes → Review.
/// Also covers the Last Survivor schedule builder + preview (A48/A49):
/// GET /api/app/survivor/schedule?players=N → phases[], final{}, elimination_rounds.
/// POST /api/app/leagues {name, public, modes[], prize, desc, surv_round_len, surv_drop, survivor_players?}.
class CreateLeaguePage extends StatefulWidget { const CreateLeaguePage({super.key}); @override State<CreateLeaguePage> createState() => _CreateState(); }

class _CreateState extends State<CreateLeaguePage> {
  final name = TextEditingController(), desc = TextEditingController(), prize = TextEditingController();
  int step = 0; bool public = false, auto = true, busy = false; int players = 17, roundLen = 3, drop = 1;
  final modes = {'ranking': true, 'civil-war': false, 'survivor': false, 'h2h': false};
  String? nameErr, modeErr, serverErr; League? created;

  static const _steps = ['Basic', 'Modes', 'Review'];
  static const _blurb = {
    'ranking': 'Every manager ranked by total FPL points.', 'civil-war': 'Clans battle every gameweek for War Points.',
    'survivor': 'Lowest scorers are eliminated each round.', 'h2h': 'Seeded knockout bracket, one gameweek per tie.',
  };

  @override void dispose() { name.dispose(); desc.dispose(); prize.dispose(); super.dispose(); }

  static BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
  List<String> get _on => [for (final e in modes.entries) if (e.value) e.key];

  bool _validate(int s) {
    if (s == 0) { final ok = name.text.trim().length >= 3; setState(() => nameErr = ok ? null : 'Give your league a name (3+ characters).'); return ok; }
    if (s == 1) { final ok = _on.isNotEmpty; setState(() => modeErr = ok ? null : 'Choose at least one game mode.'); return ok; }
    return true;
  }
  void _next() { if (_validate(step)) setState(() => step++); }

  Future<void> _create() async {
    if (!_validate(0)) { setState(() => step = 0); return; }
    if (!_validate(1)) { setState(() => step = 1); return; }
    setState(() { busy = true; serverErr = null; });
    try {
      final l = await Repo.I.createLeague({'name': name.text.trim(), 'public': public, 'modes': _on, 'prize': prize.text.trim(), 'desc': desc.text.trim(), 'surv_round_len': roundLen, 'surv_drop': drop, if (auto && modes['survivor']!) 'survivor_players': players});
      if (mounted) setState(() { busy = false; created = l; });
    } on ApiException catch (x) { if (mounted) setState(() { busy = false; serverErr = x.problems.isEmpty ? x.message : x.problems.join('\n'); }); }
    catch (_) { if (mounted) setState(() { busy = false; serverErr = 'Something went wrong. Please try again.'; }); }
  }

  @override Widget build(BuildContext c) {
    final compact = Bp.compact(c);
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: compact ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      Container(clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
        Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .5)], stops: const [.4, 1])))),
        if (!compact) Positioned(right: 26, top: 20, child: Transform.rotate(angle: -.14, child: Text('Create rivalries.\nBuild legacies.', textAlign: TextAlign.center, style: script(30)))),
        Padding(padding: EdgeInsets.all(compact ? 18 : 26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(onTap: () => c.canPop() ? c.pop() : c.go('/leagues'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70), SizedBox(width: 6), Text('Leagues', style: TextStyle(color: Colors.white70, fontSize: 13))])),
          const SizedBox(height: 10),
          Text('CREATE NEW LEAGUE', style: anton(compact ? 30 : 42, color: Colors.white, spacing: 1)),
          const Text('Build your own community.', style: TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
        ])),
      ])),
      const SizedBox(height: 16),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: created != null ? _done(c, created!) : Container(padding: EdgeInsets.all(compact ? 16 : 24), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _stepper(), const SizedBox(height: 22),
        [_basic, _modes, _review][step](c),
        const SizedBox(height: 22),
        if (serverErr != null) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: Wz.red.withValues(alpha: .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Wz.red.withValues(alpha: .45))),
          child: Row(children: [const Icon(Icons.error_outline_rounded, color: Wz.red, size: 18), const SizedBox(width: 9), Expanded(child: Text(serverErr!, style: const TextStyle(color: Wz.text, fontSize: 13)))])),
        Row(children: [
          if (step > 0) OutlinedButton(onPressed: busy ? null : () => setState(() => step--), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2), minimumSize: const Size(110, 46)), child: const Text('Back'))
          else OutlinedButton(onPressed: () => c.canPop() ? c.pop() : c.go('/leagues'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2), minimumSize: const Size(110, 46)), child: const Text('Cancel')),
          const Spacer(),
          step < 2 ? FilledButton(onPressed: _next, style: FilledButton.styleFrom(minimumSize: const Size(150, 46)), child: const Text('Next Step'))
                   : FilledButton.icon(onPressed: busy ? null : _create, style: FilledButton.styleFrom(minimumSize: const Size(170, 46)),
                       icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Wz.onPrimary)) : const Icon(Icons.emoji_events_rounded), label: Text(busy ? 'Creating…' : 'Create League')),
        ]),
      ])))),
    ])));
  }

  Widget _stepper() => Row(children: [for (final (i, s) in _steps.indexed) ...[
    if (i > 0) Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 20), color: i <= step ? Wz.green : Wz.border2)),
    InkWell(onTap: i < step ? () => setState(() => step = i) : null, child: Column(children: [
      Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: i < step ? Wz.green : Wz.bg, border: Border.all(color: i <= step ? Wz.green : Wz.border2, width: 1.6)),
        child: i < step ? const Icon(Icons.check_rounded, size: 19, color: Wz.onPrimary) : Text('${i + 1}', style: TextStyle(color: i == step ? Wz.green : Wz.muted, fontWeight: FontWeight.w700))),
      const SizedBox(height: 6), Text(s, style: TextStyle(color: i == step ? Colors.white : Wz.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
    ])),
  ]]);

  Widget _label(String t, {bool req = false}) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text.rich(TextSpan(children: [TextSpan(text: t), if (req) const TextSpan(text: ' *', style: TextStyle(color: Wz.red))]), style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)));

  // ---------- step 1 ----------
  Widget _basic(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _label('League Name', req: true),
    TextField(controller: name, maxLength: 40, style: const TextStyle(color: Wz.text), onChanged: (_) { if (nameErr != null) setState(() => nameErr = null); }, decoration: InputDecoration(hintText: 'Enter league name', errorText: nameErr, counterText: '')),
    const SizedBox(height: 18),
    _label('League Type', req: true),
    Row(children: [
      Expanded(child: _typeCard(true, Icons.public_rounded, 'Public', 'Open to everyone')), const SizedBox(width: 12),
      Expanded(child: _typeCard(false, Icons.lock_outline_rounded, 'Private', 'Join with a league code')),
    ]),
    const SizedBox(height: 18),
    _label('Description'),
    TextField(controller: desc, maxLines: 3, maxLength: 200, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'Tell us about your league…')),
  ]);

  Widget _typeCard(bool v, IconData i, String t, String s) { final on = public == v; return InkWell(onTap: () => setState(() => public = v), borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: on ? Wz.green.withValues(alpha: .12) : Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(10), border: Border.all(color: on ? Wz.green : Wz.border2, width: on ? 1.4 : 1)),
    child: Row(children: [Icon(i, color: on ? Wz.green : Colors.white70), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: TextStyle(color: on ? Wz.green : Colors.white, fontSize: 15, fontWeight: FontWeight.w700)), Text(s, style: const TextStyle(color: Wz.muted, fontSize: 12))])),
      if (on) const Icon(Icons.check_circle_rounded, color: Wz.green, size: 20)]))); }

  // ---------- step 2 ----------
  Widget _modes(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _label('Game Modes', req: true),
    GridView.extent(maxCrossAxisExtent: 420, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 3.6, children: [
      for (final k in modes.keys) () { final m = kLeagueModes[k]!; final on = modes[k]!;
        return InkWell(onTap: () => setState(() { modes[k] = !on; modeErr = null; }), borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: on ? m.$2.withValues(alpha: .12) : Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(10), border: Border.all(color: on ? m.$2 : Wz.border2, width: on ? 1.4 : 1)),
          child: Row(children: [Icon(m.$3, color: m.$2, size: 26), const SizedBox(width: 12), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.$1, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)), Text(_blurb[k]!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Wz.muted, fontSize: 12))])),
            Icon(on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: on ? m.$2 : Wz.faint)]))); }(),
    ]),
    if (modeErr != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(modeErr!, style: const TextStyle(color: Wz.red, fontSize: 12.5))),
    if (modes['survivor']!) ...[const SizedBox(height: 18), _survivor()],
    if (modes['civil-war']!) const Padding(padding: EdgeInsets.only(top: 14), child: Text('Civil War needs clans. After creating the league, members form clans from the Clans page.', style: TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.4))),
  ]);

  Widget _survivor() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Wz.purple.withValues(alpha: .07), borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.purple2.withValues(alpha: .45))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Row(children: [Icon(Icons.dangerous_outlined, color: Wz.purple2, size: 20), SizedBox(width: 8), Text('Last Survivor Schedule', style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700))]),
    const SizedBox(height: 10),
    SegmentedButton<bool>(showSelectedIcon: false, segments: const [ButtonSegment(value: true, label: Text('Auto schedule')), ButtonSegment(value: false, label: Text('Manual'))], selected: {auto}, onSelectionChanged: (v) => setState(() => auto = v.first),
      style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Wz.purple.withValues(alpha: .3) : Wz.bg), foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.white : Wz.muted), side: const WidgetStatePropertyAll(BorderSide(color: Wz.border2)))),
    const SizedBox(height: 12),
    if (auto) ...[
      _count('Number of players', players, 6, 40, (v) => setState(() => players = v)),
      const Text('The schedule is built automatically so the Grand Final lands on the last gameweeks.', style: TextStyle(color: Wz.muted, fontSize: 12.5)),
      const SizedBox(height: 12),
      Async(key: ValueKey(players), load: () => Repo.I.survivorSchedule(players), builder: (c, s, _) => _schedule(s)),
    ] else ...[
      _count('Gameweeks per round', roundLen, 1, 10, (v) => setState(() => roundLen = v)),
      _count('Eliminated per round', drop, 1, 5, (v) => setState(() => drop = v)),
    ],
  ]));

  /// Preview of the generated schedule (phases → final).
  Widget _schedule(Map<String, dynamic> s) {
    final phases = jList(s['phases']); final fin = jMap(s['final']);
    Widget row(Color col, String head, String a, String b) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: col, width: 3))),
      child: Row(children: [SizedBox(width: 78, child: Text(head, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .6))), Expanded(child: Text(a, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500))), Text(b, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))]));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Wrap(spacing: 16, runSpacing: 6, children: [
        Text('${s['players']} players', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Text('${s['elimination_rounds']} elimination rounds', style: const TextStyle(color: Colors.white70)),
        Text('${s['finalists'] ?? fin['players']} finalists', style: const TextStyle(color: Wz.gold)),
      ])),
      for (final p in phases) row(Wz.purple2, 'PHASE ${p['phase']}', 'GW ${p['start_gw']}–${p['end_gw']} · ${p['label']} · ${p['rounds']} rounds, ${p['eliminate']} out each', '${p['players_start']} → ${p['players_end']}'),
      if (fin.isNotEmpty) row(Wz.gold, 'FINAL', 'GW ${fin['start_gw']}–${fin['end_gw']} · highest total wins', '${fin['players']} managers'),
    ]);
  }

  Widget _count(String label, int v, int lo, int hi, void Function(int) on) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
    Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
    IconButton(onPressed: v > lo ? () => on(v - 1) : null, icon: const Icon(Icons.remove_circle_outline_rounded), color: Wz.green, disabledColor: Wz.faint),
    SizedBox(width: 36, child: Text('$v', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
    IconButton(onPressed: v < hi ? () => on(v + 1) : null, icon: const Icon(Icons.add_circle_outline_rounded), color: Wz.green, disabledColor: Wz.faint),
  ]));

  // ---------- step 3 ----------
  Widget _review(BuildContext c) {
    Widget kv(String k, Widget v) => Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(k, style: const TextStyle(color: Wz.muted, fontSize: 13))), Expanded(child: v)]));
    Widget t(String s) => Text(s, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _label('Prize (optional)'),
      TextField(controller: prize, maxLength: 80, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'e.g. Winner takes the trophy', counterText: '')),
      const SizedBox(height: 18),
      _label('Review'),
      kv('Name', t(name.text.trim())),
      kv('Type', t(public ? 'Public — open to everyone' : 'Private — join with a code')),
      kv('Modes', Wrap(spacing: 6, runSpacing: 6, children: [for (final k in _on) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kLeagueModes[k]!.$2.withValues(alpha: .12), borderRadius: BorderRadius.circular(20), border: Border.all(color: kLeagueModes[k]!.$2.withValues(alpha: .5))), child: Text(kLeagueModes[k]!.$1, style: TextStyle(color: kLeagueModes[k]!.$2, fontSize: 11.5, fontWeight: FontWeight.w600)))])),
      if (modes['survivor']!) kv('Last Survivor', t(auto ? 'Auto schedule for $players players' : '$roundLen GW per round · $drop out each round')),
      if (desc.text.trim().isNotEmpty) kv('Description', t(desc.text.trim())),
    ]);
  }

  Widget _done(BuildContext c, League l) => Container(padding: const EdgeInsets.all(28), decoration: _box(border: Wz.green.withValues(alpha: .5)), child: Column(children: [
    Container(width: 84, height: 84, decoration: BoxDecoration(shape: BoxShape.circle, color: Wz.green.withValues(alpha: .1), border: Border.all(color: Wz.green.withValues(alpha: .5))), child: const Icon(Icons.emoji_events_rounded, color: Wz.gold, size: 42)),
    const SizedBox(height: 16),
    Text('LEAGUE CREATED', style: anton(30, color: Colors.white, spacing: 1)),
    const SizedBox(height: 6),
    Text(l.name, style: const TextStyle(color: Wz.green, fontSize: 16, fontWeight: FontWeight.w600)),
    if (l.code.isNotEmpty) ...[
      const SizedBox(height: 18),
      const Text('INVITE CODE', style: TextStyle(color: Wz.muted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
      const SizedBox(height: 6),
      InkWell(onTap: () { Clipboard.setData(ClipboardData(text: l.code)); toast(c, 'Code copied'); }, borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10), decoration: BoxDecoration(color: Wz.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.green)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(l.code, style: anton(30, color: Colors.white, spacing: 6)), const SizedBox(width: 14), const Icon(Icons.copy_rounded, color: Wz.green, size: 20)]))),
      const SizedBox(height: 6),
      const Text('Share this code so managers can join.', style: TextStyle(color: Wz.muted, fontSize: 12.5)),
    ],
    const SizedBox(height: 20),
    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
      FilledButton.icon(onPressed: () => c.go('/league/${l.slug}'), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Open League')),
      OutlinedButton(onPressed: () => c.go('/manage/${l.slug}'), style: OutlinedButton.styleFrom(foregroundColor: Wz.purple2, side: BorderSide(color: Wz.purple2.withValues(alpha: .7))), child: const Text('League Settings')),
    ]),
  ]));
}
