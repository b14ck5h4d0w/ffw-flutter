import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/layout.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'features/admin/admin_pages.dart';
import 'features/auth/forgot_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/reset_page.dart';
import 'features/auth/splash_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/chat/chat_page.dart';
import 'features/clans/clans_pages.dart';
import 'features/fixtures/match_detail_page.dart';
import 'features/fixtures/fixtures_list_page.dart';
import 'features/fixtures/live_centre_page.dart';
import 'features/fpl/connect_fpl_page.dart';
import 'features/fpl/fpl_found_page.dart';
import 'features/fpl/fpl_sync_page.dart';
import 'features/home/home_page.dart';
import 'features/leagues/leagues_hub_page.dart';
import 'features/leagues/league_page.dart';
import 'features/leagues/create_league_page.dart';
import 'features/leagues/join_league_page.dart';
import 'features/leagues/manage_page.dart';
import 'features/modes/mode_views.dart';
import 'features/misc/legal_page.dart';
import 'features/misc/misc_pages.dart';
import 'features/misc/more_page.dart';
import 'features/profile/manager_area.dart';
import 'features/notifications/notification_prefs_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/players/players_pages.dart';
import 'features/players/player_profile_page.dart';
import 'features/profile/me_page.dart';
import 'features/team/my_team_page.dart';
import 'features/team/points_page.dart';
import 'features/transfers/transfers_page.dart';

