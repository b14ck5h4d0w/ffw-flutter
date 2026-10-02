import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/config.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import 'auth_chrome.dart';

/// A03 — Login. Lion crest + "Welcome Back" card (email, password, forgot, Google / Apple);
/// desktop adds the #10 player and "Play. Survive. Conquer." flourish.
/// POST /api/app/auth/login {email, password} → token + user. After login: /home.
class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState() => _LoginState(); }

class _LoginState extends State<LoginPage> {
  final email = TextEditingController(), pw = TextEditingController();
  bool busy = false, show = false; String? err, emailErr, pwErr;
  @override void dispose() { email.dispose(); pw.dispose(); super.dispose(); }

  Future<void> _go() async {
    final e = email.text.trim();
    setState(() { emailErr = e.isEmpty ? 'Enter your email address' : null; pwErr = pw.text.isEmpty ? 'Enter your password' : null; err = null; });
    if (emailErr != null || pwErr != null || busy) return;
    setState(() => busy = true);
    try { await Session.I.login(e, pw.text); if (mounted) context.go('/home'); }
    on ApiException catch (x) { if (mounted) setState(() { busy = false; err = x.kind == ErrKind.rateLimited ? 'Too many attempts. Please wait a moment.' : x.message; }); }
    catch (_) { if (mounted) setState(() { busy = false; err = 'Something went wrong. Please try again.'; }); }
  }
  void _google() => launchUrl(Uri.parse('${Config.baseUrl}/login/google?next=/auth/google/done'), webOnlyWindowName: '_self');
  void _apple() => toast(context, 'Apple sign-in is coming soon.');
  void _forgot() { final e = email.text.trim(); context.push(e.contains('@') ? '/forgot?email=${Uri.encodeQueryComponent(e)}' : '/forgot'); }

