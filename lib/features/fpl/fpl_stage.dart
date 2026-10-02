import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/theme.dart';
import '../auth/auth_chrome.dart';

/// Frame for the FPL onboarding screens (A07 syncing, A08 team found):
/// desktop = nav · content + #10 player with script flourish · footer; phone = back bar + scroll.
class FplStage extends StatelessWidget {
  final Widget Function(BuildContext) desktop, mobile; final String flourish, back;
  const FplStage({super.key, required this.desktop, required this.mobile, required this.flourish, this.back = '/connect-fpl'});

  static bool wide(BuildContext c) => MediaQuery.of(c).size.width >= 950;

  @override Widget build(BuildContext c) => wide(c) ? _desktop(c) : Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Column(children: [
    AuthMobileBar(fallback: back),
    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: mobile(c))))),
  ])));

  Widget _desktop(BuildContext c) {
    final showPlayer = MediaQuery.of(c).size.width >= 1240;
    return Scaffold(backgroundColor: Wz.bg, body: Stack(fit: StackFit.expand, children: [
      const AuthBackdrop(),
      if (showPlayer) Positioned(right: 60, top: 60, bottom: 40, width: 520, child: Image.asset(WzAssets.player10, fit: BoxFit.contain, alignment: Alignment.bottomCenter)),
      if (showPlayer) Positioned(right: 30, top: 150, child: Transform.rotate(angle: -.2, child: Column(children: [Text(flourish, textAlign: TextAlign.center, style: script(38)), const SizedBox(height: 4), const FfwCrown(size: 32, color: Wz.green)]))),
      Column(children: [
        const AuthTopNav(),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(48, 26, 48, 22), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1344), child: desktop(c))))),
        const AuthFooter(),
      ]),
    ]));
  }
}

/// Small green caps breadcrumb, e.g. "CONNECT FPL".
class FplCrumb extends StatelessWidget {
  final String text; const FplCrumb(this.text, {super.key});
  @override Widget build(BuildContext c) => Row(children: [const Icon(Icons.link_rounded, color: Wz.green, size: 16), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Wz.green, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.3))]);
}

/// Icon + title + line, used in the bottom strips.
class FplPerk extends StatelessWidget {
  final IconData icon; final String title, body; const FplPerk(this.icon, this.title, this.body, {super.key});
  @override Widget build(BuildContext c) => Row(children: [
    Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Wz.green.withValues(alpha: .6), width: 1.5)), child: Icon(icon, color: Wz.green, size: 24)),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 3),
      Text(body, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12.5, height: 1.35)),
    ])),
  ]);
}

BoxDecoration fplPanel({Color? border, bool glow = false}) => BoxDecoration(color: Wz.panel.withValues(alpha: .9), borderRadius: BorderRadius.circular(12),
    border: Border.all(color: border ?? Wz.border2, width: glow ? 1.2 : 1), boxShadow: glow ? [BoxShadow(color: (border ?? Wz.green).withValues(alpha: .18), blurRadius: 28)] : null);
