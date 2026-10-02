import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/theme.dart';
import '../../models/fixture.dart';
import 'fixture_widgets.dart';

/// A16 — Fixtures (/fixtures?gw=N).
/// GET /api/app/fixtures?gw= → {current, gw?, fixtures[{id, gw, home, away, hs, as, ko (UTC), min, status up|live|ft}]}.
/// Grouped by local match day, filter All / Live / Upcoming / Finished, gameweek summary.
/// Polls every 30s while a match is live. [filter] preselects All / Live / Upcoming / Finished (/results opens Finished).
class FixturesListPage extends StatefulWidget { final int? gw; final String filter; const FixturesListPage({super.key, this.gw, this.filter = 'all'}); @override State<FixturesListPage> createState() => _FixturesState(); }

class _FixturesState extends State<FixturesListPage> {
  late int? gw = widget.gw; late String filter = widget.filter; bool _live = false;

  static DateTime? _ko(Fixture f) => kickoffLocal(f);
  static BoxDecoration _box({Color? border}) => fixtureBox(border: border);

  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(key: ValueKey('$gw'), load: () => Repo.I.fixtures(gw: gw), poll: _live ? const Duration(seconds: 30) : const Duration(minutes: 5), builder: (c, j, _) {
    final all = jListOf(j['fixtures'], Fixture.fromJson);
    final cur = jInt(j['current'], 1);
    final shown = gw ?? jIntN(j['gw']) ?? (all.isNotEmpty ? all.first.gw : cur);
    final anyLive = all.any((f) => f.status == 'live');
    if (anyLive != _live) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _live = anyLive); });
    final fx = all.where((f) => filter == 'all' || f.status == filter).toList()
      ..sort((a, b) => (_ko(a) ?? DateTime(3000)).compareTo(_ko(b) ?? DateTime(3000)));
    final wide = MediaQuery.of(c).size.width >= 1100;
    final list = _list(c, fx);
    return ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      _header(c, shown, cur),
      const SizedBox(height: 14),
      _filters(all),
      const SizedBox(height: 14),
      wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: list), const SizedBox(width: 16), Expanded(flex: 1, child: _summary(shown, all))])
           : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_summary(shown, all), const SizedBox(height: 14), list]),
    ]);
  })));

  Widget _header(BuildContext c, int shown, int cur) {
    Widget nav(IconData i, bool on, int to) => IconButton.filledTonal(onPressed: on ? () => setState(() => gw = to) : null, icon: Icon(i),
        style: IconButton.styleFrom(backgroundColor: Wz.panel2, foregroundColor: Colors.white, disabledBackgroundColor: Wz.panel, disabledForegroundColor: Wz.faint));
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FIXTURES', style: anton(Bp.compact(c) ? 30 : 40, color: Colors.white, spacing: 1)),
        Text('Gameweek $shown${shown == cur ? ' · current' : ''}', style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
      ])),
      if (shown != cur) Padding(padding: const EdgeInsets.only(right: 8), child: TextButton(onPressed: () => setState(() => gw = cur), child: const Text('Current'))),
      nav(Icons.chevron_left_rounded, shown > 1, shown - 1), const SizedBox(width: 8), nav(Icons.chevron_right_rounded, shown < 38, shown + 1),
    ]);
  }

  Widget _filters(List<Fixture> all) {
    int n(String s) => all.where((f) => f.status == s).length;
    final opts = [('all', 'All', all.length), ('live', 'Live', n('live')), ('up', 'Upcoming', n('up')), ('ft', 'Finished', n('ft'))];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      for (final o in opts) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
        selected: filter == o.$1, onSelected: (_) => setState(() => filter = o.$1), showCheckmark: false,
        label: Text('${o.$2}  ${o.$3}'), labelStyle: TextStyle(color: filter == o.$1 ? Wz.onPrimary : Colors.white, fontWeight: FontWeight.w600),
        selectedColor: o.$1 == 'live' ? Wz.red : Wz.green, backgroundColor: Wz.panel, side: const BorderSide(color: Wz.border2))),
    ]));
  }

  Widget _list(BuildContext c, List<Fixture> fx) {
    if (fx.isEmpty) return Container(padding: const EdgeInsets.all(24), decoration: _box(), child: const Center(child: Text('No matches here.', style: TextStyle(color: Wz.muted))));
    final days = <String, List<Fixture>>{};
    for (final f in fx) { final d = _ko(f); days.putIfAbsent(d == null ? 'Date to be confirmed' : DateFormat('EEEE d MMMM').format(d), () => []).add(f); }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final e in days.entries) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.fromLTRB(14, 12, 14, 6), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(e.key.toUpperCase(), style: const TextStyle(color: Wz.green, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
        for (final f in e.value) FixtureRow(f, compact: Bp.compact(c)),
      ])),
    ]);
  }

  Widget _summary(int shown, List<Fixture> all) {
    final played = all.where((f) => f.status != 'up').toList();
    final goals = played.fold<int>(0, (s, f) => s + (f.hs ?? 0) + (f.as_ ?? 0));
    final live = all.where((f) => f.status == 'live').length;
    final ft = all.where((f) => f.status == 'ft').length;
    Widget kv(IconData i, Color col, String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Icon(i, color: col, size: 20), const SizedBox(width: 10), Text(k, style: const TextStyle(color: Wz.muted, fontSize: 13)), const Spacer(), Text(v, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))]));
    return Container(padding: const EdgeInsets.all(16), decoration: _box(border: live > 0 ? Wz.red.withValues(alpha: .4) : null), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('GW $shown SUMMARY', style: const TextStyle(color: Wz.green, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const SizedBox(height: 6),
      kv(Icons.sports_soccer_rounded, Colors.white, 'Matches', '${all.length}'),
      kv(Icons.check_circle_outline_rounded, Wz.green, 'Finished', '$ft'),
      kv(Icons.sensors_rounded, Wz.red, 'Live now', '$live'),
      kv(Icons.sports_score_rounded, Wz.gold, 'Goals', '$goals'),
      if (played.isNotEmpty) kv(Icons.functions_rounded, Wz.cyan, 'Goals / match', (goals / played.length).toStringAsFixed(1)),
      if (live > 0) ...[const SizedBox(height: 8), FilledButton.icon(onPressed: () => context.go('/live'), style: FilledButton.styleFrom(backgroundColor: Wz.red, foregroundColor: Colors.white), icon: const Icon(Icons.sensors_rounded), label: const Text('Live Match Centre'))],
    ]));
  }
}