  Widget _social(String label, Widget icon, VoidCallback on) => SizedBox(height: 46, child: OutlinedButton(onPressed: on, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), backgroundColor: Wz.bg.withValues(alpha: .5), side: const BorderSide(color: Wz.border2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [icon, const SizedBox(width: 8), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)))])));

  Widget _form({required bool card}) => AutofillGroup(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
    Center(child: Image.asset(WzAssets.emblem, width: card ? 150 : 170, height: card ? 150 : 170)),
    const SizedBox(height: 6),
    Text('Welcome Back', textAlign: TextAlign.center, style: anton(card ? 34 : 32, color: Colors.white, spacing: .6)),
    const SizedBox(height: 6),
    Text('Log in to your FFW Warzone account\nand continue your journey.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 14, height: 1.4)),
    const SizedBox(height: 20),
    AuthField(icon: Icons.mail_outline_rounded, label: 'Email address', hint: 'you@example.com', controller: email, error: emailErr, enabled: !busy, keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.username, AutofillHints.email], onChanged: () { if (emailErr != null || err != null) setState(() { emailErr = null; err = null; }); }),
    const SizedBox(height: 10),
    AuthField(icon: Icons.lock_outline_rounded, label: 'Password', hint: 'Your password', controller: pw, error: pwErr, enabled: !busy, obscure: !show, autofill: const [AutofillHints.password], onSubmitted: _go, onChanged: () { if (pwErr != null || err != null) setState(() { pwErr = null; err = null; }); },
        trailing: IconButton(onPressed: () => setState(() => show = !show), tooltip: show ? 'Hide password' : 'Show password', icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Wz.text, size: 21))),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgot, style: TextButton.styleFrom(foregroundColor: Wz.green, padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('Forgot password?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)))),
    if (err != null) AuthErrorBanner(err!),
    AuthCta(label: 'Login', busyLabel: 'Logging in…', icon: Icons.arrow_forward_rounded, busy: busy, onPressed: _go),
    const SizedBox(height: 16),
    Row(children: [const Expanded(child: Divider(color: Wz.border2)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR CONTINUE WITH', style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1))), const Expanded(child: Divider(color: Wz.border2))]),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: _social('Google', const _GoogleG(), _google)), const SizedBox(width: 10),
      Expanded(child: _social('Apple', const Icon(Icons.apple, color: Colors.white, size: 21), _apple)),
    ]),
    const SizedBox(height: 18),
    Center(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text("Don't have an account?  ", style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 14)),
      InkWell(onTap: () => context.go('/register'), child: const Text('Create Account', style: TextStyle(color: Wz.green, fontSize: 14, fontWeight: FontWeight.w600))),
    ])),
  ]));

  @override Widget build(BuildContext c) => MediaQuery.of(c).size.width >= 950 ? _desktop(c) : _mobile(c);

  Widget _mobile(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: Stack(children: [
    Positioned(top: 0, left: 0, right: 0, height: 360, child: Stack(fit: StackFit.expand, children: [
      Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Wz.bg.withValues(alpha: .3), Wz.bg.withValues(alpha: .65), Wz.bg], stops: const [0, .6, 1]))),
    ])),
    SafeArea(child: Column(children: [
      SizedBox(height: 48, child: Row(children: [IconButton(onPressed: () => c.canPop() ? c.pop() : c.go('/welcome'), tooltip: 'Back', icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)), const Spacer(), TextButton(onPressed: () => c.go('/home'), child: Text('Skip', style: TextStyle(color: Colors.white.withValues(alpha: .75))))])),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 0, 22, 24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(children: [
        _form(card: false),
        const SizedBox(height: 22),
        Transform.rotate(angle: -.08, child: Text('Different players.\nSame passion.', textAlign: TextAlign.center, style: script(24))),
      ]))))),
    ])),
  ]));

  Widget _desktop(BuildContext c) {
    final showPlayer = MediaQuery.of(c).size.width >= 1180;
    return Scaffold(backgroundColor: Wz.bg, body: Stack(fit: StackFit.expand, children: [
      const AuthBackdrop(),
      Column(children: [
        const AuthTopNav(),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 60), child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 22), child: Container(width: 420, padding: const EdgeInsets.fromLTRB(30, 22, 30, 26),
            decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .9), borderRadius: BorderRadius.circular(14), border: Border.all(color: Wz.green.withValues(alpha: .55), width: 1.2), boxShadow: [BoxShadow(color: Wz.green.withValues(alpha: .15), blurRadius: 32)]),
            child: _form(card: true)))),
          Expanded(child: showPlayer ? Stack(children: [
            Positioned.fill(child: Padding(padding: const EdgeInsets.only(top: 20), child: Image.asset(WzAssets.player10, fit: BoxFit.contain, alignment: Alignment.bottomCenter))),
            Positioned(right: 0, top: 90, child: Transform.rotate(angle: -.16, child: Column(children: [const FfwCrown(size: 36, color: Wz.green), const SizedBox(height: 6), Text('Play.\nSurvive.\nConquer.', textAlign: TextAlign.center, style: script(46))]))),
            const Positioned(right: 0, bottom: 60, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('MORE THAN A GAME.', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 3.5)),
              Text('A BATTLE OF MINDS.', style: TextStyle(color: Wz.green, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 3.5)),
            ])),
          ]) : const SizedBox()),
        ]))))),
        const AuthFooter(),
      ]),
    ]));
  }
}

/// Four-colour Google "G" mark.
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override Widget build(BuildContext c) => ShaderMask(blendMode: BlendMode.srcIn,
    shaderCallback: (r) => const SweepGradient(colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4), Color(0xFFEA4335)], stops: [0, .25, .5, .75, 1]).createShader(r),
    child: const Text('G', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1)));
}

/// /auth/google/done#token=… — finishes Google sign-in by exchanging the one-time code.
class GoogleDonePage extends StatefulWidget { const GoogleDonePage({super.key}); @override State<GoogleDonePage> createState() => _GoogleDoneState(); }
class _GoogleDoneState extends State<GoogleDonePage> {
  @override void initState() { super.initState(); _run(); }
  Future<void> _run() async {
    final code = RegExp(r'token=([^&]+)').firstMatch(Uri.base.fragment)?.group(1);
    try {
      if (code == null) throw ApiException(ErrKind.validation, 'no_code', 'Google sign-in did not complete. Please try again.');
      await Session.I.exchange(code);
      if (mounted) context.go(Session.I.user?.fpl == null ? '/connect-fpl' : '/home');
    } catch (e) { if (mounted) { toast(context, e.toString(), error: true); context.go('/login'); } }
  }
  @override Widget build(BuildContext c) => const Scaffold(backgroundColor: Wz.bg, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Wz.green), SizedBox(height: 16), Text('Signing you in…', style: TextStyle(color: Wz.muted))])));
}
