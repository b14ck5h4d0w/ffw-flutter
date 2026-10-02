import 'package:flutter/material.dart';
import 'theme.dart';

/// FFW wordmark: slanted "FFW" + gold crown, optionally followed by the two-line
/// "FANTASY FOOTBALL / WARZONE" lockup. [height] is the height of the "FFW" letters.
class FfwWordmark extends StatelessWidget {
  final double height; final bool full;
  const FfwWordmark({super.key, this.height = 30, this.full = true});
  @override Widget build(BuildContext c) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
    Transform(transform: Matrix4.skewX(-.18), alignment: Alignment.center,
        child: Text('FFW', style: anton(height * 1.1, color: Colors.white, spacing: .5).copyWith(height: 1, shadows: [Shadow(color: Wz.green.withValues(alpha: .35), blurRadius: 14)]))),
    SizedBox(width: height * .12),
    Padding(padding: EdgeInsets.only(bottom: height * .18), child: FfwCrown(size: height * .82)),
    if (full) ...[
      SizedBox(width: height * .4),
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FANTASY FOOTBALL', style: TextStyle(color: Wz.green, fontSize: height * .46, fontWeight: FontWeight.w600, letterSpacing: 1, height: 1.15)),
        Text('WARZONE', style: TextStyle(color: Wz.green, fontSize: height * .46, fontWeight: FontWeight.w600, letterSpacing: 1, height: 1.15)),
      ]),
    ],
  ]);
}

/// Gold three-point crown used across the brand.
class FfwCrown extends StatelessWidget {
  final double size; final Color color;
  const FfwCrown({super.key, this.size = 24, this.color = Wz.gold});
  @override Widget build(BuildContext c) => CustomPaint(size: Size(size, size * .78), painter: _CrownPainter(color));
}
class _CrownPainter extends CustomPainter {
  final Color color; _CrownPainter(this.color);
  @override void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final crown = Path()
      ..moveTo(w * .06, h * .92)..lineTo(w * .02, h * .22)..lineTo(w * .3, h * .5)..lineTo(w * .5, h * .02)
      ..lineTo(w * .7, h * .5)..lineTo(w * .98, h * .22)..lineTo(w * .94, h * .92)..close();
    final gem = Path()..moveTo(w * .5, h * .42)..lineTo(w * .58, h * .6)..lineTo(w * .5, h * .78)..lineTo(w * .42, h * .6)..close();
    canvas.drawPath(crown, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(color, Colors.white, .35)!, color, Color.lerp(color, Colors.black, .25)!]).createShader(Offset.zero & s));
    canvas.drawPath(gem, Paint()..color = Wz.bg);
  }
  @override bool shouldRepaint(covariant _CrownPainter o) => o.color != color;
}
