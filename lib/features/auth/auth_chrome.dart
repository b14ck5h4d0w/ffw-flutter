import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/session.dart';
import '../../core/theme.dart';

/// Shared chrome for the signed-out auth screens (A04 Register, A05 Forgot/Reset, …).

/// Desktop nav bar: wordmark · links · search / notifications / Login.
class AuthTopNav extends StatelessWidget {
  const AuthTopNav({super.key});
  static const _links = [('Home', '/home'), ('Leagues', '/leagues'), ('Modes', '/modes'), ('Community', '/clans'), ('Help', '/about')];
  @override Widget build(BuildContext c) => Container(height: 72, padding: const EdgeInsets.symmetric(horizontal: 36),
    decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .82), border: const Border(bottom: BorderSide(color: Wz.border))),
    child: Row(children: [
      InkWell(onTap: () => c.go('/welcome'), child: const FfwWordmark(height: 30)),
      const SizedBox(width: 56),
      ..._links.map((l) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: TextButton(onPressed: () => c.go(l.$2), style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), child: Text(l.$1, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500))))),
      const Spacer(),
      IconButton(onPressed: () => c.go('/players'), tooltip: 'Search players', icon: const Icon(Icons.search_rounded, color: Colors.white, size: 25)),
      const SizedBox(width: 6),
      IconButton(onPressed: () => c.go('/notifications'), tooltip: 'Notifications', icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 25)),
      const SizedBox(width: 12),
      if (Session.I.loggedIn) InkWell(onTap: () => c.go('/me'), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Row(children: [
        HexAvatar(Session.I.user!.initials, url: Session.I.user!.avatar, size: 36), const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Session.I.user!.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const Text('FPL Manager', style: TextStyle(color: Wz.muted, fontSize: 11.5)),
        ]),
      ])))
      else TextButton.icon(onPressed: () => c.go('/login'), style: TextButton.styleFrom(foregroundColor: Colors.white), icon: const Icon(Icons.account_circle_outlined, color: Wz.green, size: 32), label: const Text('Login', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500))),
    ]));
}

/// Desktop footer strip: wordmark left, brand pillars right.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});
  @override Widget build(BuildContext c) => Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 36),
    decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .85), border: const Border(top: BorderSide(color: Wz.border))),
    child: Row(children: [
      const FfwWordmark(height: 20, full: false),
      const SizedBox(width: 14),
      Text('FANTASY FOOTBALL WARZONE', style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2)),
      const Spacer(),
      for (final (i, t) in const ['FOOTBALL', 'COMMUNITY', 'COMPETITION', 'GLORY'].indexed) ...[
        if (i > 0) Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 22), color: Wz.border2),
        Text(t, style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2)),
      ],
    ]));
}

/// Full-bleed stadium backdrop with the dark cinematic grade used on auth screens.
class AuthBackdrop extends StatelessWidget {
  final Alignment align; const AuthBackdrop({super.key, this.align = Alignment.center});
  @override Widget build(BuildContext c) => Stack(fit: StackFit.expand, children: [
    Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: align),
    DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Wz.bg.withValues(alpha: .88), Wz.bg.withValues(alpha: .45), Wz.bg.withValues(alpha: .55), Wz.bg.withValues(alpha: .9)], stops: const [0, .35, .6, 1]))),
    DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Wz.bg.withValues(alpha: .75)], stops: const [.6, 1]))),
  ]);
}

