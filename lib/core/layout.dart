import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'assets.dart';
import 'brand.dart';
import 'session.dart';
import 'theme.dart';

class Bp {
  static bool compact(BuildContext c) => MediaQuery.of(c).size.width < 600;
  /// Desktop shell (sidebar + top bar) from 950 wide, matching the screens' own wide layouts.
  static bool desktop(BuildContext c) => MediaQuery.of(c).size.width >= 950;
  static bool expanded(BuildContext c) => MediaQuery.of(c).size.width >= 1200;
}

/// Responsive app shell for the signed-in/public app (not admin — /admin/* has AdminShell).
/// Phone: 5-item bottom nav (Home · Leagues · Live · Players · More). Tablet: the same 5 as a rail.
/// Desktop: FFW top bar + left sidebar with the full menu. Active state = URL prefix.
class Shell extends StatelessWidget {
  final Widget child; final String location;
  const Shell({super.key, required this.child, required this.location});

  static const tabs = [('/home', 'Home', Icons.home_rounded), ('/leagues', 'Leagues', Icons.emoji_events_rounded), ('/live', 'Live', Icons.sensors_rounded), ('/players', 'Players', Icons.person_search_rounded), ('/more', 'More', Icons.menu_rounded)];
  /// Paths reached from the "More" tab, so it stays highlighted there.
  static const _moreRoots = ['/more', '/modes', '/clans', '/clan/', '/me', '/profile', '/notifications', '/table', '/results', '/history', '/hof', '/squad', '/points', '/chips', '/hits', '/gw-history', '/rankings', '/about', '/manager/', '/transfers'];

  /// "/clan/" matches any child path; "/leagues" matches itself and "/leagues/…".
  static bool _on(String loc, String p) => p.endsWith('/') ? loc.startsWith(p) : (loc == p || loc.startsWith('$p/'));

  int _tab() {
    if (_on(location, '/leagues') || _on(location, '/league/') || _on(location, '/manage/') || location == '/create-league' || location == '/join') return 1;
    if (_on(location, '/live') || _on(location, '/match/') || _on(location, '/fixtures')) return 2;
    if (_on(location, '/players')) return 3;
    if (_moreRoots.any((p) => _on(location, p))) return 4;
    return 0;
  }

  @override Widget build(BuildContext c) {
    if (Bp.desktop(c)) return _desktop(c);
    final i = _tab();
    if (!Bp.compact(c)) {
      return Scaffold(body: Row(children: [
        NavigationRail(selectedIndex: i, onDestinationSelected: (n) => c.go(tabs[n].$1), labelType: NavigationRailLabelType.all, backgroundColor: Wz.panel,
            leading: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: FfwWordmark(height: 18, full: false)),
            indicatorColor: Wz.green.withValues(alpha: .18), selectedIconTheme: const IconThemeData(color: Wz.green), unselectedIconTheme: const IconThemeData(color: Wz.muted),
            selectedLabelTextStyle: const TextStyle(color: Wz.green, fontWeight: FontWeight.w700), unselectedLabelTextStyle: const TextStyle(color: Wz.muted),
            destinations: tabs.map((t) => NavigationRailDestination(icon: Icon(t.$3), label: Text(t.$2))).toList()),
        const VerticalDivider(width: 1, color: Wz.border), Expanded(child: child)]));
    }
    return Scaffold(body: child, bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (n) => c.go(tabs[n].$1), height: 64,
        destinations: tabs.map((t) => NavigationDestination(icon: Icon(t.$3), label: t.$2)).toList()));
  }

  // ---------- desktop ----------
  static const _side = [
    ('/home', 'Dashboard', Icons.home_rounded), ('/squad', 'My Team', Icons.shield_outlined), ('/points', 'Points', Icons.bolt_rounded), ('/leagues', 'Leagues', Icons.emoji_events_outlined),
    ('/modes', 'Modes', Icons.sports_mma_rounded), ('/live', 'Live', Icons.sensors_rounded), ('/fixtures', 'Fixtures', Icons.calendar_month_outlined), ('/players', 'Players', Icons.person_search_rounded),
    ('/clans', 'Clans', Icons.groups_outlined), ('/rankings', 'Rankings', Icons.leaderboard_outlined), ('/notifications', 'Notifications', Icons.notifications_none_rounded),
    ('/me', 'Account', Icons.person_outline_rounded), ('/about', 'Help', Icons.help_outline_rounded),
  ];

  bool _sideOn(String p) => switch (p) {
    '/leagues' => _tab() == 1,
    '/live' => _on(location, '/live') || _on(location, '/match/'),
    '/clans' => _on(location, '/clans') || _on(location, '/clan/'),
    '/me' => _on(location, '/me') || _on(location, '/profile') || location.startsWith('/settings'),
    _ => _on(location, p),
  };

  Widget _desktop(BuildContext c) {
    final s = Session.I;
    return Scaffold(backgroundColor: Wz.bg, body: Column(children: [
      ShellTopBar(onHome: () => c.go('/home')),
      Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 232, decoration: const BoxDecoration(color: Wz.panel, border: Border(right: BorderSide(color: Wz.border))), child: ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 16), children: [
          for (final it in _side) if (s.loggedIn || !const ['/squad', '/points', '/notifications', '/me'].contains(it.$1)) _SideItem(icon: it.$3, label: it.$2, on: _sideOn(it.$1), onTap: () => c.go(it.$1)),
          if (s.isAdmin) _SideItem(icon: Icons.admin_panel_settings_outlined, label: 'Admin', color: Wz.purple2, on: false, onTap: () => c.go('/admin')),
          if (s.loggedIn) _SideItem(icon: Icons.logout_rounded, label: 'Log Out', on: false, onTap: () async { await Session.I.logout(); if (c.mounted) c.go('/welcome'); })
          else _SideItem(icon: Icons.login_rounded, label: 'Login', color: Wz.green, on: false, onTap: () => c.go('/login')),
          const SizedBox(height: 18),
          Container(height: 150, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)), child: Stack(fit: StackFit.expand, children: [
            Image.asset(WzAssets.stadium, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(.55)),
            Center(child: Transform.rotate(angle: -.1, child: Column(mainAxisSize: MainAxisSize.min, children: [
              const FfwCrown(size: 26), Text('Same game.\nSame passion.', textAlign: TextAlign.center, style: script(24)), const SizedBox(height: 4), const FfwWordmark(height: 16, full: false)]))),
          ])),
          const SizedBox(height: 14),
          const Text('MORE THAN A GAME.', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.6)),
          const Text('A BATTLE OF MINDS.', style: TextStyle(color: Wz.green, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.6)),
        ])),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1480), child: child))),
      ])),
    ]));
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon; final String label; final bool on; final VoidCallback onTap; final Color? color;
  const _SideItem({required this.icon, required this.label, required this.on, required this.onTap, this.color});
  @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
    child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: on ? Wz.green.withValues(alpha: .14) : null, borderRadius: BorderRadius.circular(8), border: on ? Border.all(color: Wz.green.withValues(alpha: .45)) : null),
      child: Row(children: [
        Icon(icon, size: 21, color: on ? Wz.green : (color ?? Colors.white.withValues(alpha: .85))), const SizedBox(width: 14),
        Text(label, style: TextStyle(color: on ? Wz.green : (color ?? Colors.white.withValues(alpha: .9)), fontSize: 14, fontWeight: on ? FontWeight.w600 : FontWeight.w500)),
      ])))));
}

