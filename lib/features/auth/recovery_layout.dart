import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/theme.dart';
import 'auth_chrome.dart';

/// Layout shared by the account-recovery screens (A05 forgot + reset).
/// Desktop: nav · [main card][side card] · #10 player with script flourish · footer.
/// Phone: back bar · stadium header (player behind the heading) · stacked body.
class RecoveryScaffold extends StatelessWidget {
  final Widget desktopMain, desktopSide, mobileBody; final bool glowMain, mobilePlayer, backToLogin;
  const RecoveryScaffold({super.key, required this.desktopMain, required this.desktopSide, required this.mobileBody, this.glowMain = false, this.mobilePlayer = true, this.backToLogin = true});

  @override Widget build(BuildContext c) => MediaQuery.of(c).size.width >= 950 ? _desktop(c) : _mobile(c);

  Widget _mobile(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: Stack(children: [
    Positioned(top: 0, left: 0, right: 0, height: 380, child: Stack(fit: StackFit.expand, children: [
      Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter),
      if (mobilePlayer) Positioned(right: -40, top: 40, bottom: -80, child: Opacity(opacity: .85, child: Image.asset(WzAssets.player10, fit: BoxFit.fitHeight, alignment: Alignment.topCenter))),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Wz.bg.withValues(alpha: .2), Wz.bg.withValues(alpha: .55), Wz.bg], stops: const [0, .62, 1]))),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Wz.bg.withValues(alpha: .75), Colors.transparent], stops: const [.25, .8]))),
    ])),
    SafeArea(child: Column(children: [
      const AuthMobileBar(fallback: '/login', subtitle: true),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 26, 20, 24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        mobileBody, if (backToLogin) ...[const SizedBox(height: 18), const BackToLogin()],
      ]))))),
    ])),
  ]));

  Widget _desktop(BuildContext c) {
    final showPlayer = MediaQuery.of(c).size.width >= 1200;
    return Scaffold(backgroundColor: Wz.bg, body: Stack(fit: StackFit.expand, children: [
      const AuthBackdrop(),
      Column(children: [
        const AuthTopNav(),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 48), child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 28), child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 420, padding: const EdgeInsets.fromLTRB(28, 28, 28, 22), decoration: authCardDeco(glow: glowMain), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              desktopMain, const Spacer(), if (backToLogin) ...[const SizedBox(height: 16), const BackToLogin()],
            ])),
            const SizedBox(width: 20),
            Container(width: 330, padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), decoration: authCardDeco(), child: desktopSide),
          ])))),
          Expanded(child: showPlayer ? Stack(children: [
            Positioned.fill(child: Padding(padding: const EdgeInsets.only(top: 20), child: Image.asset(WzAssets.player10, fit: BoxFit.contain, alignment: Alignment.bottomCenter))),
            Positioned(right: 0, top: 140, child: Transform.rotate(angle: -.14, child: Column(children: [const FfwCrown(size: 40), const SizedBox(height: 6), Text('Same game.\nBigger minds.', textAlign: TextAlign.center, style: script(42))]))),
          ]) : const SizedBox()),
        ]))))),
        const AuthFooter(),
      ]),
    ]));
  }
}

BoxDecoration authCardDeco({bool glow = false, Color accent = Wz.green}) => BoxDecoration(color: Wz.panel.withValues(alpha: .9), borderRadius: BorderRadius.circular(12),
    border: Border.all(color: glow ? accent.withValues(alpha: .55) : Wz.border2, width: glow ? 1.2 : 1), boxShadow: glow ? [BoxShadow(color: accent.withValues(alpha: .14), blurRadius: 30)] : null);

class BackToLogin extends StatelessWidget {
  const BackToLogin({super.key});
  @override Widget build(BuildContext c) => Center(child: TextButton.icon(onPressed: () => c.go('/login'), style: TextButton.styleFrom(foregroundColor: Wz.green),
      icon: const Icon(Icons.arrow_back_rounded, size: 19), label: const Text('Back to Login', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))));
}

/// Small green caps label, e.g. "ACCOUNT RECOVERY".
class RecoveryEyebrow extends StatelessWidget {
  final String text; const RecoveryEyebrow(this.text, {super.key});
  @override Widget build(BuildContext c) => Text(text, style: const TextStyle(color: Wz.green, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.4));
}

/// Icon tile + text rows (steps, tips).
class RecoveryList extends StatelessWidget {
  final List<(IconData, String)> items; const RecoveryList(this.items, {super.key});
  @override Widget build(BuildContext c) => Column(children: [
    for (final (i, (icon, t)) in items.indexed) Padding(padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 14), child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(8), border: Border.all(color: Wz.border2)), child: Icon(icon, color: Colors.white, size: 19)),
      const SizedBox(width: 14), Expanded(child: Text(t, style: const TextStyle(color: Wz.text, fontSize: 13.5, height: 1.35))),
    ])),
  ]);
}

/// Shield + reassurance card.
class SafeNote extends StatelessWidget {
  final String title, body; const SafeNote({super.key, required this.title, required this.body});
  @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .85), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.verified_user_outlined, color: Wz.green, size: 30), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Wz.text, fontSize: 13.5, fontWeight: FontWeight.w600)), const SizedBox(height: 4),
        Text(body, style: const TextStyle(color: Wz.muted, fontSize: 12.5, height: 1.4)),
      ])),
    ]));
}

/// Round glowing status icon (sent / success / expired).
class StatusBadge extends StatelessWidget {
  final IconData icon; final Color color; const StatusBadge(this.icon, {super.key, this.color = Wz.green});
  @override Widget build(BuildContext c) => Container(width: 92, height: 92, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .08), border: Border.all(color: color.withValues(alpha: .35)), boxShadow: [BoxShadow(color: color.withValues(alpha: .2), blurRadius: 30)]),
      child: Icon(icon, color: color, size: 46));
}