/// Labelled input box: icon · (label over input) · optional trailing action.
/// Tap-only when [onTap] is set (e.g. a picker), showing [value] or [hint].
class AuthField extends StatefulWidget {
  final IconData icon; final String label, hint; final TextEditingController? controller; final String? value, error;
  final bool obscure, enabled, autofocus; final TextInputType? keyboard; final Iterable<String>? autofill; final Widget? trailing; final VoidCallback? onTap, onChanged, onSubmitted;
  const AuthField({super.key, required this.icon, required this.label, required this.hint, this.controller, this.value, this.error, this.obscure = false, this.enabled = true, this.autofocus = false, this.keyboard, this.autofill, this.trailing, this.onTap, this.onChanged, this.onSubmitted});
  @override State<AuthField> createState() => _AuthFieldState();
}
class _AuthFieldState extends State<AuthField> {
  final _focus = FocusNode(); bool _focused = false;
  @override void initState() { super.initState(); _focus.addListener(() => setState(() => _focused = _focus.hasFocus)); }
  @override void dispose() { _focus.dispose(); super.dispose(); }
  @override Widget build(BuildContext c) {
    final w = widget; final bad = w.error != null;
    final hintStyle = TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 13.5);
    final input = w.onTap != null
        ? Text(w.value ?? w.hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: w.value == null ? hintStyle : const TextStyle(color: Wz.text, fontSize: 13.5))
        : TextField(controller: w.controller, focusNode: _focus, enabled: w.enabled, autofocus: w.autofocus, obscureText: w.obscure, keyboardType: w.keyboard, autofillHints: w.autofill, onChanged: (_) => w.onChanged?.call(),
            textInputAction: w.onSubmitted != null ? TextInputAction.done : TextInputAction.next, onSubmitted: (_) => w.onSubmitted?.call(),
            style: const TextStyle(color: Wz.text, fontSize: 13.5), cursorColor: Wz.green,
            decoration: InputDecoration(isDense: true, isCollapsed: true, filled: false, hintText: w.hint, hintStyle: hintStyle, border: InputBorder.none, enabledBorder: InputBorder.none, disabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: const EdgeInsets.only(top: 4, bottom: 2)));
    final box = AnimatedContainer(duration: const Duration(milliseconds: 150), constraints: const BoxConstraints(minHeight: 58),
      padding: EdgeInsets.fromLTRB(16, 9, w.trailing == null ? 16 : 4, 9),
      decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(8), border: Border.all(color: bad ? Wz.red : (_focused ? Wz.green : Wz.border2), width: _focused ? 1.3 : 1)),
      child: Row(children: [
        Icon(w.icon, color: Colors.white.withValues(alpha: .9), size: 21), const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(w.label, style: const TextStyle(color: Wz.text, fontSize: 12.5, fontWeight: FontWeight.w500)), const SizedBox(height: 3), input])),
        if (w.trailing != null) w.trailing!,
      ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      w.onTap != null ? InkWell(onTap: w.onTap, borderRadius: BorderRadius.circular(8), child: box) : GestureDetector(onTap: _focus.requestFocus, child: box),
      if (bad) Padding(padding: const EdgeInsets.only(top: 5, left: 4), child: Text(w.error!, style: const TextStyle(color: Wz.red, fontSize: 11.5))),
    ]);
  }
}

/// Red inline banner for server/network errors, with an optional retry action.
class AuthErrorBanner extends StatelessWidget {
  final String message; final VoidCallback? onRetry;
  const AuthErrorBanner(this.message, {super.key, this.onRetry});
  @override Widget build(BuildContext c) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.fromLTRB(11, 11, 6, 11),
    decoration: BoxDecoration(color: Wz.red.withValues(alpha: .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Wz.red.withValues(alpha: .45))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, color: Wz.red, size: 18), const SizedBox(width: 9),
      Expanded(child: Text(message, style: const TextStyle(color: Wz.text, fontSize: 13, height: 1.35))),
      if (onRetry != null) TextButton(onPressed: onRetry, style: TextButton.styleFrom(foregroundColor: Wz.green, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 32)), child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600))),
    ]));
}

/// Primary teal CTA with a busy state (spinner + [busyLabel]).
class AuthCta extends StatelessWidget {
  final String label, busyLabel; final IconData icon; final bool busy; final VoidCallback? onPressed; final double height;
  const AuthCta({super.key, required this.label, required this.busyLabel, required this.icon, required this.busy, required this.onPressed, this.height = 50});
  @override Widget build(BuildContext c) => SizedBox(width: double.infinity, height: height, child: FilledButton(onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(backgroundColor: Wz.green, disabledBackgroundColor: Wz.green.withValues(alpha: .55), foregroundColor: Wz.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: busy
        ? [const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Wz.onPrimary)), const SizedBox(width: 12), Text(busyLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Wz.onPrimary))]
        : [Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(width: 10), Icon(icon, size: 21)])));
}

/// "—— OR ——" divider.
class AuthOr extends StatelessWidget {
  const AuthOr({super.key});
  @override Widget build(BuildContext c) => Row(children: [const Expanded(child: Divider(color: Wz.border2)), Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('OR', style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 12.5, fontWeight: FontWeight.w600))), const Expanded(child: Divider(color: Wz.border2))]);
}

/// Mobile top bar: back · centred FFW mark.
class AuthMobileBar extends StatelessWidget {
  final String fallback; final bool subtitle;
  const AuthMobileBar({super.key, this.fallback = '/welcome', this.subtitle = false});
  @override Widget build(BuildContext c) => SizedBox(height: subtitle ? 64 : 52, child: Row(children: [
    IconButton(onPressed: () => c.canPop() ? c.pop() : c.go(fallback), tooltip: 'Back', icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
    Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const FfwWordmark(height: 24, full: false),
      if (subtitle) ...[const SizedBox(height: 3), const Text('FANTASY FOOTBALL WARZONE', style: TextStyle(color: Wz.green, fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 1.2))],
    ])),
    const SizedBox(width: 48),
  ]));
}