/// Desktop top bar: FFW wordmark · search · notifications · user (or Login / Join).
class ShellTopBar extends StatelessWidget {
  final VoidCallback onHome; const ShellTopBar({super.key, required this.onHome});
  @override Widget build(BuildContext c) {
    final s = Session.I;
    return Container(height: 68, padding: const EdgeInsets.symmetric(horizontal: 24), decoration: const BoxDecoration(color: Wz.bg, border: Border(bottom: BorderSide(color: Wz.border))), child: Row(children: [
      InkWell(onTap: onHome, child: const FfwWordmark(height: 28)),
      const Spacer(),
      IconButton(onPressed: () => c.go('/players'), tooltip: 'Search players', icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24)),
      if (s.loggedIn) ...[
        const SizedBox(width: 4),
        IconButton(onPressed: () => c.go('/notifications'), tooltip: 'Notifications', icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24)),
        const SizedBox(width: 10),
        InkWell(onTap: () => c.go('/me'), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Row(children: [
          HexAvatar(s.user!.initials, url: s.user!.avatar, size: 36), const SizedBox(width: 10),
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.user!.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(s.user!.team.isEmpty ? 'FPL Manager' : s.user!.team, style: const TextStyle(color: Wz.muted, fontSize: 11.5)),
          ]),
        ]))),
      ] else ...[
        const SizedBox(width: 10),
        OutlinedButton(onPressed: () => c.go('/login'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), child: const Text('Login')),
        const SizedBox(width: 8),
        FilledButton(onPressed: () => c.go('/register'), child: const Text('Join')),
      ],
    ]));
  }
}

/// Page scaffold with title, optional actions and max-width body.
class WzPage extends StatelessWidget {
  final String title; final String? subtitle; final Widget body; final List<Widget> actions; final bool back; final Widget? fab;
  const WzPage({super.key, required this.title, this.subtitle, required this.body, this.actions = const [], this.back = false, this.fab});
  @override Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(automaticallyImplyLeading: back, leading: back ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => c.canPop() ? c.pop() : c.go('/')) : null,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Wz.green2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2))]), actions: actions),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: body))), floatingActionButton: fab);
}
class Pad extends StatelessWidget { final Widget child; const Pad({super.key, required this.child}); @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), child: child); }

class Guard extends StatelessWidget {
  final Widget child; final bool admin; const Guard({super.key, required this.child, this.admin = false});
  @override Widget build(BuildContext c) {
    final s = Session.I;
    if (!s.loggedIn) return WzPage(title: 'Sign in', body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Muted('Sign in to continue.'), const SizedBox(height: 12), FilledButton(onPressed: () => c.go('/login'), child: const Text('Sign in'))])));
    if (admin && !s.isAdmin) return const WzPage(title: 'Admins only', body: Center(child: Muted('Admins only.')));
    return child;
  }
}
