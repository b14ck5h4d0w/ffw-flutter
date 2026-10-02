import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/json.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../fpl/fpl_stage.dart';

/// A09 — What's Next / Onboarding (/onboarding).
/// Five setup steps with real progress where the API can tell: profile (country + bio set),
/// league joined and clan joined (from /home leagues). Modes and alerts can't be detected, so they
/// only offer their action. "Continue Setup" opens the first unfinished step.
class OnboardingPage extends StatefulWidget { const OnboardingPage({super.key}); @override State<OnboardingPage> createState() => _OnboardingState(); }

class _Task {
  final IconData icon; final Color color; final String title, short, detail, cta, route; final bool? done;
  const _Task(this.icon, this.color, this.title, this.short, this.detail, this.cta, this.route, this.done);
}

class _OnboardingState extends State<OnboardingPage> {
  List<Map<String, dynamic>>? leagues;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final j = await Repo.I.home(); if (mounted) setState(() => leagues = jList(j['leagues'])); } catch (_) { if (mounted) setState(() => leagues = const []); }
  }

  List<_Task> get _tasks {
    final u = Session.I.user;
    final profile = u != null && (u.country ?? '').isNotEmpty && (u.bio ?? '').isNotEmpty;
    final l = leagues;
    return [
      _Task(Icons.person_rounded, Colors.white, 'Complete Your Profile', 'Make it yours', 'Add your photo, country and a short bio.', 'Get Started', '/me', profile),
      _Task(Icons.emoji_events_rounded, Wz.gold, 'Join a League', 'Compete with friends', 'Compete in global and private leagues.', 'Join League', '/leagues', l?.isNotEmpty),
      const _Task(Icons.sports_esports_rounded, Colors.white, 'Choose Your Modes', 'Pick your challenges', 'Ranking, Civil War, Last Survivor and Head-to-Head.', 'Explore Modes', '/modes', null),
      _Task(Icons.groups_rounded, Colors.white, 'Create or Join a Clan', 'Find your squad', 'Find your squad. Build your legacy.', 'Find a Clan', '/clans', l?.any((x) => x['clan'] != null)),
      const _Task(Icons.notifications_rounded, Colors.white, 'Enable Alerts', 'Stay ahead of the action', 'Live updates, deadline reminders and more.', 'Enable Alerts', '/settings/notifications', null),
    ];
  }

  int get _doneCount => _tasks.where((t) => t.done == true).length;
  _Task get _next => _tasks.firstWhere((t) => t.done != true, orElse: () => _tasks.last);

  @override Widget build(BuildContext c) {
    if (!Session.I.loggedIn) return FplStage(flourish: 'Same game.\nBigger battles.', back: '/welcome', desktop: (_) => _gate(), mobile: (_) => _gate());
    return FplStage(flourish: 'Same game.\nBigger battles.', back: '/home', desktop: _desktop, mobile: _mobile);
  }

  Widget _gate() => Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Container(width: 400, padding: const EdgeInsets.all(24), decoration: fplPanel(), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text('Log in to continue', style: anton(24, color: Colors.white)), const SizedBox(height: 16),
    FilledButton(onPressed: () => context.go('/login'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)), child: const Text('Login')),
  ]))));

  // ---------- pieces ----------
  Widget _head(double size, {bool center = false}) {
    final linked = Session.I.user?.fpl != null;
    final a = center ? TextAlign.center : TextAlign.start;
    return Column(crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
      Text('$_doneCount OF ${_tasks.length} DONE', textAlign: a, style: const TextStyle(color: Wz.green, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 1.3)),
      const SizedBox(height: 6),
      Text("WHAT'S NEXT?", textAlign: a, style: anton(size, color: Colors.white, spacing: .8)),
      const SizedBox(height: 6),
      Text(linked ? 'Your FPL account is connected!' : 'Your FFW account is ready!', textAlign: a, style: TextStyle(color: Wz.green, fontSize: size * .42, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Now let\'s set up your FFW experience and unlock everything the Warzone has to offer.', textAlign: a, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: size < 40 ? 13.5 : 15.5, height: 1.45)),
    ]);
  }

  Widget _num(int i, _Task t, {required bool active, double size = 30}) => Container(width: size, height: size, alignment: Alignment.center,
    decoration: BoxDecoration(shape: BoxShape.circle, color: t.done == true ? Wz.green : Wz.bg, border: Border.all(color: active || t.done == true ? Wz.green : Colors.white.withValues(alpha: .7), width: 1.6),
        boxShadow: active ? [BoxShadow(color: Wz.green.withValues(alpha: .45), blurRadius: 12)] : null),
    child: t.done == true ? Icon(Icons.check_rounded, size: size * .6, color: Wz.onPrimary) : Text('${i + 1}', style: TextStyle(color: active ? Wz.green : Colors.white, fontSize: size * .45, fontWeight: FontWeight.w700)));

  Widget _cta(_Task t, {required bool primary}) => SizedBox(width: 150, height: 40, child: primary
      ? FilledButton(onPressed: () => context.go(t.route), style: FilledButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t.cta, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 17)]))
      : OutlinedButton(onPressed: () => context.go(t.route), style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: t.done == true ? Wz.muted : Wz.green, side: BorderSide(color: t.done == true ? Wz.border2 : Wz.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t.done == true ? 'Done · View' : t.cta, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), const SizedBox(width: 6), Icon(t.done == true ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 17)])));

  Widget _deskRow(int i, _Task t) {
    final active = t.route == _next.route && t.done != true;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      SizedBox(width: 44, child: Center(child: _num(i, t, active: active))),
      const SizedBox(width: 10),
      Expanded(child: Container(padding: const EdgeInsets.fromLTRB(20, 9, 14, 9), decoration: fplPanel(border: active ? Wz.green.withValues(alpha: .6) : null, glow: active), child: Row(children: [
        Icon(t.icon, color: t.color, size: 32), const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600)), const SizedBox(height: 3),
          Text(t.detail, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 13)),
        ])),
        _cta(t, primary: active),
      ]))),
    ]));
  }

  Widget _mobRow(int i, _Task t) {
    final active = t.route == _next.route && t.done != true;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      _num(i, t, active: active, size: 26), const SizedBox(width: 10),
      Expanded(child: InkWell(onTap: () => context.go(t.route), borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.fromLTRB(14, 10, 8, 10), decoration: fplPanel(border: active ? Wz.green.withValues(alpha: .6) : null),
        child: Row(children: [
          Icon(t.icon, color: t.color, size: 26), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
            Text(t.done == true ? 'Done' : t.short, style: TextStyle(color: t.done == true ? Wz.green : Colors.white.withValues(alpha: .7), fontSize: 11.5)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ])))),
    ]));
  }

  Widget _continue(double h) => SizedBox(height: h, child: FilledButton(onPressed: () => context.go(_next.route), style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Continue Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), SizedBox(width: 10), Icon(Icons.arrow_forward_rounded)])));
  Widget _later() => Center(child: TextButton(onPressed: () => context.go('/home'), style: TextButton.styleFrom(foregroundColor: Wz.green),
      child: const Text("I'll Do This Later", style: TextStyle(fontSize: 13.5, decoration: TextDecoration.underline, decorationColor: Wz.green))));

  // ---------- desktop ----------
  Widget _desktop(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 680, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 54), child: _head(46)),
      const SizedBox(height: 20),
      for (final (i, t) in _tasks.indexed) _deskRow(i, t),
      Padding(padding: const EdgeInsets.only(left: 54, top: 4), child: Row(children: [SizedBox(width: 240, child: _continue(48)), const SizedBox(width: 12), _later()])),
    ])),
    const SizedBox(height: 18),
    Row(children: [
      Expanded(flex: 5, child: Container(height: 110, clipBehavior: Clip.antiAlias, decoration: fplPanel(border: Wz.green.withValues(alpha: .35)), child: Stack(fit: StackFit.expand, children: [
        Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.bottomCenter, opacity: const AlwaysStoppedAnimation(.45)),
        Row(children: [const SizedBox(width: 22), Image.asset(WzAssets.emblem, width: 90, height: 90), const SizedBox(width: 18), Expanded(child: Transform.rotate(angle: -.05, child: Text('Join a global community\nof FPL warriors.', style: script(30))))]),
      ]))),
      const SizedBox(width: 12),
      Expanded(flex: 4, child: Container(height: 110, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: fplPanel(), child: Row(children: [
        for (final (i, s) in const [(Icons.sync_rounded, 'Live FPL', 'Sync'), (Icons.sports_esports_rounded, 'Competitive', 'Game Modes'), (Icons.public_rounded, 'Clans & Private', 'Leagues')].indexed) ...[
          if (i > 0) Container(width: 1, height: 60, color: Wz.border2),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(s.$1, color: Wz.green, size: 30), const SizedBox(height: 8), Text(s.$2, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)), Text(s.$3, style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 12.5))])),
        ],
      ]))),
      const SizedBox(width: 12),
      Expanded(flex: 3, child: Column(children: [const Text('"SET UP TODAY,\nDOMINATE TOMORROW."', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 3, height: 1.5)), const SizedBox(height: 8), Icon(Icons.workspace_premium_rounded, color: Wz.gold.withValues(alpha: .9), size: 28)])),
    ]),
  ]);

  // ---------- phone ----------
  Widget _mobile(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    SizedBox(height: 230, child: Stack(children: [
      Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
        Image.asset(WzAssets.stadium, fit: BoxFit.cover),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Wz.bg], stops: [.55, 1]))),
      ]))),
      Positioned(left: 0, right: 90, top: 8, bottom: 0, child: Image.asset(WzAssets.player10, fit: BoxFit.fitHeight, alignment: Alignment.topCenter)),
      Positioned(right: 6, top: 40, child: Transform.rotate(angle: -.2, child: Text('Your journey\ncontinues.', textAlign: TextAlign.center, style: script(26)))),
    ])),
    const SizedBox(height: 4),
    _head(32, center: true), const SizedBox(height: 16),
    for (final (i, t) in _tasks.indexed) _mobRow(i, t),
    const SizedBox(height: 10), _continue(48), const SizedBox(height: 4), _later(),
  ]);
}
