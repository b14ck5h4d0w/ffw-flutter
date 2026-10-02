import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import 'auth_chrome.dart';
import 'recovery_layout.dart';

/// A05 (reset half) — /reset?token=… from the reset email.
/// POST /api/app/auth/reset {token, password} → {token, user}: the user is signed in on success.
/// Errors: 400 invalid_token (bad / used / older than 1 hour) → expired state;
/// 422 weak_password → field error; 429 rate_limited → banner.
class ResetPage extends StatefulWidget { final String token; const ResetPage(this.token, {super.key}); @override State<ResetPage> createState() => _ResetState(); }

enum _Stage { form, done, expired }

const _tips = [(Icons.password_rounded, 'Use at least 8 characters'), (Icons.shuffle_rounded, 'Mix letters, numbers and symbols'), (Icons.block_rounded, "Don't reuse your FPL or email password")];

class _ResetState extends State<ResetPage> {
  final pw = TextEditingController(), pw2 = TextEditingController();
  late _Stage stage = widget.token.trim().isEmpty ? _Stage.expired : _Stage.form;
  String? pwErr, pw2Err, serverErr, expiredMsg; bool busy = false, show = false, show2 = false;

  @override void initState() { super.initState(); for (final t in [pw, pw2]) { t.addListener(() => setState(() {})); } }
  @override void dispose() { pw.dispose(); pw2.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final e1 = pw.text.length < 8 ? 'Use at least 8 characters' : null;
    final e2 = pw2.text != pw.text ? "Passwords don't match" : null;
    setState(() { pwErr = e1; pw2Err = e2; serverErr = null; });
    if (e1 != null || e2 != null || busy) return;
    setState(() => busy = true);
    try {
      await Session.I.reset(widget.token.trim(), pw.text);
      if (mounted) setState(() { busy = false; stage = _Stage.done; });
    } on ApiException catch (x) {
      if (!mounted) return;
      setState(() {
        busy = false;
        switch (x.code) {
          case 'invalid_token': stage = _Stage.expired; expiredMsg = x.message;
          case 'weak_password': pwErr = x.message;
          default: serverErr = x.kind == ErrKind.rateLimited ? 'Too many attempts. Please wait a while and try again.' : x.message;
        }
      });
    } catch (_) {
      if (mounted) setState(() { busy = false; serverErr = 'Something went wrong. Please try again.'; });
    }
  }

