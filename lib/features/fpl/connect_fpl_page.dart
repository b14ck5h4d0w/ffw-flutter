import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/json.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../auth/auth_chrome.dart';
import 'fpl_login_page.dart';

/// A06 — Connect with FPL.
/// App: the user signs in on FPL's own page in a WebView (FplLoginPage); the entry id is read from FPL's
/// /api/me/ on the device and the FPL session never leaves the phone.
/// Web: browsers can't reach FPL's private API, so the team is found by entry id / team URL (read-only).
/// Either way the next step is A07 (/connect-fpl/sync?entry=…), which links the team and syncs it.
class ConnectFplPage extends StatefulWidget { const ConnectFplPage({super.key}); @override State<ConnectFplPage> createState() => _ConnectFplState(); }

class _ConnectFplState extends State<ConnectFplPage> {
  final entry = TextEditingController();
  bool busy = false, manual = kIsWeb; String? fieldErr, serverErr, note;

  @override void dispose() { entry.dispose(); super.dispose(); }

  void _next(int e) => context.go('/connect-fpl/sync?entry=$e');

  /// App: FPL's own login page → entry id (or -1 when signed in but the team couldn't be resolved).
  Future<void> _openFplLogin() async {
    final r = await Navigator.of(context).push<int?>(MaterialPageRoute(builder: (_) => const FplLoginPage()));
    if (!mounted || r == null) return;
    if (r > 0) return _next(r);
    setState(() { manual = true; note = "You're signed in to FPL, but we couldn't find your team automatically. Enter your FPL Team ID below."; });
  }

  /// Web (and app fallback): check the id / URL with the server before moving on.
  Future<void> _find() async {
    final v = entry.text.trim();
    if (v.isEmpty) { setState(() => fieldErr = 'Enter your FPL Team ID or team URL'); return; }
    setState(() { busy = true; fieldErr = null; serverErr = null; });
    try {
      final j = await Repo.I.fplLookup(v);
      final e = jIntN(j['entry']);
      if (!mounted) return;
      if (e == null) { setState(() { busy = false; fieldErr = "We couldn't find that FPL team. Check the ID and try again."; }); return; }
      _next(e);
    } on ApiException catch (x) {
      if (!mounted) return;
      setState(() { busy = false; if (x.kind == ErrKind.validation || x.kind == ErrKind.notFound) { fieldErr = x.message; } else { serverErr = x.message; } });
    } catch (_) {
      if (mounted) setState(() { busy = false; serverErr = 'Something went wrong. Please try again.'; });
    }
  }

  @override Widget build(BuildContext c) => ListenableBuilder(listenable: Session.I, builder: (c, _) => MediaQuery.of(c).size.width >= 950 ? _desktop(c) : _mobile(c));

  // ---------- content ----------
  static const _features = [
    (Icons.emoji_events_rounded, Wz.gold, 'Sync Your Team', 'Your squad, captain and live points, updated automatically.'),
    (Icons.swap_horiz_rounded, Wz.green, 'Track Transfers', 'Keep up with your latest transfers and hits.'),
    (Icons.sports_mma_rounded, Wz.green, 'Compete in Modes', 'Ranking, Civil War, Last Survivor and Head-to-Head.'),
    (Icons.bar_chart_rounded, Wz.green, 'Live FPL Data', 'Real-time points, fixtures and player updates.'),
  ];
  List<(IconData, String)> get _trust => [
    (Icons.shield_outlined, kIsWeb ? 'Uses your public FPL data' : "Sign in on FPL's own page"),
    (Icons.lock_outline_rounded, kIsWeb ? 'Read-only on the web' : 'Your FPL password never reaches FFW'),
    (Icons.visibility_outlined, 'Your data stays private'),
    (Icons.link_off_rounded, 'Disconnect anytime'),
  ];

