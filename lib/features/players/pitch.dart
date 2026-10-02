import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/player.dart';
import 'player_sheet.dart';

/// Pitch view of an FPL squad (starting XI by line + bench strip).
/// mode 'team' shows each player's next fixture (or price); 'points' shows gameweek points × multiplier.
/// Shared by Home, My Team (A12), Points and Transfers — the API (picks / mode / onTap) is stable.
class Pitch extends StatelessWidget {
  final List<Player> picks; final String mode; final void Function(Player)? onTap; final Set<int> selected;
  const Pitch({super.key, required this.picks, this.mode = 'team', this.onTap, this.selected = const {}});

  @override Widget build(BuildContext c) => LayoutBuilder(builder: (c, box) {
    final xi = picks.where((p) => !p.bench).toList()..sort((a, b) => a.slot.compareTo(b.slot));
    final bench = picks.where((p) => p.bench).toList()..sort((a, b) => a.slot.compareTo(b.slot));
    final w = (box.maxWidth / 5.8).clamp(58.0, 96.0);
    void tap(Player p) => onTap != null ? onTap!(p) : showPlayerSheet(c, p);
    Widget line(String pos) {
      final ps = xi.where((p) => p.pos == pos).toList();
      if (ps.isEmpty) return const SizedBox.shrink();
      return Padding(padding: EdgeInsets.symmetric(vertical: w * .09), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final p in ps) PlayerCard(p, mode: mode, w: w, onTap: () => tap(p), out: selected.contains(p.id))]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(borderRadius: BorderRadius.circular(14), child: CustomPaint(painter: _PitchPainter(), child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Wz.green.withValues(alpha: .35))),
        padding: EdgeInsets.symmetric(vertical: w * .2, horizontal: 6),
        child: Column(children: [line('GK'), line('DEF'), line('MID'), line('FWD')])))),
      if (bench.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.fromLTRB(8, 8, 8, 10), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)), child: Column(children: [
          const Padding(padding: EdgeInsets.only(left: 6, bottom: 6), child: Align(alignment: Alignment.centerLeft, child: Text('SUBSTITUTES', style: TextStyle(color: Wz.green, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (final (i, p) in bench.indexed) Column(children: [
              Text(p.pos == 'GK' ? 'GK' : '${i + (bench.first.pos == 'GK' ? 0 : 1)}', style: const TextStyle(color: Wz.muted, fontSize: 10.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              PlayerCard(p, mode: mode, w: w * .88, onTap: () => tap(p), dim: true, out: selected.contains(p.id)),
            ]),
          ]),
        ])),
      ],
    ]);
  });
}

/// One player on the pitch: photo tile in club colour, C/V badge, availability flag,
/// name plate, fixture/points plate and the next-three-fixture difficulty strip.
class PlayerCard extends StatelessWidget {
  final Player p; final String mode; final VoidCallback? onTap; final double w; final bool dim, out;
  const PlayerCard(this.p, {super.key, this.mode = 'team', this.onTap, this.w = 74, this.dim = false, this.out = false});

  String get _info {
    if (mode == 'points') return '${(p.gwPts ?? 0) * (p.mult == 0 ? 1 : p.mult)} pts';
    if (p.fix.isNotEmpty) return p.fix;
    if (p.next.isNotEmpty) return '${p.next.first.opp} (${p.next.first.ha})';
    return '£${p.price.toStringAsFixed(1)}m';
  }

  static Color fdr(int d) => d <= 2 ? Wz.green : d == 3 ? const Color(0xFFCFD8D2) : d == 4 ? Wz.red : const Color(0xFF9B1030);

