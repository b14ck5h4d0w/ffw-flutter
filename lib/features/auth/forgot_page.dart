import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import 'auth_chrome.dart';
import 'recovery_layout.dart';

/// A05 — Forgot password. Two states: email form → "Check your email" (masked address,
/// resend cooldown, back to login). The API always answers {ok:true} (it never reveals whether
/// an account exists), so the email format is checked here and the copy stays neutral.
/// Reset links are single-use and valid for 1 hour (backend contract).
class ForgotPage extends StatefulWidget { final String initialEmail; const ForgotPage({super.key, this.initialEmail = ''}); @override State<ForgotPage> createState() => _ForgotState(); }

const _steps = [(Icons.mail_outline_rounded, 'Open your email inbox'), (Icons.ads_click_rounded, 'Click the reset link'), (Icons.lock_outline_rounded, 'Create a new password')];
const _safe = SafeNote(title: "We'll keep your account safe", body: 'Your reset link works once and expires after 1 hour. We never ask for your password.');

class _ForgotState extends State<ForgotPage> {
  static const _cooldown = 60;
  late final email = TextEditingController(text: widget.initialEmail);
  String? fieldErr, serverErr, sentTo; bool busy = false; int wait = 0; Timer? _timer;

  @override void dispose() { _timer?.cancel(); email.dispose(); super.dispose(); }

  bool get _sent => sentTo != null;

  Future<void> _send({bool resend = false}) async {
    final e = resend ? sentTo! : email.text.trim();
    if (!resend && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) { setState(() => fieldErr = 'Enter a valid email address'); return; }
    setState(() { busy = true; serverErr = null; fieldErr = null; });
    try {
      await Session.I.forgot(e);
      if (!mounted) return;
      setState(() { sentTo = e; busy = false; });
      _startCooldown();
      if (resend) toast(context, 'A new reset link is on its way.');
    } on ApiException catch (x) {
      if (mounted) setState(() { busy = false; serverErr = x.kind == ErrKind.rateLimited ? 'Too many requests. Please wait a while and try again.' : x.message; });
    } catch (_) {
      if (mounted) setState(() { busy = false; serverErr = 'Something went wrong. Please try again.'; });
    }
  }

  void _startCooldown() {
    _timer?.cancel(); setState(() => wait = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) { if (!mounted) return t.cancel(); setState(() => wait--); if (wait <= 0) t.cancel(); });
  }

  void _changeEmail() { _timer?.cancel(); setState(() { sentTo = null; wait = 0; serverErr = null; }); }

  static String mask(String e) => ForgotPageMask.mask(e);

  @override Widget build(BuildContext c) => RecoveryScaffold(
    glowMain: _sent, mobilePlayer: !_sent,
    desktopMain: _sent ? _sentBody(steps: false) : _formBody(wide: true),
    desktopSide: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [RecoveryEyebrow('WHAT HAPPENS NEXT'), SizedBox(height: 18), RecoveryList(_steps), Spacer(), SizedBox(height: 18), _safe]),
    mobileBody: _sent
        ? Container(padding: const EdgeInsets.fromLTRB(18, 26, 18, 14), decoration: authCardDeco(glow: true), child: _sentBody(steps: true))
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_formBody(wide: false), const SizedBox(height: 18), _safe]),
  );

  Widget _formBody({required bool wide}) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
    if (wide) ...[const RecoveryEyebrow('ACCOUNT RECOVERY'), const SizedBox(height: 12)],
    // Phone: keep the copy clear of the player on the right; the inputs stay full width.
    Padding(padding: EdgeInsets.only(right: wide ? 0 : 110), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Reset Your', style: anton(wide ? 44 : 32, color: Colors.white, spacing: .6)),
      Text('Password', style: anton(wide ? 44 : 32, color: Colors.white, spacing: .6)),
      const SizedBox(height: 12),
      Text(wide ? "No worries. It happens to the best managers. Enter your registered email address and we'll send you a secure link to reset your password."
                : 'No worries. It happens to the best managers. Enter your registered email to receive a reset link.',
          style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: wide ? 15 : 13, height: 1.45)),
    ])),
    SizedBox(height: wide ? 24 : 20),
    AutofillGroup(child: AuthField(icon: Icons.mail_outline_rounded, label: 'Enter your email address', hint: 'e.g. manager@email.com', controller: email, error: fieldErr, enabled: !busy,
        keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email], onSubmitted: _send, onChanged: () { if (fieldErr != null || serverErr != null) setState(() { fieldErr = null; serverErr = null; }); })),
    const SizedBox(height: 18),
    if (serverErr != null) AuthErrorBanner(serverErr!, onRetry: busy ? null : _send),
    AuthCta(label: 'Send Reset Link', busyLabel: 'Sending link…', icon: Icons.send_rounded, busy: busy, onPressed: _send, height: wide ? 50 : 48),
  ]);

  Widget _sentBody({required bool steps}) => Column(mainAxisSize: MainAxisSize.min, children: [
    const StatusBadge(Icons.mark_email_read_outlined),
    const SizedBox(height: 18),
    Text('Check Your Email', textAlign: TextAlign.center, style: anton(30, color: Colors.white, spacing: .6)),
    const SizedBox(height: 10),
    Text("We've sent a password reset link to", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 14.5)),
    const SizedBox(height: 4),
    Text(mask(sentTo!), textAlign: TextAlign.center, style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    const Text("If it's registered with FFW, it should arrive within a few minutes. Check your spam folder too. The link expires in 1 hour.", textAlign: TextAlign.center, style: TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.4)),
    if (steps) ...[const SizedBox(height: 18), const RecoveryList(_steps)],
    const SizedBox(height: 20),
    if (serverErr != null) AuthErrorBanner(serverErr!, onRetry: busy || wait > 0 ? null : () => _send(resend: true)),
    SizedBox(width: double.infinity, height: 46, child: OutlinedButton.icon(onPressed: busy || wait > 0 ? null : () => _send(resend: true),
      style: OutlinedButton.styleFrom(foregroundColor: Wz.green, disabledForegroundColor: Wz.muted, side: BorderSide(color: wait > 0 ? Wz.border2 : Wz.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.green)) : const Icon(Icons.refresh_rounded, size: 19),
      label: Text(busy ? 'Resending…' : wait > 0 ? 'Resend link in 0:${wait.toString().padLeft(2, '0')}' : 'Resend link', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)))),
    const SizedBox(height: 6),
    TextButton(onPressed: busy ? null : _changeEmail, style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text('Use a different email', style: TextStyle(fontSize: 13.5))),
  ]);
}

/// Masks the local part of an email for display: s********n@example.com.
abstract final class ForgotPageMask {
  static String mask(String e) {
    final at = e.indexOf('@'); if (at < 1) return e;
    final u = e.substring(0, at), d = e.substring(at);
    return u.length <= 2 ? '${u[0]}${'*' * (u.length - 1)}$d' : '${u[0]}${'*' * (u.length - 2)}${u[u.length - 1]}$d';
  }
}