  Widget _title(double size, {bool center = false}) => Column(crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
    Text('Connect Your', textAlign: center ? TextAlign.center : TextAlign.start, style: anton(size, color: Colors.white, spacing: .6)),
    Text('FPL Account', textAlign: center ? TextAlign.center : TextAlign.start, style: anton(size, color: Wz.green, spacing: .6)),
  ]);
  Widget _sub(double size, {bool center = false}) => Text('Sync your team, transfers and live data. Bring your FPL journey into FFW and compete with a bigger community.',
      textAlign: center ? TextAlign.center : TextAlign.start, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: size, height: 1.45));

  /// The purple "Securely connect with Fantasy Premier League" card + primary action.
  Widget _connectCard({required bool wide}) {
    final u = Session.I.user;
    if (u == null) return _gate(wide);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (u.fpl != null) ...[_linked(u.fpl!), const SizedBox(height: 14)],
      Container(padding: EdgeInsets.all(wide ? 18 : 14), decoration: BoxDecoration(color: const Color(0xFF120C24).withValues(alpha: .85), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Wz.purple.withValues(alpha: .8), width: 1.3), boxShadow: [BoxShadow(color: Wz.purple.withValues(alpha: .25), blurRadius: 26)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(width: wide ? 52 : 44, height: wide ? 52 : 44, decoration: BoxDecoration(shape: BoxShape.circle, color: Wz.purple.withValues(alpha: .18), border: Border.all(color: Wz.purple2.withValues(alpha: .6))),
                child: Icon(Icons.sports_soccer_rounded, color: Colors.white, size: wide ? 28 : 24)),
            SizedBox(width: wide ? 16 : 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(manual ? 'Find your team on' : 'Securely connect with', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: wide ? 14.5 : 12.5)),
              Text('Fantasy Premier League', style: TextStyle(color: Colors.white, fontSize: wide ? 19 : 15.5, fontWeight: FontWeight.w700)),
            ])),
          ]),
          if (note != null) ...[const SizedBox(height: 12), Text(note!, style: const TextStyle(color: Wz.gold, fontSize: 12.5, height: 1.4))],
          if (manual) ...[
            const SizedBox(height: 14),
            AuthField(icon: Icons.tag_rounded, label: 'FPL Team ID or team URL', hint: 'e.g. 1234567', controller: entry, error: fieldErr, enabled: !busy, keyboard: TextInputType.url, onSubmitted: _find,
                onChanged: () { if (fieldErr != null) setState(() => fieldErr = null); }),
            const SizedBox(height: 8),
            const Text('Where to find it: open FPL → Points. Your Team ID is the number after /entry/ in the address.', style: TextStyle(color: Wz.muted, fontSize: 12, height: 1.4)),
          ],
        ])),
      const SizedBox(height: 14),
      if (serverErr != null) AuthErrorBanner(serverErr!, onRetry: busy ? null : (manual ? _find : _openFplLogin)),
      manual
          ? AuthCta(label: 'Find My Team', busyLabel: 'Finding your team…', icon: Icons.search_rounded, busy: busy, onPressed: _find, height: wide ? 50 : 48)
          : AuthCta(label: 'Open FPL Login', busyLabel: '', icon: Icons.open_in_new_rounded, busy: false, onPressed: _openFplLogin, height: wide ? 50 : 48),
      const SizedBox(height: 10),
      Text(manual ? (kIsWeb ? 'The web links read-only data. Transfers are confirmed in the FFW app.' : 'We only use your Team ID to read your FPL data.')
                  : "You'll sign in on FPL's official page. Your password is never shared with FFW.",
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12.5)),
      if (!kIsWeb && manual) Center(child: TextButton(onPressed: () => setState(() { manual = false; note = null; fieldErr = null; }), child: const Text('Sign in with FPL instead', style: TextStyle(color: Wz.green, fontSize: 13)))),
      Center(child: TextButton(onPressed: () => context.go('/home'), style: TextButton.styleFrom(foregroundColor: Colors.white60), child: const Text("I'll do this later", style: TextStyle(fontSize: 13)))),
    ]);
  }

  Widget _linked(int id) => Container(padding: const EdgeInsets.fromLTRB(14, 10, 8, 10), decoration: BoxDecoration(color: Wz.green.withValues(alpha: .08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.green.withValues(alpha: .45))),
    child: Row(children: [
      const Icon(Icons.check_circle_rounded, color: Wz.green, size: 20), const SizedBox(width: 10),
      Expanded(child: Text('Already connected · FPL Team ID $id', style: const TextStyle(color: Wz.text, fontSize: 13.5, fontWeight: FontWeight.w500))),
      TextButton(onPressed: () => context.go('/home'), style: TextButton.styleFrom(foregroundColor: Wz.green), child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600))),
    ]));

  /// Signed-out visitors need an FFW account first.
  Widget _gate(bool wide) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Log in to connect your FPL team', style: TextStyle(color: Wz.text, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Your FPL team is linked to your FFW account.', style: TextStyle(color: Wz.muted, fontSize: 13)),
      const SizedBox(height: 14),
      AuthCta(label: 'Login', busyLabel: '', icon: Icons.arrow_forward_rounded, busy: false, onPressed: () => context.go('/login'), height: 46),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: () => context.go('/register'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green), minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600))),
    ]));

  Widget _featureCard((IconData, Color, String, String) f) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .88), borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)),
    child: Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Icon(f.$1, color: f.$2, size: 30)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(f.$3, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)), const SizedBox(height: 4),
        Text(f.$4, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12.5, height: 1.35)),
      ])),
    ]));

  // ---------- phone ----------
  Widget _mobile(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Column(children: [
    const AuthMobileBar(fallback: '/home'),
    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(height: 230, child: Stack(children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
          Image.asset(WzAssets.stadium, fit: BoxFit.cover),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Wz.bg], stops: [.55, 1]))),
        ]))),
        Positioned.fill(top: 8, child: Image.asset(WzAssets.player10, fit: BoxFit.fitHeight, alignment: Alignment.topCenter)),
        Positioned(left: 4, top: 26, child: Transform.rotate(angle: -.18, child: Text('Real players.\nReal battles.', style: script(22)))),
        Positioned(right: 2, top: 30, child: Transform.rotate(angle: -.14, child: Text('Your FPL team\nlives here.', textAlign: TextAlign.right, style: script(22)))),
      ])),
      const SizedBox(height: 6),
      _title(30, center: true), const SizedBox(height: 10), _sub(13.5, center: true), const SizedBox(height: 18),
      _connectCard(wide: false),
      const SizedBox(height: 16),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final f in _features) Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .8), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
        child: Column(children: [Icon(f.$1, color: f.$2, size: 24), const SizedBox(height: 5), Text(f.$3, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2))])))])),
      const SizedBox(height: 14),
      for (final t in _trust) Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [const Icon(Icons.check_circle_outline_rounded, color: Wz.green, size: 18), const SizedBox(width: 10), Expanded(child: Text(t.$2, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 13)))])),
    ]))))),
  ])));

  // ---------- desktop / web ----------
  Widget _desktop(BuildContext c) {
    final showPlayer = MediaQuery.of(c).size.width >= 1240;
    return Scaffold(backgroundColor: Wz.bg, body: Stack(fit: StackFit.expand, children: [
      const AuthBackdrop(),
      Column(children: [
        const AuthTopNav(),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Padding(padding: const EdgeInsets.fromLTRB(48, 0, 36, 0), child: Column(children: [
          Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: 440, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _title(52), const SizedBox(height: 16), _sub(16), const SizedBox(height: 24), _connectCard(wide: true),
            ])))),
            Expanded(child: showPlayer ? Stack(children: [
              Positioned.fill(child: Padding(padding: const EdgeInsets.only(top: 16), child: Image.asset(WzAssets.player10, fit: BoxFit.contain, alignment: Alignment.bottomCenter))),
              Positioned(right: 0, top: 50, child: Transform.rotate(angle: -.2, child: Column(children: [Text('Same game.\nBigger battles.', textAlign: TextAlign.center, style: script(40)), const SizedBox(height: 4), const FfwCrown(size: 34, color: Wz.green)]))),
            ]) : const SizedBox(width: 24)),
            SizedBox(width: 320, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(children: [
              for (final f in _features) Padding(padding: const EdgeInsets.only(bottom: 12), child: _featureCard(f)),
            ])))),
          ])),
          Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .88), borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)),
            child: Row(children: [
              for (final (i, t) in _trust.indexed) ...[
                if (i > 0) Container(width: 1, height: 34, color: Wz.border2),
                Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(t.$1, color: Wz.green, size: 26), const SizedBox(width: 12), Flexible(child: Text(t.$2, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.3)))])),
              ],
            ])),
        ]))))),
        const AuthFooter(),
      ]),
    ]));
  }
}
