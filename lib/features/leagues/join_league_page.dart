import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/assets.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/theme.dart';

/// Opens A23 and completes when the user comes back (callers refresh their lists afterwards).
Future<void> joinByCode(BuildContext c) => c.push('/join');

/// A23 — Join League (/join?code=). POST /api/app/join {code} — the code may belong to a league or a clan.
/// → {ok, msg, slug, kind ('league'|'clan')}. The message is shown as-is; with a slug the user can open it straight away.
class JoinLeaguePage extends StatefulWidget { final String? code; const JoinLeaguePage({super.key, this.code}); @override State<JoinLeaguePage> createState() => _JoinState(); }

class _JoinState extends State<JoinLeaguePage> {
  late final code = TextEditingController(text: (widget.code ?? '').toUpperCase());
  bool busy = false, clan = false; String? err, done, slug;

  @override void dispose() { code.dispose(); super.dispose(); }

  Future<void> _join() async {
    final v = code.text.trim().toUpperCase();
    if (v.length < 4) { setState(() => err = 'Enter the invite code you were given.'); return; }
    setState(() { busy = true; err = null; });
    try {
      final r = await Repo.I.join(v);
      if (mounted) setState(() { busy = false; done = jStr(r['msg'], 'You are in!'); slug = jStrN(r['slug']); clan = jStr(r['kind']) == 'clan'; });
    } on ApiException catch (x) { if (mounted) setState(() { busy = false; err = x.kind == ErrKind.rateLimited ? 'Too many attempts. Please wait a moment.' : x.message; }); }
    catch (_) { if (mounted) setState(() { busy = false; err = 'Something went wrong. Please try again.'; }); }
  }

  static BoxDecoration _box({Color? border, bool glow = false}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2), boxShadow: glow ? [BoxShadow(color: Wz.green.withValues(alpha: .14), blurRadius: 28)] : null);

  @override Widget build(BuildContext c) {
    final compact = Bp.compact(c); final wide = MediaQuery.of(c).size.width >= 1000;
    final form = Container(padding: EdgeInsets.all(compact ? 18 : 26), decoration: _box(border: Wz.green.withValues(alpha: .5), glow: true), child: done != null ? _success(c) : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('INVITE CODE', style: TextStyle(color: Wz.green, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
      const SizedBox(height: 10),
      TextField(controller: code, enabled: !busy, autofocus: true, textAlign: TextAlign.center, textCapitalization: TextCapitalization.characters, maxLength: 12, onSubmitted: (_) => _join(),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')), TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase()))],
        onChanged: (_) { if (err != null) setState(() => err = null); },
        style: anton(34, color: Colors.white, spacing: 8),
        decoration: InputDecoration(counterText: '', hintText: 'WZ0142', hintStyle: anton(34, color: Wz.faint, spacing: 8), errorText: err, contentPadding: const EdgeInsets.symmetric(vertical: 18))),
      const SizedBox(height: 16),
      SizedBox(height: 50, child: FilledButton.icon(onPressed: busy ? null : _join,
        icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Wz.onPrimary)) : const Icon(Icons.login_rounded),
        label: Text(busy ? 'Joining…' : 'Join', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 14),
      const Text('The code comes from a league owner or a clan captain. It takes you straight in — or sends a request if the league needs approval.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.45)),
    ]));
    final side = Container(padding: const EdgeInsets.all(20), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('HOW IT WORKS', style: TextStyle(color: Wz.green, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.3)), const SizedBox(height: 14),
      for (final (i, t) in const ['Ask the league owner or clan captain for their invite code.', 'Enter it here — capitals or lower case both work.', 'You are added to the league or clan right away, or after approval.'].indexed) Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Wz.green)), child: Text('${i + 1}', style: const TextStyle(color: Wz.green, fontSize: 12.5, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12), Expanded(child: Text(t, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13.5, height: 1.4))),
      ])),
      const Divider(color: Wz.border2, height: 24),
      const Text("Don't have a code?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () => c.go('/leagues/directory'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.travel_explore_rounded, size: 18), label: const Text('Discover Public Leagues')),
    ]));
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: compact ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      Container(clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
        Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .5)], stops: const [.4, 1])))),
        if (!compact) Positioned(right: 26, top: 20, child: Transform.rotate(angle: -.14, child: Text('One code.\nOne battle.', textAlign: TextAlign.center, style: script(30)))),
        Padding(padding: EdgeInsets.all(compact ? 18 : 26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(onTap: () => c.canPop() ? c.pop() : c.go('/leagues'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70), SizedBox(width: 6), Text('Leagues', style: TextStyle(color: Colors.white70, fontSize: 13))])),
          const SizedBox(height: 10),
          Text('JOIN A LEAGUE', style: anton(compact ? 30 : 42, color: Colors.white, spacing: 1)),
          const Text('Enter your invite code to step into the Warzone.', style: TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
        ])),
      ])),
      const SizedBox(height: 16),
      wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: form), const SizedBox(width: 16), Expanded(flex: 2, child: side)])
           : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [form, const SizedBox(height: 14), side]),
    ])));
  }

  Widget _success(BuildContext c) => Column(children: [
    Container(width: 84, height: 84, decoration: BoxDecoration(shape: BoxShape.circle, color: Wz.green.withValues(alpha: .1), border: Border.all(color: Wz.green.withValues(alpha: .5))), child: const Icon(Icons.check_rounded, color: Wz.green, size: 44)),
    const SizedBox(height: 16),
    Text(done!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
    const SizedBox(height: 18),
    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
      if (slug != null) FilledButton.icon(onPressed: () => c.go(clan ? '/clan/$slug' : '/league/$slug'), icon: const Icon(Icons.arrow_forward_rounded), label: Text(clan ? 'Open Clan' : 'Open League')),
      OutlinedButton(onPressed: () => c.go('/leagues'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), child: const Text('My Leagues')),
      TextButton(onPressed: () => setState(() { done = null; slug = null; code.clear(); }), child: const Text('Enter another code')),
    ]),
  ]);
}
