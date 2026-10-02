import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/config.dart';
import '../../core/countries.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import 'auth_chrome.dart';

/// A04 — Register / Create Account.
/// Phone: stadium header + stacked form. Desktop (≥950): nav bar, lion crest + value props,
/// #10 player hero, glowing two-column form card.
/// Country/Region is part of the form but is saved with a profile update right after the
/// account is created (the register endpoint doesn't take it).
class RegisterPage extends StatefulWidget { const RegisterPage({super.key}); @override State<RegisterPage> createState() => _RegisterState(); }

class _RegisterState extends State<RegisterPage> {
  final name = TextEditingController(), email = TextEditingController(), pw = TextEditingController(), pw2 = TextEditingController(), fpl = TextEditingController();
  String? country, err; bool agree = false, showPw = false, showPw2 = false, busy = false;
  Map<String, String> errs = {};

  @override void dispose() { for (final t in [name, email, pw, pw2, fpl]) { t.dispose(); } super.dispose(); }

  bool _validate() {
    final e = <String, String>{};
    if (name.text.trim().isEmpty) e['name'] = 'Enter your full name';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) e['email'] = 'Enter a valid email address';
    if (pw.text.length < 8) e['pw'] = 'Use at least 8 characters';
    if (pw2.text != pw.text) e['pw2'] = "Passwords don't match";
    if (country == null) e['country'] = 'Select your country or region';
    if (fpl.text.trim().isNotEmpty && int.tryParse(fpl.text.trim()) == null) e['fpl'] = 'FPL ID is a number, e.g. 1234567';
    setState(() { errs = e; err = agree ? null : 'Please accept the Terms of Service and Privacy Policy.'; });
    return e.isEmpty && agree;
  }

  Future<void> _submit() async {
    if (busy || !_validate()) return;
    setState(() { busy = true; err = null; });
    try {
      await Session.I.register(name.text.trim(), email.text.trim(), pw.text, fpl: fpl.text.trim());
    } on ApiException catch (e) {
      if (mounted) setState(() { busy = false; err = e.problems.isEmpty ? e.message : e.problems.join('\n'); });
      return;
    } catch (_) {
      if (mounted) setState(() { busy = false; err = 'Something went wrong. Please try again.'; });
      return;
    }
    // Account exists now — save the country quietly; a failure here must not block sign-up
    // (it can still be set from the profile).
    try { await Repo.I.updateMe({'name': name.text.trim(), 'country': country}); await Session.I.refreshMe(); } catch (_) {}
    // Onboarding: straight to the team if the FPL id was linked at sign-up, otherwise A06.
    if (mounted) context.go(Session.I.user?.fpl != null ? '/connect-fpl/done' : '/connect-fpl');
  }

  void _google() => launchUrl(Uri.parse('${Config.baseUrl}/login/google?next=/auth/google/done'), webOnlyWindowName: '_self');
  void _apple() => toast(context, 'Apple sign-in is coming soon.');

  Future<void> _pickCountry() async {
    final wide = MediaQuery.of(context).size.width >= 950;
    final picked = wide
        ? await showDialog<String>(context: context, builder: (_) => Dialog(backgroundColor: Wz.panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Wz.border2)), child: SizedBox(width: 440, height: 560, child: _CountryPicker(selected: country))))
        : await showModalBottomSheet<String>(context: context, isScrollControlled: true, backgroundColor: Wz.panel, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))), builder: (c) => SizedBox(height: MediaQuery.of(c).size.height * .78, child: _CountryPicker(selected: country)));
    if (picked != null) setState(() { country = picked; errs.remove('country'); });
  }

  @override Widget build(BuildContext c) => MediaQuery.of(c).size.width >= 950 ? _desktop(c) : _mobile(c);

  // ---------- form pieces ----------
  Widget _title(double size) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
    Text('Create Your', style: anton(size, color: Colors.white, spacing: .6)),
    Text('Warzone Account', style: anton(size, color: Wz.green, spacing: .6)),
  ]);
  Widget _subtitle(double size) => Text('Join the FPL warriors.\nBuild your legacy. The game never stops.', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: size, height: 1.45));

  Widget _name() => AuthField(icon: Icons.person_outline_rounded, label: 'Full Name', hint: 'Enter your full name', controller: name, error: errs['name'], autofill: const [AutofillHints.name], onChanged: () => _clear('name'));
  Widget _email() => AuthField(icon: Icons.mail_outline_rounded, label: 'Email Address', hint: 'you@example.com', controller: email, error: errs['email'], keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email], onChanged: () => _clear('email'));
  Widget _pw() => AuthField(icon: Icons.lock_outline_rounded, label: 'Password', hint: 'Create a strong password', controller: pw, error: errs['pw'], obscure: !showPw, autofill: const [AutofillHints.newPassword], onChanged: () => _clear('pw'),
      trailing: _eye(showPw, () => setState(() => showPw = !showPw)));
  Widget _pw2() => AuthField(icon: Icons.lock_outline_rounded, label: 'Confirm Password', hint: 'Confirm your password', controller: pw2, error: errs['pw2'], obscure: !showPw2, autofill: const [AutofillHints.newPassword], onChanged: () => _clear('pw2'),
      trailing: _eye(showPw2, () => setState(() => showPw2 = !showPw2)));
  Widget _country() => AuthField(icon: Icons.language_rounded, label: 'Country / Region', hint: 'Select your country', value: country, error: errs['country'], onTap: _pickCountry,
      trailing: const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.keyboard_arrow_down_rounded, color: Wz.text, size: 24)));
  Widget _fpl() => AuthField(icon: Icons.tag_rounded, label: 'FPL Team ID (optional)', hint: 'e.g. 1234567', controller: fpl, error: errs['fpl'], keyboard: TextInputType.number, onChanged: () => _clear('fpl'), onSubmitted: _submit);
  Widget _eye(bool on, VoidCallback f) => IconButton(onPressed: f, tooltip: on ? 'Hide password' : 'Show password', icon: Icon(on ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Wz.text, size: 21));
  void _clear(String k) { if (errs.containsKey(k)) setState(() => errs.remove(k)); }

  Widget _terms(double font) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
    SizedBox(width: 22, height: 22, child: Checkbox(value: agree, onChanged: (v) => setState(() { agree = v ?? false; if (agree) err = null; }), activeColor: Wz.green, checkColor: Wz.onPrimary, side: const BorderSide(color: Wz.border2, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
    const SizedBox(width: 12),
    Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text('I agree to the ', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: font)),
      _link('Terms of Service', 'terms', font),
      Text(' and ', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: font)),
      _link('Privacy Policy', 'privacy', font),
    ])),
  ]);
  Widget _link(String t, String kind, double font) => InkWell(onTap: () => context.push('/legal/$kind'), borderRadius: BorderRadius.circular(4), child: Text(t, style: TextStyle(color: Wz.green, fontSize: font, fontWeight: FontWeight.w600)));

  Widget _error() => err == null ? const SizedBox.shrink() : AuthErrorBanner(err!);
  Widget _cta(double h) => AuthCta(label: 'Create Account', busyLabel: 'Creating account…', icon: Icons.arrow_forward_rounded, busy: busy, onPressed: _submit, height: h);

  Widget _socials(double h, double font) => Row(children: [
    Expanded(child: _social('Continue with Google', const _GoogleG(), _google, h, font)),
    const SizedBox(width: 12),
    Expanded(child: _social('Continue with Apple', const Icon(Icons.apple, color: Colors.white, size: 22), _apple, h, font)),
  ]);
  Widget _social(String label, Widget icon, VoidCallback on, double h, double font) => SizedBox(height: h, child: OutlinedButton(onPressed: on,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), backgroundColor: Wz.bg.withValues(alpha: .5), side: const BorderSide(color: Wz.border2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [icon, SizedBox(width: font * .6), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: font, fontWeight: FontWeight.w500)))])));

  Widget _login(double font) => Center(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
    Text('Already have an account?  ', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: font)),
    InkWell(onTap: () => context.go('/login'), child: Text('Login', style: TextStyle(color: Wz.green, fontSize: font, fontWeight: FontWeight.w600))),
  ]));

  // ---------- phone ----------
  Widget _mobile(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: Stack(children: [
    Positioned(top: 0, left: 0, right: 0, height: 340, child: Stack(fit: StackFit.expand, children: [
      Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Wz.bg.withValues(alpha: .35), Wz.bg.withValues(alpha: .7), Wz.bg], stops: const [0, .6, 1]))),
    ])),
    SafeArea(child: Column(children: [
      const AuthMobileBar(),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: AutofillGroup(child: Column(children: [
        Center(child: Column(children: [
          Text('Create Your', textAlign: TextAlign.center, style: anton(29, color: Colors.white, spacing: .6)),
          Text('Warzone Account', textAlign: TextAlign.center, style: anton(29, color: Wz.green, spacing: .6)),
          const SizedBox(height: 10),
          Text('Join the FPL warriors.\nBuild your legacy. The game never stops.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 13.5, height: 1.45)),
        ])),
        const SizedBox(height: 22),
        _name(), const SizedBox(height: 10), _email(), const SizedBox(height: 10), _pw(), const SizedBox(height: 10), _pw2(), const SizedBox(height: 10), _country(), const SizedBox(height: 10), _fpl(),
        const SizedBox(height: 16), _terms(12.5), const SizedBox(height: 16),
        _error(), _cta(48), const SizedBox(height: 14), const AuthOr(), const SizedBox(height: 14), _socials(46, 11.5),
        const SizedBox(height: 20), _login(13.5),
      ])))))),
    ])),
  ]));

  // ---------- desktop / web ----------
  Widget _desktop(BuildContext c) {
    final w = MediaQuery.of(c).size.width; final showPlayer = w >= 1240;
    return Scaffold(backgroundColor: Wz.bg, body: Stack(fit: StackFit.expand, children: [
      const AuthBackdrop(),
      Column(children: [
        const AuthTopNav(),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 36), child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: 370, child: _pitchSide()),
          Expanded(child: showPlayer ? Padding(padding: const EdgeInsets.only(top: 24), child: Image.asset(WzAssets.player10, fit: BoxFit.contain, alignment: Alignment.bottomCenter)) : const SizedBox()),
          Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 24), child: _card())),
        ]))))),
      ]),
    ]));
  }

  Widget _pitchSide() => SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 28), child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Center(child: Image.asset(WzAssets.emblem, width: 230, height: 230)),
    const SizedBox(height: 18),
    const Text('MORE THAN A GAME.', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: 4.5)),
    const SizedBox(height: 4),
    const Text('A BATTLE OF MINDS.', style: TextStyle(color: Wz.green, fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: 4.5)),
    const SizedBox(height: 30),
    _prop(Icons.emoji_events_rounded, Wz.gold, 'REAL LEAGUES', 'Real Competition'),
    _prop(Icons.groups_rounded, Wz.green, 'REAL COMMUNITY', 'FPL Warriors'),
    _prop(Icons.bar_chart_rounded, Wz.green, 'REAL GLORY', 'Build Your Legacy'),
    const SizedBox(height: 18),
    Row(children: [Text('Play. Survive. Conquer.', style: script(34)), const SizedBox(width: 10), const FfwCrown(size: 26, color: Wz.green)]),
    const SizedBox(height: 28),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _strip(Icons.sync_rounded, 'Live FPL', 'Sync'),
      _strip(Icons.sports_esports_rounded, 'Competitive', 'Game Modes'),
      _strip(Icons.shield_outlined, 'Clans &', 'Private Leagues'),
    ]),
  ])));
  Widget _prop(IconData i, Color col, String t, String s) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
    Container(width: 46, height: 46, decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Wz.border2)), child: Icon(i, color: col, size: 26)),
    const SizedBox(width: 16),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: .4)), const SizedBox(height: 2), Text(s, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 13))]),
  ]));
  Widget _strip(IconData i, String a, String b) => Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(i, color: Wz.green, size: 22), const SizedBox(width: 7),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.25)), Text(b, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12, height: 1.25))])),
  ]));

  Widget _card() => Container(width: 600, padding: const EdgeInsets.fromLTRB(34, 32, 34, 28),
    decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .9), borderRadius: BorderRadius.circular(14), border: Border.all(color: Wz.green.withValues(alpha: .6), width: 1.2), boxShadow: [BoxShadow(color: Wz.green.withValues(alpha: .16), blurRadius: 34, spreadRadius: 1)]),
    child: AutofillGroup(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _title(38)),
        Transform.rotate(angle: -.12, child: Text('Legends\nNever Retire.', textAlign: TextAlign.center, style: script(30))),
      ]),
      const SizedBox(height: 12), _subtitle(15.5), const SizedBox(height: 26),
      _pair(_name(), _email()), const SizedBox(height: 14),
      _pair(_pw(), _pw2()), const SizedBox(height: 14),
      _pair(_country(), _fpl()), const SizedBox(height: 20),
      _terms(13.5), const SizedBox(height: 20),
      _error(), _cta(50), const SizedBox(height: 18), const AuthOr(), const SizedBox(height: 18), _socials(46, 14),
      const SizedBox(height: 22), _login(14.5),
    ])));
  Widget _pair(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 14), Expanded(child: b)]);
}