/// Path URLs mirror the old website so every link keeps working. Same app for Android, iOS and Web.
final router = GoRouter(
  refreshListenable: Session.I,
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (c, s) => const WelcomePage()),
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
    GoRoute(path: '/legal/:kind', builder: (c, s) => LegalPage(s.pathParameters['kind']!)),
    GoRoute(path: '/connect-fpl', builder: (c, s) => const ConnectFplPage()),
    GoRoute(path: '/connect-fpl/sync', builder: (c, s) => FplSyncPage(entry: int.tryParse(s.uri.queryParameters['entry'] ?? ''))),
    GoRoute(path: '/connect-fpl/done', builder: (c, s) => const FplFoundPage()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingPage()),
    GoRoute(path: '/settings/notifications', builder: (c, s) => const NotificationPrefsPage()),
    GoRoute(path: '/forgot', builder: (c, s) => ForgotPage(initialEmail: s.uri.queryParameters['email'] ?? '')),
    GoRoute(path: '/reset', builder: (c, s) => ResetPage(s.uri.queryParameters['token'] ?? '')),
    GoRoute(path: '/auth/google/done', builder: (c, s) => const GoogleDonePage()),
    ShellRoute(builder: (c, s, child) => Shell(location: s.uri.path, child: child), routes: [
      GoRoute(path: '/home', builder: (c, s) => const HomePage()),
      GoRoute(path: '/more', builder: (c, s) => const MorePage()),
      GoRoute(path: '/dashboard', redirect: (c, s) => '/'),
      GoRoute(path: '/leagues', builder: (c, s) => const MyLeaguesPage()),
      GoRoute(path: '/leagues/directory', builder: (c, s) => const LeagueDirectoryPage()),
      GoRoute(path: '/my-leagues', redirect: (c, s) => '/leagues'),
      GoRoute(path: '/create-league', builder: (c, s) => const Guard(child: CreateLeaguePage())),
      GoRoute(path: '/join', builder: (c, s) => Guard(child: JoinLeaguePage(code: s.uri.queryParameters['code']))),
      GoRoute(path: '/league/:slug', builder: (c, s) => LeaguePage(s.pathParameters['slug']!)),
      GoRoute(path: '/league/:slug/standings', builder: (c, s) => LeaguePage(s.pathParameters['slug']!, tab: 'table')),
      GoRoute(path: '/league/:slug/survivor', builder: (c, s) => LeaguePage(s.pathParameters['slug']!, tab: 'survivor')),
      GoRoute(path: '/league/:slug/civil-war', builder: (c, s) => LeaguePage(s.pathParameters['slug']!, tab: 'civil-war')),
      GoRoute(path: '/league/:slug/h2h', builder: (c, s) => LeaguePage(s.pathParameters['slug']!, tab: 'h2h')),
      GoRoute(path: '/league/:slug/rules', builder: (c, s) => LeaguePage(s.pathParameters['slug']!, tab: 'rules')),
      GoRoute(path: '/league/:slug/members', builder: (c, s) => LeaguePage(s.pathParameters['slug']!, tab: 'members')),
      GoRoute(path: '/league/:slug/requests', builder: (c, s) => LeaguePage(s.pathParameters['slug']!, tab: 'requests')),
      GoRoute(path: '/league/:slug/history', builder: (c, s) => LeaguePage(s.pathParameters['slug']!, tab: 'history')),
      GoRoute(path: '/manage/:slug', builder: (c, s) => Guard(child: ManageLeaguePage(s.pathParameters['slug']!))),
      GoRoute(path: '/modes', builder: (c, s) => const ModesPage()),
      GoRoute(path: '/live', builder: (c, s) => const LiveCentrePage()),
      GoRoute(path: '/fixtures', builder: (c, s) => FixturesListPage(gw: int.tryParse(s.uri.queryParameters['gw'] ?? ''))),
      GoRoute(path: '/match/:id', builder: (c, s) => MatchDetailPage(int.parse(s.pathParameters['id']!), tab: s.uri.queryParameters['tab'])),
      GoRoute(path: '/players', builder: (c, s) => const PlayersPage()),
      GoRoute(path: '/players/:id', builder: (c, s) => PlayerProfilePage(int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/transfers', builder: (c, s) => Guard(child: TransfersPage(preIn: int.tryParse(s.uri.queryParameters['in'] ?? '')))),
      GoRoute(path: '/clans', builder: (c, s) => const ClansPage()),
      GoRoute(path: '/clan/:slug', builder: (c, s) => ClanPage(s.pathParameters['slug']!, tab: s.uri.queryParameters['tab'])),
      GoRoute(path: '/chat/:kind/:slug', builder: (c, s) => Guard(child: ChatPage(s.pathParameters['kind']!, s.pathParameters['slug']!))),
      GoRoute(path: '/manager/:id', builder: (c, s) => ManagerPage(int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/notifications', builder: (c, s) => const Guard(child: NotificationsPage())),
      GoRoute(path: '/me', builder: (c, s) => const MePage()),
      GoRoute(path: '/me/edit', builder: (c, s) => const EditProfilePage()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsPage()),
      GoRoute(path: '/profile', redirect: (c, s) => '/me'),
      GoRoute(path: '/rankings', builder: (c, s) => const Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: LeagueStandings('fpl-warzone-global', padding: EdgeInsets.fromLTRB(24, 20, 24, 28), title: 'Global Rankings')))),
      GoRoute(path: '/table', builder: (c, s) => const TablePage()),
      GoRoute(path: '/results', builder: (c, s) => FixturesListPage(gw: int.tryParse(s.uri.queryParameters['gw'] ?? ''), filter: 'ft')),
      GoRoute(path: '/history', builder: (c, s) => const HistoryPage()),
      GoRoute(path: '/hof', builder: (c, s) => HofPage(league: s.uri.queryParameters['league'], season: s.uri.queryParameters['season'])),
      GoRoute(path: '/league/:slug/hof', builder: (c, s) => HofPage(league: s.pathParameters['slug'])),
      GoRoute(path: '/squad', builder: (c, s) => const Guard(child: MyTeamPage())),
      GoRoute(path: '/points', builder: (c, s) => Guard(child: PointsPage(gw: int.tryParse(s.uri.queryParameters['gw'] ?? '')))),
      GoRoute(path: '/hits', builder: (c, s) => const Guard(child: HitsPage())),
      GoRoute(path: '/chips', builder: (c, s) => const Guard(child: ChipsPage())),
      GoRoute(path: '/gw-history', builder: (c, s) => const Guard(child: GwHistoryPage())),
      GoRoute(path: '/global', redirect: (c, s) => '/league/fpl-warzone-global'),
      GoRoute(path: '/about', builder: (c, s) => const AboutPage()),
    ]),
    ShellRoute(builder: (c, s, child) => AdminShell(location: s.uri.path, child: child), routes: [
      GoRoute(path: '/admin', builder: (c, s) => const AdminDashboard()),
      GoRoute(path: '/admin/leagues', builder: (c, s) => const AdminLeagues()),
      GoRoute(path: '/admin/users', builder: (c, s) => const AdminUsers()),
      GoRoute(path: '/admin/clans', builder: (c, s) => const AdminClans()),
      GoRoute(path: '/admin/hof', builder: (c, s) => const AdminHof()),
      GoRoute(path: '/admin/live', builder: (c, s) => const AdminLive()),
      GoRoute(path: '/admin/api', builder: (c, s) => const AdminApi()),
      GoRoute(path: '/admin/branding', builder: (c, s) => const AdminBranding()),
      GoRoute(path: '/admin/logs', builder: (c, s) => const AdminLogs()),
      GoRoute(path: '/admin/settings', builder: (c, s) => const AdminSettings()),
      GoRoute(path: '/admin/broadcast', builder: (c, s) => const AdminBroadcast()),
    ]),
  ],
  errorBuilder: (c, s) => Scaffold(backgroundColor: Wz.bg, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('404', style: anton(64, color: Wz.green)), const SizedBox(height: 6), const Text('That page does not exist.', style: TextStyle(color: Wz.muted)), const SizedBox(height: 16), FilledButton(onPressed: () => c.go('/home'), child: const Text('Back to Home'))]))),
);

class FfwApp extends StatelessWidget { const FfwApp({super.key});
  // One router app from the first frame: swapping in a temporary MaterialApp while booting
  // reset the web URL to "/" and lost deep links (/register, /league/…) on a cold load.
  @override Widget build(BuildContext c) => MaterialApp.router(title: 'FFW · Fantasy Football Warzone', theme: Wz.theme(), routerConfig: router, debugShowCheckedModeBanner: false,
      builder: (c, child) => ListenableBuilder(listenable: Session.I, builder: (c, _) => Session.I.ready ? child! : const Scaffold(body: Center(child: CircularProgressIndicator(color: Wz.green)))));
}
