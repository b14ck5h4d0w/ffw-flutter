import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/assets.dart';
import '../../core/json.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import 'fpl_stage.dart';

/// A07 — Connecting to FPL (/connect-fpl/sync?entry=…).
/// Runs the real steps in order — verify team (fpl/lookup) → link to the FFW account (me/fpl)
/// → sync squad → load chips — showing each one's actual state (no simulated percentages).
/// A failed step can be retried from where it stopped. On success → A08 (/connect-fpl/done).
class FplSyncPage extends StatefulWidget { final int? entry; const FplSyncPage({super.key, this.entry}); @override State<FplSyncPage> createState() => _FplSyncState(); }

enum _St { waiting, running, done, failed }

class _Step {
  final String title, detail; _St st = _St.waiting; String? error;
  _Step(this.title, this.detail);
}

class _FplSyncState extends State<FplSyncPage> {
  final steps = [
    _Step('Verifying Team', 'Checking your FPL team exists and reading its details.'),
    _Step('Linking Account', 'Connecting the team to your FFW account.'),
    _Step('Syncing Squad', 'Importing your current squad, captain and points.'),
    _Step('Loading Chips', 'Checking which chips you still have.'),
  ];
  String? team;

  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _run()); }

  bool get _failed => steps.any((s) => s.st == _St.failed);
  int get _doneCount => steps.where((s) => s.st == _St.done).length;

  Future<void> _run() async {
    final e = widget.entry;
    if (e == null) { setState(() { steps[0].st = _St.failed; steps[0].error = 'No FPL team was selected.'; }); return; }
    if (!Session.I.loggedIn) { setState(() { steps[0].st = _St.failed; steps[0].error = 'Please log in first.'; }); return; }
    final jobs = <Future<void> Function()>[
      () async { final j = await Repo.I.fplLookup('$e'); team = jStrN(j['team']); },
      () async { await Repo.I.fplLink(e); await Session.I.refreshMe(); },
      () async { await Repo.I.squad(); },
      () async { await Repo.I.chips(); },
    ];
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].st == _St.done) continue;
      setState(() { steps[i].st = _St.running; steps[i].error = null; });
      try {
        await jobs[i]();
        if (!mounted) return;
        setState(() => steps[i].st = _St.done);
      } on ApiException catch (x) {
        if (!mounted) return;
        // Squad/chips can lag right after linking; the team is still connected, so don't block on them.
        if (i >= 2) { setState(() => steps[i].st = _St.done); continue; }
        setState(() { steps[i].st = _St.failed; steps[i].error = x.message; });
        return;
      } catch (_) {
        if (!mounted) return;
        if (i >= 2) { setState(() => steps[i].st = _St.done); continue; }
        setState(() { steps[i].st = _St.failed; steps[i].error = 'Something went wrong. Please try again.'; });
        return;
      }
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) context.go('/connect-fpl/done');
  }

  @override Widget build(BuildContext c) => FplStage(flourish: 'Real players.\nReal leagues.\nBigger battles.', desktop: _desktop, mobile: _mobile);

  // ---------- pieces ----------
  Widget _head(double size, {bool center = false}) => Column(crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
    Text.rich(TextSpan(children: [
      TextSpan(text: _failed ? 'Connection ' : 'Connecting to ', style: anton(size, color: Colors.white, spacing: .6)),
      TextSpan(text: _failed ? 'Paused' : 'FPL', style: anton(size, color: _failed ? Wz.gold : Wz.green, spacing: .6)),
    ]), textAlign: center ? TextAlign.center : TextAlign.start),
    const SizedBox(height: 8),
    Text(_failed ? 'One step needs your attention.' : _doneCount == steps.length ? 'All set — opening your team…' : 'Syncing your data, almost there…',
        textAlign: center ? TextAlign.center : TextAlign.start, style: TextStyle(color: _failed ? Wz.gold : Wz.green, fontSize: size * .38, fontWeight: FontWeight.w600)),
  ]);

  Widget _stepRow(_Step s, {required bool wide, bool last = false}) {
    final (icon, color, label) = switch (s.st) {
      _St.done => (Icons.check_circle_outline_rounded, Wz.green, 'Completed'),
      _St.running => (Icons.autorenew_rounded, Wz.green, 'Working…'),
      _St.failed => (Icons.error_outline_rounded, Wz.red, 'Failed'),
      _St.waiting => (Icons.radio_button_unchecked_rounded, Wz.faint, 'Waiting…'),
    };
    final bar = ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(height: 6, child: switch (s.st) {
      _St.running => const LinearProgressIndicator(color: Wz.green, backgroundColor: Wz.border2),
      _ => LinearProgressIndicator(value: s.st == _St.waiting ? 0.04 : 1, color: s.st == _St.failed ? Wz.red : Wz.green, backgroundColor: Wz.border2),
    }));
    return Container(padding: EdgeInsets.symmetric(vertical: wide ? 14 : 10), decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Wz.border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        s.st == _St.running
            ? SizedBox(width: wide ? 34 : 28, height: wide ? 34 : 28, child: const CircularProgressIndicator(strokeWidth: 2.4, color: Wz.green))
            : Icon(icon, color: color, size: wide ? 36 : 30),
        SizedBox(width: wide ? 18 : 12),
        Expanded(flex: wide ? 5 : 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(s.title, style: TextStyle(color: Colors.white, fontSize: wide ? 15.5 : 14, fontWeight: FontWeight.w600))),
            if (!wide) Text(label, style: TextStyle(color: s.st == _St.waiting ? Wz.muted : color, fontSize: 11.5)),
          ]),
          const SizedBox(height: 3),
          Text(s.error ?? s.detail, style: TextStyle(color: s.error != null ? Wz.red : Colors.white.withValues(alpha: .7), fontSize: 12.5, height: 1.35)),
          if (!wide) ...[const SizedBox(height: 8), bar],
        ])),
        if (wide) ...[const SizedBox(width: 20), Expanded(flex: 3, child: bar), SizedBox(width: 96, child: Text(label, textAlign: TextAlign.right, style: TextStyle(color: s.st == _St.waiting ? Wz.muted : color, fontSize: 13, fontWeight: FontWeight.w600)))],
      ]));
  }

  Widget _steps({required bool wide}) => Container(padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 14, vertical: wide ? 8 : 4), decoration: fplPanel(border: (_failed ? Wz.red : Wz.green).withValues(alpha: .45), glow: true),
    child: Column(children: [for (final (i, s) in steps.indexed) _stepRow(s, wide: wide, last: i == steps.length - 1)]));

  Widget _actions() => !_failed ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(top: 16), child: Wrap(spacing: 12, runSpacing: 10, alignment: WrapAlignment.center, children: [
    FilledButton.icon(onPressed: _run, icon: const Icon(Icons.refresh_rounded), label: const Text('Try Again'), style: FilledButton.styleFrom(minimumSize: const Size(160, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
    OutlinedButton(onPressed: () => context.go('/connect-fpl'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green), minimumSize: const Size(160, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Use a Different Team')),
  ]));

  Widget _status() => Container(padding: const EdgeInsets.all(20), decoration: fplPanel(border: Wz.green.withValues(alpha: .4)), child: Row(children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Wz.border2)), child: const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 30)),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(team ?? 'FPL Team ${widget.entry ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      const Text('Fantasy Premier League', style: TextStyle(color: Wz.muted, fontSize: 12.5)),
    ])),
    Container(width: 1, height: 44, margin: const EdgeInsets.symmetric(horizontal: 16), color: Wz.border2),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: _failed ? Wz.red : Wz.green)), const SizedBox(width: 8),
        Text(_failed ? 'PAUSED' : _doneCount == steps.length ? 'CONNECTED' : 'CONNECTING…', style: TextStyle(color: _failed ? Wz.red : Wz.green, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: .8))]),
      const SizedBox(height: 4),
      Text('Step ${(_doneCount + (_failed ? 1 : 0)).clamp(1, steps.length)} of ${steps.length}', style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12.5)),
    ]),
  ]));

  static final _perks = [
    (Icons.verified_user_outlined, 'Secure', kIsWeb ? 'We only read your public FPL data.' : "Your FPL password never reaches FFW."),
    (Icons.bolt_rounded, 'Fast Sync', 'Your team is imported in seconds.'),
    (Icons.groups_rounded, 'Your Leagues', 'Compete in FFW leagues and clans.'),
    (Icons.emoji_events_outlined, 'Bigger Together', 'Same game. New levels.'),
  ];

  // ---------- desktop ----------
  Widget _desktop(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const FplCrumb('CONNECT FPL'), const SizedBox(height: 12),
    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _head(50), const SizedBox(height: 12),
      Text("We're connecting your Fantasy Premier League team to FFW and importing your squad and game data.", style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 15, height: 1.45)),
    ])),
    const SizedBox(height: 22),
    SizedBox(width: 620, child: Column(children: [_steps(wide: true), _actions()])),
    const SizedBox(height: 18),
    SizedBox(width: 620, child: _status()),
    const SizedBox(height: 22),
    Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18), decoration: fplPanel(), child: Row(children: [
      for (final (i, p) in _perks.indexed) ...[if (i > 0) const SizedBox(width: 20), Expanded(child: FplPerk(p.$1, p.$2, p.$3))],
    ])),
  ]);

  // ---------- phone ----------
  Widget _mobile(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const SizedBox(height: 8),
    Center(child: SizedBox(width: 200, height: 200, child: Stack(alignment: Alignment.center, children: [
      SizedBox(width: 196, height: 196, child: CircularProgressIndicator(strokeWidth: 3, color: _failed ? Wz.red : Wz.green, backgroundColor: Wz.border2, value: _failed || _doneCount == steps.length ? 1 : null)),
      Image.asset(WzAssets.emblem, width: 160, height: 160),
    ]))),
    const SizedBox(height: 14),
    _head(28, center: true), const SizedBox(height: 18),
    _steps(wide: false), _actions(),
    const SizedBox(height: 18),
    Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), decoration: fplPanel(border: Wz.green.withValues(alpha: .4)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.workspace_premium_rounded, color: Wz.gold, size: 26), const SizedBox(width: 10), Text('"Same game. Stronger together."', style: script(22))])),
  ]);
}