/// Searchable country list; pops with the chosen name.
class _CountryPicker extends StatefulWidget { final String? selected; const _CountryPicker({this.selected}); @override State<_CountryPicker> createState() => _CountryPickerState(); }
class _CountryPickerState extends State<_CountryPicker> {
  String q = '';
  @override Widget build(BuildContext c) {
    final list = q.isEmpty ? kCountries : kCountries.where((x) => x.toLowerCase().contains(q.toLowerCase())).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 18, 12, 6), child: Row(children: [Text('COUNTRY / REGION', style: anton(18, color: Wz.text)), const Spacer(), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close_rounded, color: Wz.muted))])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(autofocus: true, onChanged: (v) => setState(() => q = v.trim()), style: const TextStyle(color: Wz.text),
          decoration: const InputDecoration(hintText: 'Search country', prefixIcon: Icon(Icons.search_rounded, color: Wz.muted), isDense: true))),
      const SizedBox(height: 8),
      Expanded(child: list.isEmpty
          ? const Center(child: Muted('No match'))
          : ListView.builder(itemCount: list.length, itemBuilder: (_, i) { final x = list[i]; final sel = x == widget.selected;
              return ListTile(dense: true, title: Text(x, style: TextStyle(color: sel ? Wz.green : Wz.text, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)), trailing: sel ? const Icon(Icons.check_rounded, color: Wz.green, size: 20) : null, onTap: () => Navigator.pop(c, x)); })),
    ]);
  }
}

/// Four-colour Google "G" mark.
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override Widget build(BuildContext c) => ShaderMask(blendMode: BlendMode.srcIn,
    shaderCallback: (r) => const SweepGradient(colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4), Color(0xFFEA4335)], stops: [0, .25, .5, .75, 1]).createShader(r),
    child: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1)));
}
