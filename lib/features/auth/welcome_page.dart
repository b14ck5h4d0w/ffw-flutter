import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/theme.dart';
import 'auth_chrome.dart';

/// A02 — Welcome / Get Started. Lion crest, "Welcome to FFW Warzone", three feature cards,
/// Get Started / Login; desktop adds the #10 player and a handwritten flourish.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  static const _features = [
    (Icons.emoji_events_rounded, Wz.gold, 'Join Leagues', 'Compete. Climb. Win.', '/leagues/directory'),
    (Icons.groups_rounded, Wz.green, 'Build Clans', 'Stronger together.', '/clans'),
    (Icons.close_rounded, Wz.red, 'Battle Modes', 'More ways to play.', '/modes'),
  ];

  @override Widget build(BuildContext c) => MediaQuery.of(c).size.width >= 950 ? _desktop(c) : _mobile(c);

  Widget _title(double size, {required bool center}) => Column(crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
    Text('WELCOME TO', style: TextStyle(color: Colors.white, fontSize: size * .34, fontWeight: FontWeight.w600, letterSpacing: 5)),
    Text.rich(TextSpan(children: [TextSpan(text: 'FFW ', style: anton(size, color: Colors.white, spacing: 1)), TextSpan(text: 'WARZONE', style: anton(size, color: Wz.green, spacing: 1))]), textAlign: center ? TextAlign.center : TextAlign.start),
    const SizedBox(height: 10),
    Text('Leagues. Clans. Battle Modes.\nMore than fantasy. A battle of minds.', textAlign: center ? TextAlign.center : TextAlign.start, style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: size * .3 < 14 ? 14 : size * .3, height: 1.45)),
  ]);

  Widget _mobile(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: Stack(children: [
    Positioned(top: 0, left: 0, right: 0, height: 420, child: Stack(fit: StackFit.expand, children: [
      Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Wz.bg.withValues(alpha: .25), Wz.bg.withValues(alpha: .6), Wz.bg], stops: const [0, .62, 1]))),
    ])),
    SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 14, 22, 24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(children: [
      Image.asset(WzAssets.emblem, width: 200, height: 200),
      _title(40, center: true),
      const SizedBox(height: 20),
      for (final f in _features) InkWell(onTap: () => c.go(f.$5), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .88), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
        child: Row(children: [Icon(f.$1, color: f.$2, size: 30), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(f.$3, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)), Text(f.$4, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12.5))])), const Icon(Icons.chevron_right_rounded, color: Wz.green)]))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () => c.go('/register'), style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Get Started', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)), SizedBox(width: 10), Icon(Icons.arrow_forward_rounded)]))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => c.go('/login'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      TextButton(onPressed: () => c.go('/home'), style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text('Look around first')),
    ]))))),
  ]));

  Widget _desktop(BuildContext c) {
    final showPlayer = MediaQuery.of(c).size.width >= 1180;
    return Scaffold(backgroundColor: Wz.bg, body: Stack(fit: StackFit.expand, children: [
      const AuthBackdrop(),
      Column(children: [
        const AuthTopNav(),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 60), child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: 620, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Image.asset(WzAssets.emblem, width: 190, height: 190),
            _title(62, center: false),
            const SizedBox(height: 24),
            Row(children: [for (final (i, f) in _features.indexed) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: InkWell(onTap: () => c.go(f.$5), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .88), borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)),
              child: Column(children: [Icon(f.$1, color: f.$2, size: 40), const SizedBox(height: 10), Text(f.$3, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(f.$4, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 13))]))))]]),
            const SizedBox(height: 18),
            Row(children: [
              SizedBox(width: 210, height: 52, child: FilledButton(onPressed: () => c.go('/register'), style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Get Started', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), SizedBox(width: 10), Icon(Icons.arrow_forward_rounded)]))),
              const SizedBox(width: 12),
              SizedBox(width: 140, height: 52, child: OutlinedButton(onPressed: () => c.go('/login'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Login', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 12),
              TextButton(onPressed: () => c.go('/home'), style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text('Look around first ›')),
            ]),
            const SizedBox(height: 22),
            Wrap(spacing: 26, runSpacing: 10, children: [for (final s in const [(Icons.sync_rounded, 'Live FPL Sync'), (Icons.sports_esports_rounded, 'Competitive Game Modes'), (Icons.shield_outlined, 'Clans & Private Leagues')]) Row(mainAxisSize: MainAxisSize.min, children: [Icon(s.$1, color: Wz.green, size: 22), const SizedBox(width: 8), Text(s.$2, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))])]),
          ])))),
          Expanded(child: showPlayer ? Stack(children: [
            Positioned.fill(child: Padding(padding: const EdgeInsets.only(top: 14), child: Image.asset(WzAssets.player10, fit: BoxFit.contain, alignment: Alignment.bottomCenter))),
            Positioned(right: 0, top: 110, child: Transform.rotate(angle: -.18, child: Text('Good managers\nbuild teams.\nGreat ones\nbuild legacies.', textAlign: TextAlign.center, style: script(34)))),
            const Positioned(right: 0, bottom: 70, child: Row(children: [FfwCrown(size: 22), SizedBox(width: 10), Text('SAME GAME.\nHIGHER STAKES.', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2, height: 1.4))])),
          ]) : const SizedBox()),
        ]))))),
        const AuthFooter(),
      ]),
    ]));
  }
}
