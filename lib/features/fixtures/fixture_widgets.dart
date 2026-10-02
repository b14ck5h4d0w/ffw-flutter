import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/fixture.dart';
import '../../models/player.dart';

/// Pieces shared by Fixtures (A16), Live Match Centre (A17) and Match Detail (A18).

/// Kick-off as a local DateTime (API sends UTC ISO).
DateTime? kickoffLocal(Fixture f) => f.ko == null ? null : DateTime.tryParse(f.ko!)?.toLocal();

/// "Today 15:00" · "Tomorrow 12:30" · "Sat 10 Oct, 11:30".
String kickoffLabel(Fixture f) {
  final d = kickoffLocal(f); if (d == null) return 'TBC';
  final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day); final day = DateTime(d.year, d.month, d.day);
  final t = DateFormat('HH:mm').format(d);
  if (day == today) return 'Today $t';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow $t';
  return '${DateFormat('EEE d MMM').format(d)}, $t';
}

BoxDecoration fixtureBox({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));

class ClubBadge extends StatelessWidget {
  final Club club; final double size;
  const ClubBadge(this.club, {super.key, this.size = 28});
  @override Widget build(BuildContext c) => SizedBox(width: size, height: size, child: club.badgeUrl == null ? HexAvatar(club.code, size: size, color: Wz.hex(club.color))
      : Image.network(club.badgeUrl!, errorBuilder: (_, __, ___) => HexAvatar(club.code, size: size, color: Wz.hex(club.color))));
}

/// One fixture line: home · score/time · away. Tapping opens the match page.
class FixtureRow extends StatelessWidget {
  final Fixture f; final bool compact;
  const FixtureRow(this.f, {super.key, this.compact = false});
  @override Widget build(BuildContext c) {
    final live = f.status == 'live', ft = f.status == 'ft';
    final d = kickoffLocal(f);
    String name(Club t) => compact ? t.code : t.name;
    return InkWell(onTap: () => c.push('/match/${f.id}'), borderRadius: BorderRadius.circular(10), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: live ? Wz.red.withValues(alpha: .55) : Wz.border2)),
      child: Row(children: [
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Flexible(child: Text(name(f.home), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: ft && (f.hs ?? 0) > (f.as_ ?? 0) ? FontWeight.w700 : FontWeight.w500))),
          const SizedBox(width: 10), ClubBadge(f.home),
        ])),
        Container(width: compact ? 78 : 96, margin: const EdgeInsets.symmetric(horizontal: 10), padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: live ? Wz.red.withValues(alpha: .15) : ft ? Wz.panel2 : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: live ? Wz.red.withValues(alpha: .6) : ft ? Wz.border2 : Wz.green.withValues(alpha: .5))),
          child: Column(children: [
            Text(f.status == 'up' ? (d == null ? 'TBC' : DateFormat('HH:mm').format(d)) : '${f.hs ?? 0} - ${f.as_ ?? 0}', style: TextStyle(color: f.status == 'up' ? Wz.green : Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            Text(live ? "LIVE ${f.min}'" : ft ? 'FT' : 'KICK-OFF', style: TextStyle(color: live ? Wz.red : Wz.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .6)),
          ])),
        Expanded(child: Row(children: [
          ClubBadge(f.away), const SizedBox(width: 10),
          Flexible(child: Text(name(f.away), overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: ft && (f.as_ ?? 0) > (f.hs ?? 0) ? FontWeight.w700 : FontWeight.w500))),
        ])),
        const Icon(Icons.chevron_right_rounded, color: Wz.muted, size: 20),
      ])));
  }
}

/// Big live-match card for the Match Centre: badges, score, pulsing minute.
class LiveMatchCard extends StatelessWidget {
  final Fixture f; const LiveMatchCard(this.f, {super.key});
  @override Widget build(BuildContext c) => InkWell(onTap: () => c.push('/match/${f.id}'), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.red.withValues(alpha: .6)), boxShadow: [BoxShadow(color: Wz.red.withValues(alpha: .12), blurRadius: 20)],
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Wz.hex(f.home.color).withValues(alpha: .35), Wz.panel, Wz.hex(f.away.color).withValues(alpha: .35)])),
    child: Column(children: [
      Row(children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Wz.red)), const SizedBox(width: 6),
        Text("LIVE · ${f.min}'", style: const TextStyle(color: Wz.red, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .8)),
        const Spacer(), Text('GW ${f.gw}', style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Column(children: [ClubBadge(f.home, size: 44), const SizedBox(height: 6), Text(f.home.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))])),
        Text('${f.hs ?? 0} – ${f.as_ ?? 0}', style: anton(40, color: Colors.white, spacing: 2)),
        Expanded(child: Column(children: [ClubBadge(f.away, size: 44), const SizedBox(height: 6), Text(f.away.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))])),
      ]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: (f.min / 90).clamp(0, 1), minHeight: 4, color: Wz.red, backgroundColor: Wz.border2)),
    ])));
}
