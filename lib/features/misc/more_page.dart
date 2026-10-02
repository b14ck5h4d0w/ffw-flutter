import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/brand.dart';
import '../../core/session.dart';
import '../../core/theme.dart';

/// "More" tab (/more): everything that doesn't fit the 5-item bottom nav.
/// Signed-in-only entries are hidden for visitors; Admin only for admins.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override Widget build(BuildContext c) => ListenableBuilder(listenable: Session.I, builder: (c, _) {
    final s = Session.I; final u = s.user;
    final groups = <(String, List<(IconData, String, String, Color?)>)>[
      ('Compete', [
        (Icons.sports_mma_rounded, 'Modes', '/modes', null),
        (Icons.groups_outlined, 'Clans', '/clans', null),
        (Icons.leaderboard_outlined, 'Rankings', '/rankings', null),
        (Icons.military_tech_outlined, 'Hall of Fame', '/hof', Wz.gold),
      ]),
      if (s.loggedIn) ('My FPL', [
        (Icons.shield_outlined, 'My Squad', '/squad', null),
        (Icons.bolt_outlined, 'Gameweek Points', '/points', null),
        (Icons.bolt_rounded, 'Chips', '/chips', null),
        (Icons.remove_circle_outline_rounded, 'Points Hits', '/hits', null),
        (Icons.history_rounded, 'Gameweek History', '/gw-history', null),
      ]),
      ('Premier League', [
        (Icons.calendar_month_outlined, 'Fixtures', '/fixtures', null),
        (Icons.table_chart_outlined, 'Table', '/table', null),
        (Icons.scoreboard_outlined, 'Results', '/results', null),
        (Icons.auto_stories_outlined, 'History', '/history', null),
      ]),
      ('Account', [
        if (s.loggedIn) ...[
          (Icons.person_outline_rounded, 'Me', '/me', null),
          (Icons.notifications_none_rounded, 'Notifications', '/notifications', null),
          (Icons.tune_rounded, 'Notification Settings', '/settings/notifications', null),
        ],
        if (s.isAdmin) (Icons.admin_panel_settings_outlined, 'Admin', '/admin', Wz.purple2),
        (Icons.help_outline_rounded, 'Help & About', '/about', null),
      ]),
    ];
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      Row(children: [const FfwWordmark(height: 24), const Spacer(), if (s.loggedIn) HexAvatar(u!.initials, url: u.avatar, size: 38)]),
      const SizedBox(height: 18),
      if (s.loggedIn) Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)), child: Row(children: [
        HexAvatar(u!.initials, url: u.avatar, size: 48), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          Text(u.fpl == null ? 'FPL team not connected' : (u.team.isEmpty ? 'FPL Team ID ${u.fpl}' : u.team), style: TextStyle(color: u.fpl == null ? Wz.gold : Wz.muted, fontSize: 12.5)),
        ])),
        if (u.fpl == null) TextButton(onPressed: () => c.go('/connect-fpl'), style: TextButton.styleFrom(foregroundColor: Wz.green), child: const Text('Connect'))
        else IconButton(onPressed: () => c.go('/me'), icon: const Icon(Icons.chevron_right_rounded, color: Wz.muted)),
      ]))
      else Row(children: [
        Expanded(child: FilledButton(onPressed: () => c.go('/login'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)), child: const Text('Login'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(onPressed: () => c.go('/register'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), child: const Text('Create Account'))),
      ]),
      for (final g in groups) if (g.$2.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.fromLTRB(4, 22, 4, 8), child: Text(g.$1.toUpperCase(), style: const TextStyle(color: Wz.green, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
        Container(decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)), child: Column(children: [
          for (final (i, it) in g.$2.indexed) ...[
            if (i > 0) const Divider(height: 1, color: Wz.border, indent: 52),
            ListTile(onTap: () => c.go(it.$3), leading: Icon(it.$1, color: it.$4 ?? Colors.white.withValues(alpha: .85)), title: Text(it.$2, style: TextStyle(color: it.$4 ?? Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Wz.muted)),
          ],
        ])),
      ],
      if (s.loggedIn) ...[
        const SizedBox(height: 22),
        OutlinedButton.icon(onPressed: () async { await Session.I.logout(); if (c.mounted) c.go('/welcome'); }, icon: const Icon(Icons.logout_rounded), label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(foregroundColor: Wz.red, side: BorderSide(color: Wz.red.withValues(alpha: .5)), minimumSize: const Size.fromHeight(46))),
      ],
    ])));
  });
}