  @override Widget build(BuildContext c) {
    final col = Wz.hex(p.club.color);
    final flagged = p.status != 'a' && p.status.isNotEmpty;
    final flagColor = p.status == 'd' ? Wz.gold : Wz.red;
    return Semantics(button: true, label: '${p.name}${p.c ? ', captain' : p.v ? ', vice captain' : ''}, $_info', child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: SizedBox(width: w, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(width: w, height: w * .86, decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col.withValues(alpha: dim ? .45 : .85), Color.lerp(col, Wz.bg, .75)!]),
            border: Border.all(color: out ? Wz.red : p.c ? Wz.gold : Colors.white.withValues(alpha: .12), width: out ? 2 : p.c ? 1.4 : 1)),
          clipBehavior: Clip.antiAlias,
          child: p.photoUrl != null
              ? Image.network(p.photoUrl!, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => _code())
              : _code()),
        if (out) Positioned.fill(child: Container(decoration: const BoxDecoration(color: Color(0xE6A01228), borderRadius: BorderRadius.vertical(top: Radius.circular(8))), alignment: Alignment.center, child: const Text('OUT', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)))),
        if (p.c || p.v) Positioned(top: -6, left: -4, child: Container(width: 20, height: 20, alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.c ? Wz.gold : Colors.white, border: Border.all(color: Wz.bg, width: 1.5)),
            child: Text(p.c ? (p.mult == 3 ? 'TC' : 'C') : 'V', style: TextStyle(color: Wz.bg, fontSize: p.mult == 3 ? 8 : 11, fontWeight: FontWeight.w800)))),
        if (flagged) Positioned(top: -6, right: -4, child: Tooltip(message: p.news ?? 'Availability doubt', child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: flagColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: Wz.bg, width: 1.5)),
            child: Text(p.chance != null ? '${p.chance}%' : '!', style: const TextStyle(color: Wz.bg, fontSize: 9.5, fontWeight: FontWeight.w800))))),
      ]),
      Container(width: w, padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 3), color: const Color(0xF0060C10),
          child: Text(p.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: w < 70 ? 10 : 11.5, fontWeight: FontWeight.w700))),
      Container(width: w, padding: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(color: mode == 'points' ? Wz.green : const Color(0xF00A1B23), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))),
          child: Text(_info, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: mode == 'points' ? Wz.onPrimary : Wz.green2, fontSize: w < 70 ? 9.5 : 10.5, fontWeight: FontWeight.w700))),
      if (mode == 'team' && p.next.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Row(children: [
        for (final n in p.next.take(3)) Expanded(child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: fdr(n.fdr), borderRadius: BorderRadius.circular(2)))),
      ])),
    ]))));
  }

  Widget _code() => Center(child: Text(p.club.code, style: TextStyle(color: Colors.white, fontSize: w * .2, fontWeight: FontWeight.w800)));
}

/// Striped grass + markings (goal at the top, halfway line at the bottom edge).
class _PitchPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size s) {
    const stripes = 8; final h = s.height / stripes;
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(Rect.fromLTWH(0, i * h, s.width, h), Paint()..color = i.isEven ? const Color(0xFF0E3A26) : const Color(0xFF0B3120));
    }
    canvas.drawRect(Offset.zero & s, Paint()..shader = RadialGradient(center: Alignment.topCenter, radius: 1.2, colors: [Colors.white.withValues(alpha: .06), Colors.black.withValues(alpha: .35)]).createShader(Offset.zero & s));
    final line = Paint()..color = Colors.white.withValues(alpha: .18)..style = PaintingStyle.stroke..strokeWidth = 1.4;
    const m = 10.0;
    canvas.drawRect(Rect.fromLTWH(m, m, s.width - 2 * m, s.height - 2 * m), line);
    final boxW = s.width * .56, boxH = s.height * .16;
    canvas.drawRect(Rect.fromLTWH((s.width - boxW) / 2, m, boxW, boxH), line);
    canvas.drawRect(Rect.fromLTWH((s.width - boxW * .45) / 2, m, boxW * .45, boxH * .42), line);
    canvas.drawArc(Rect.fromCircle(center: Offset(s.width / 2, m + boxH), radius: s.width * .09), 0, 3.1416, false, line);
    canvas.drawLine(Offset(m, s.height - m), Offset(s.width - m, s.height - m), line);
    canvas.drawArc(Rect.fromCircle(center: Offset(s.width / 2, s.height - m), radius: s.width * .14), 3.1416, 3.1416, false, line);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}
