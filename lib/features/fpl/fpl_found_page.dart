import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/json.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/player.dart';
import 'fpl_stage.dart';

/// A08 — FPL Connected / Team Found (/connect-fpl/done).
/// Team + manager from fpl/lookup (total, overall rank), gameweek points from home.summary,
/// chips from /chips and the top-5 season scorers from the synced squad. Each source loads
/// independently so a slow squad/chips sync never blanks the page.
class FplFoundPage extends StatefulWidget { const FplFoundPage({super.key}); @override State<FplFoundPage> createState() => _FplFoundState(); }

class _FplFoundState extends State<FplFoundPage> {
  Map<String, dynamic>? team, summary; List<Map<String, dynamic>>? chips; List<Player>? picks; bool loading = true;

  static const _chipMeta = {
    'wildcard': ('Wildcard', Icons.bolt_rounded, Wz.green),
    'freehit': ('Free Hit', Icons.checkroom_rounded, Wz.purple2),
    'bboost': ('Bench Boost', Icons.groups_rounded, Wz.cyan),
    '3xc': ('Triple Captain', Icons.star_rounded, Wz.gold),
  };

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final e = Session.I.user?.fpl;
    Future<T?> soft<T>(Future<T> f) => f.then<T?>((v) => v).catchError((_) => null);
    final r = await Future.wait([
      e == null ? Future.value(null) : soft(Repo.I.fplLookup('$e')),
      soft(Repo.I.home()),
      soft(Repo.I.chips()),
      soft(Repo.I.squad()),
    ]);
    if (!mounted) return;
    setState(() {
      team = r[0] as Map<String, dynamic>?;
      summary = r[1] == null ? null : jMap((r[1] as Map<String, dynamic>)['summary']);
      chips = r[2] as List<Map<String, dynamic>>?;
      final sq = r[3] as Map<String, dynamic>?;
      picks = sq == null ? null : (jListOf(sq['picks'], Player.fromJson)..sort((a, b) => b.pts.compareTo(a.pts)));
      loading = false;
    });
  }

  String get _teamName => loading ? 'Loading your team…' : jStrN(team?['team']) ?? 'Your FPL Team';
  String get _manager => jStrN(team?['manager']) ?? Session.I.user?.name ?? '';
  String _fmt(dynamic v) { final n = jIntN(v); if (n == null) return '—'; final s = '$n'; return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','); }

  @override Widget build(BuildContext c) {
    if (!Session.I.loggedIn || Session.I.user?.fpl == null) {
      return FplStage(flourish: 'Same passion.\nBigger battles.', desktop: (_) => _notLinked(), mobile: (_) => _notLinked());
    }
    return FplStage(flourish: 'Same passion.\nBigger battles.', back: '/home', desktop: _desktop, mobile: _mobile);
  }

  Widget _notLinked() => Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Container(width: 420, padding: const EdgeInsets.all(24), decoration: fplPanel(), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.link_off_rounded, color: Wz.gold, size: 40), const SizedBox(height: 12),
    Text('No FPL team linked yet', style: anton(24, color: Colors.white)), const SizedBox(height: 8),
    const Text('Connect your FPL team to see it here.', textAlign: TextAlign.center, style: TextStyle(color: Wz.muted)), const SizedBox(height: 18),
    FilledButton(onPressed: () => context.go('/connect-fpl'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)), child: const Text('Connect with FPL')),
  ]))));

  // ---------- pieces ----------
  Widget _hero(double size) => Column(children: [
    Container(width: size * 1.5, height: size * 1.5, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Wz.green, width: 3), boxShadow: [BoxShadow(color: Wz.green.withValues(alpha: .35), blurRadius: 24)]),
        child: Icon(Icons.check_rounded, color: Wz.green, size: size)),
    const SizedBox(height: 14),
    Transform(transform: Matrix4.skewX(-.12), alignment: Alignment.center, child: Text('FPL TEAM FOUND!', textAlign: TextAlign.center, style: anton(size * 1.1, color: Colors.white, spacing: 1))),
    const SizedBox(height: 8),
    Text('Your FPL team is now connected to FFW.', textAlign: TextAlign.center, style: TextStyle(color: Wz.green, fontSize: size * .34, fontWeight: FontWeight.w500)),
  ]);

  Widget _teamCard({required bool wide}) => Container(padding: EdgeInsets.all(wide ? 18 : 14), decoration: fplPanel(border: Wz.green.withValues(alpha: .4)), child: Row(children: [
    HexAvatar(loading ? '' : _teamName.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase(), size: wide ? 64 : 54),
    SizedBox(width: wide ? 18 : 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_teamName, maxLines: 1, overflow: TextOverflow.ellipsis, style: anton(wide ? 26 : 21, color: Colors.white, spacing: .4)),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 20), const SizedBox(width: 8),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_manager, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text('FPL Team ID ${Session.I.user?.fpl ?? ''}', style: const TextStyle(color: Wz.green, fontSize: 11.5)),
        ])),
      ]),
    ])),
  ]));

  List<Widget> _statTiles() => [
    _stat(Icons.emoji_events_rounded, Wz.gold, _fmt(team?['total'] ?? summary?['total']), 'Total Points', summary?['gw_pts'] == null ? null : '${jInt(summary!['gw_pts'])} this GW'),
    _stat(Icons.bar_chart_rounded, Wz.green, _fmt(team?['orank'] ?? summary?['orank']), 'Overall Rank', null),
  ];
  Widget _stat(IconData i, Color col, String v, String label, String? sub) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: fplPanel(), child: Row(children: [
    Icon(i, color: col, size: 34), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12)),
      if (sub != null) Text(sub, style: const TextStyle(color: Wz.green, fontSize: 11.5, fontWeight: FontWeight.w600)),
    ])),
  ]));

  List<Widget> _chipTiles({required bool compact}) => [
    for (final ch in chips ?? const <Map<String, dynamic>>[]) if (_chipMeta.containsKey(jStr(ch['name']))) () {
      final m = _chipMeta[jStr(ch['name'])]!;
      final st = jBool(ch['active']) ? 'Active' : jBool(ch['available']) ? 'Available' : 'Used';
      final on = st != 'Used';
      return Container(padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: compact ? 8 : 12), decoration: fplPanel(border: on ? m.$3.withValues(alpha: .35) : null),
        child: Row(children: [
          Container(width: compact ? 28 : 40, height: compact ? 28 : 40, decoration: BoxDecoration(color: m.$3.withValues(alpha: on ? .2 : .06), borderRadius: BorderRadius.circular(8)), child: Icon(m.$2, color: on ? m.$3 : Wz.faint, size: compact ? 18 : 24)),
          SizedBox(width: compact ? 6 : 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: compact ? 10.5 : 14, fontWeight: FontWeight.w600)),
            Text(st, style: TextStyle(color: on ? Wz.green : Wz.muted, fontSize: compact ? 10 : 12.5)),
          ])),
        ]));
    }(),
  ];

  Widget _playerCard(Player p, int rank) => Container(width: 150, padding: const EdgeInsets.all(10), decoration: fplPanel(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(),
      if (p.club.badgeUrl != null) Image.network(p.club.badgeUrl!, width: 22, height: 22, errorBuilder: (_, __, ___) => const SizedBox()),
    ]),
    SizedBox(height: 92, child: Stack(children: [
      Center(child: p.photoUrl == null ? const Icon(Icons.person_rounded, color: Wz.faint, size: 60)
          : Image.network(p.photoUrl!, height: 92, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Wz.faint, size: 60))),
      Positioned(left: 0, bottom: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .8), borderRadius: BorderRadius.circular(4), border: Border.all(color: Wz.green)),
          child: Text(p.pos, style: const TextStyle(color: Wz.green, fontSize: 10.5, fontWeight: FontWeight.w700)))),
    ])),
    const SizedBox(height: 6),
    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text('${p.pts}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(width: 5),
      const Text('Points', style: TextStyle(color: Wz.muted, fontSize: 12)),
    ]),
  ]));

  Widget _playerRow(Player p) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(4, 6, 12, 6), decoration: BoxDecoration(color: Wz.panel.withValues(alpha: .9), borderRadius: BorderRadius.circular(10), border: const Border(left: BorderSide(color: Wz.green, width: 3))),
    child: Row(children: [
      SizedBox(width: 52, height: 44, child: p.photoUrl == null ? const Icon(Icons.person_rounded, color: Wz.faint) : Image.network(p.photoUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Wz.faint))),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
        Text('${p.pos} • ${p.club.code}', style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${p.pts}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const Text('Points', style: TextStyle(color: Wz.muted, fontSize: 11))]),
    ]));

  Widget _keyTitle() => Row(children: [
    const Text('Your Key Players', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const Spacer(),
    TextButton(onPressed: () => context.go('/squad'), style: TextButton.styleFrom(foregroundColor: Wz.green), child: const Text('View All ›', style: TextStyle(fontWeight: FontWeight.w600))),
  ]);

  Widget _squadPending() => Container(padding: const EdgeInsets.all(16), decoration: fplPanel(), child: const Row(children: [
    Icon(Icons.hourglass_top_rounded, color: Wz.gold), SizedBox(width: 12),
    Expanded(child: Text('Your squad is still syncing. It will appear on your team page shortly.', style: TextStyle(color: Wz.muted, fontSize: 13))),
  ]));

  Widget _cta({required bool wide}) => SizedBox(width: wide ? 580 : double.infinity, height: wide ? 64 : 50, child: FilledButton(onPressed: () => context.go('/onboarding'),
    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.emoji_events_rounded, size: 22), const SizedBox(width: 10), Text(wide ? 'Enter Warzone' : 'Continue to FFW', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(width: 10), const Icon(Icons.arrow_forward_rounded, size: 22)]),
      if (wide) const Text('Compete. Climb. Conquer.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    ])));

  // ---------- desktop ----------
  Widget _desktop(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 760, child: Column(children: [_hero(40), const SizedBox(height: 18), SizedBox(width: 520, child: _teamCard(wide: true))])),
    const SizedBox(height: 22),
    if (loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: Wz.green)))
    else ...[
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final w in [..._statTiles(), ..._chipTiles(compact: false)]) Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: w)),
      ])),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.fromLTRB(16, 6, 16, 16), decoration: fplPanel(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _keyTitle(),
        (picks == null || picks!.isEmpty) ? _squadPending() : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final (i, p) in picks!.take(5).indexed) Padding(padding: const EdgeInsets.only(right: 10), child: _playerCard(p, i + 1))]))),
          const SizedBox(width: 6),
          Container(width: 260, height: 196, padding: const EdgeInsets.all(18), decoration: fplPanel(border: Wz.green.withValues(alpha: .35)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('"SAME PLAYERS.\nNEW BATTLES."', style: anton(20, color: Colors.white, spacing: .8)), const SizedBox(height: 10),
            Text('Your FPL journey continues in a bigger arena.', style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 13, height: 1.4)),
          ])),
        ]),
      ])),
    ],
    const SizedBox(height: 20),
    Center(child: _cta(wide: true)),
  ]);

  // ---------- phone ----------
  Widget _mobile(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const SizedBox(height: 10), _hero(30), const SizedBox(height: 16),
    _teamCard(wide: false), const SizedBox(height: 10),
    if (loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: Wz.green)))
    else ...[
      Row(children: [for (final w in _statTiles()) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: w))]),
      if ((chips ?? const []).isNotEmpty) ...[const SizedBox(height: 8), GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 3.3, mainAxisSpacing: 6, crossAxisSpacing: 6, children: _chipTiles(compact: true))],
      const SizedBox(height: 10), _keyTitle(),
      if (picks == null || picks!.isEmpty) _squadPending() else ...picks!.take(3).map(_playerRow),
    ],
    const SizedBox(height: 16), _cta(wide: false),
  ]);
}
