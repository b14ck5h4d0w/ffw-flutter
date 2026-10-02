import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/brand.dart';
import '../../core/session.dart';
import '../../core/theme.dart';

/// A01 — Splash. Stadium backdrop, lion crest, loading bar, then routes on
/// (Home when signed in, Welcome otherwise). Tap anywhere to skip the animation.
class SplashPage extends StatefulWidget { const SplashPage({super.key}); @override State<SplashPage> createState() => _SplashState(); }

class _SplashState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();
  Timer? _t; bool _left = false;
  @override void initState() { super.initState(); _t = Timer(const Duration(milliseconds: 2500), _next); }
  @override void dispose() { _t?.cancel(); _c.dispose(); super.dispose(); }
  void _next() { if (!mounted || _left) return; _left = true; context.go(Session.I.loggedIn ? '/home' : '/welcome'); }

  @override Widget build(BuildContext c) {
    final reduce = MediaQuery.of(c).disableAnimations;
    final crest = Column(mainAxisSize: MainAxisSize.min, children: [
      Image.asset(WzAssets.emblem, width: 230, height: 230),
      const FfwWordmark(height: 30),
      const SizedBox(height: 18),
      const Text('MORE THAN A GAME.', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 4)),
      const Text('A BATTLE OF MINDS.', style: TextStyle(color: Wz.green, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 4)),
    ]);
    return Scaffold(backgroundColor: Wz.bg, body: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _next, child: Stack(fit: StackFit.expand, children: [
      Image.asset(WzAssets.stadium, fit: BoxFit.cover),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Wz.bg.withValues(alpha: .55), Wz.bg.withValues(alpha: .4), Wz.bg.withValues(alpha: .94)]))),
      Center(child: reduce ? crest : FadeTransition(opacity: CurvedAnimation(parent: _c, curve: const Interval(0, .45, curve: Curves.easeOut)),
          child: ScaleTransition(scale: Tween(begin: .86, end: 1.0).animate(CurvedAnimation(parent: _c, curve: const Interval(0, .55, curve: Curves.easeOutBack))), child: crest))),
      Align(alignment: const Alignment(0, .84), child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(borderRadius: BorderRadius.circular(99), child: SizedBox(height: 4, width: 240, child: AnimatedBuilder(animation: _c, builder: (_, __) => LinearProgressIndicator(value: _c.value, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(Wz.green))))),
        const SizedBox(height: 14),
        Text('PLAY · SURVIVE · CONQUER', style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
      ])),
    ])));
  }
}