  @override Widget build(BuildContext c) {
    const side = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RecoveryEyebrow('PASSWORD TIPS'), SizedBox(height: 18), RecoveryList(_tips), Spacer(), SizedBox(height: 18),
      SafeNote(title: 'Straight back in', body: "Once your password is updated you'll be signed in automatically — no extra login."),
    ]);
    return switch (stage) {
      _Stage.form => RecoveryScaffold(desktopMain: _form(wide: true), desktopSide: side, mobileBody: _form(wide: false)),
      _Stage.done => RecoveryScaffold(glowMain: true, mobilePlayer: false, backToLogin: false, desktopMain: _done(), desktopSide: side, mobileBody: _card(_done())),
      _Stage.expired => RecoveryScaffold(mobilePlayer: false, desktopMain: _expired(), desktopSide: side, mobileBody: _card(_expired(), accent: Wz.gold)),
    };
  }

  Widget _card(Widget child, {Color accent = Wz.green}) => Container(padding: const EdgeInsets.fromLTRB(18, 26, 18, 20), decoration: authCardDeco(glow: true, accent: accent), child: child);

  Widget _eye(bool on, VoidCallback f) => IconButton(onPressed: f, tooltip: on ? 'Hide password' : 'Show password', icon: Icon(on ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Wz.text, size: 21));

  Widget _form({required bool wide}) => AutofillGroup(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
    if (wide) ...[const RecoveryEyebrow('ACCOUNT RECOVERY'), const SizedBox(height: 12)],
    Padding(padding: EdgeInsets.only(right: wide ? 0 : 110), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Create New', style: anton(wide ? 44 : 32, color: Colors.white, spacing: .6)),
      Text('Password', style: anton(wide ? 44 : 32, color: Wz.green, spacing: .6)),
      const SizedBox(height: 12),
      Text('Choose a strong password you haven\'t used before. You\'ll be signed straight back in.', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: wide ? 15 : 13, height: 1.45)),
    ])),
    SizedBox(height: wide ? 24 : 20),
    AuthField(icon: Icons.lock_outline_rounded, label: 'New Password', hint: 'At least 8 characters', controller: pw, error: pwErr, obscure: !show, enabled: !busy, autofocus: wide, autofill: const [AutofillHints.newPassword],
        onChanged: () { if (pwErr != null) setState(() => pwErr = null); }, trailing: _eye(show, () => setState(() => show = !show))),
    const SizedBox(height: 12),
    AuthField(icon: Icons.lock_outline_rounded, label: 'Confirm New Password', hint: 'Type it again', controller: pw2, error: pw2Err, obscure: !show2, enabled: !busy, autofill: const [AutofillHints.newPassword], onSubmitted: _submit,
        onChanged: () { if (pw2Err != null) setState(() => pw2Err = null); }, trailing: _eye(show2, () => setState(() => show2 = !show2))),
    const SizedBox(height: 14),
    _check(pw.text.length >= 8, 'At least 8 characters'),
    _check(RegExp(r'[A-Za-z]').hasMatch(pw.text) && RegExp(r'\d').hasMatch(pw.text), 'Letters and numbers (recommended)'),
    _check(pw2.text.isNotEmpty && pw2.text == pw.text, 'Passwords match'),
    const SizedBox(height: 18),
    if (serverErr != null) AuthErrorBanner(serverErr!, onRetry: busy ? null : _submit),
    AuthCta(label: 'Update Password', busyLabel: 'Updating…', icon: Icons.check_rounded, busy: busy, onPressed: _submit, height: wide ? 50 : 48),
  ]));

  Widget _check(bool ok, String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
    Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 17, color: ok ? Wz.green : Wz.faint),
    const SizedBox(width: 8), Text(t, style: TextStyle(color: ok ? Wz.text : Wz.muted, fontSize: 12.5)),
  ]));

  Widget _done() {
    final name = Session.I.user?.name ?? '';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const StatusBadge(Icons.verified_rounded),
      const SizedBox(height: 18),
      Text('Password Updated', textAlign: TextAlign.center, style: anton(30, color: Colors.white, spacing: .6)),
      const SizedBox(height: 10),
      Text(name.isEmpty ? "You're signed in and ready to go." : "You're signed in as $name.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 14.5)),
      const SizedBox(height: 6),
      const Text('Use your new password next time you log in on another device.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.4)),
      const SizedBox(height: 22),
      AuthCta(label: 'Continue to FFW', busyLabel: '', icon: Icons.arrow_forward_rounded, busy: false, onPressed: () => context.go('/home'), height: 48),
    ]);
  }

  Widget _expired() => Column(mainAxisSize: MainAxisSize.min, children: [
    const StatusBadge(Icons.link_off_rounded, color: Wz.gold),
    const SizedBox(height: 18),
    Text('Link Expired', textAlign: TextAlign.center, style: anton(30, color: Colors.white, spacing: .6)),
    const SizedBox(height: 10),
    Text(expiredMsg ?? 'This reset link is invalid or has expired.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 14.5, height: 1.4)),
    const SizedBox(height: 6),
    const Text('Reset links work once and last 1 hour. Request a new one and use the latest email.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.4)),
    const SizedBox(height: 22),
    AuthCta(label: 'Request a New Link', busyLabel: '', icon: Icons.send_rounded, busy: false, onPressed: () => context.go('/forgot'), height: 48),
  ]);
}
