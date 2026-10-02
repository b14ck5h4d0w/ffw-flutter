# FFW — কতদূর হয়েছে (Status · 2026-10-01)

## সারাংশ
সব স্ক্রিন নতুন FFW cinematic design-এ লেখা হয়েছে। পুরনো Flask-style চেহারার কোনো পেজ বাকি নেই।
`flutter analyze`: No issues found · `flutter test`: 7টা pass · `flutter build web --release`: সফল।
Live server-এ এখনো deploy করা হয়নি; নিচের "যা যাচাই হয়নি" দেখুন।

## স্ক্রিন → route → ফাইল
| স্ক্রিন | Route | ফাইল |
|---|---|---|
| A01 Splash | `/` | features/auth/splash_page.dart |
| A02 Welcome | `/welcome` | features/auth/welcome_page.dart |
| A03 Login (+ Google done) | `/login`, `/auth/google/done` | features/auth/login_page.dart |
| A04 Register | `/register` | features/auth/register_page.dart |
| A05 Forgot / Reset | `/forgot`, `/reset?token=` | features/auth/forgot_page.dart, reset_page.dart |
| A06 Connect FPL | `/connect-fpl` | features/fpl/connect_fpl_page.dart |
| A07 Syncing | `/connect-fpl/sync?entry=` | features/fpl/fpl_sync_page.dart |
| A08 Team Found | `/connect-fpl/done` | features/fpl/fpl_found_page.dart |
| A09 Onboarding | `/onboarding` | features/onboarding/onboarding_page.dart |
| A10 Notification Preferences | `/settings/notifications` | features/notifications/notification_prefs_page.dart |
| A11 Home (login / public) | `/home` | features/home/home_page.dart |
| A12 My Team | `/squad` | features/team/my_team_page.dart |
| A13 Gameweek Points | `/points?gw=` | features/team/points_page.dart |
| A14 Player Details (sheet) | — | features/players/player_sheet.dart |
| A15 Player Profile | `/players/:id` | features/players/player_profile_page.dart |
| Players Hub, Help | `/players`, `/about` | features/players/players_pages.dart |
| A16 Fixtures (+ Results) | `/fixtures`, `/results` | features/fixtures/fixtures_list_page.dart |
| A17 Live Match Centre | `/live` | features/fixtures/live_centre_page.dart |
| A18–A20 Match (Overview/Timeline/Lineups) | `/match/:id?tab=` | features/fixtures/match_detail_page.dart |
| A21 My Leagues · A22 Directory | `/leagues`, `/leagues/directory` | features/leagues/leagues_hub_page.dart |
| A23 Join League | `/join?code=` | features/leagues/join_league_page.dart |
| A24 Create League (+ Survivor schedule A48/A49) | `/create-league` | features/leagues/create_league_page.dart |
| A25–A30 League (Overview/Standings/Members/Requests/Rules/History) | `/league/:slug[/tab]` | features/leagues/league_page.dart |
| League Settings (+ A50) | `/manage/:slug` | features/leagues/manage_page.dart |
| A31–A32 Hall of Fame | `/hof?league=&season=` | features/misc/misc_pages.dart |
| A33 Modes Hub, Ranking, Civil War (A38–A43), Last Survivor (A44–A47), H2H (A51–A55) | `/modes`, league tabs | features/modes/mode_views.dart |
| A56–A60 Clans | `/clans`, `/clan/:slug?tab=` | features/clans/clans_pages.dart |
| Clan / league chat | `/chat/:kind/:slug` | features/chat/chat_page.dart |
| A61 Profile · A62 Edit · A63 Settings · User profile | `/me`, `/me/edit`, `/settings`, `/manager/:id` | features/profile/me_page.dart |
| Chips, Hits, GW History | `/chips`, `/hits`, `/gw-history` | features/profile/manager_area.dart |
| T01–T04 Transfers | `/transfers?in=` | features/transfers/transfers_page.dart |
| Notifications inbox | `/notifications` | features/notifications/notifications_page.dart |
| PL Table, History | `/table`, `/history` | features/misc/misc_pages.dart |
| More (phone) | `/more` | features/misc/more_page.dart |
| Admin (১১টা স্ক্রিন) | `/admin/*` | features/admin/admin_pages.dart |

## গঠন
- `lib/core/`: `theme.dart` (রঙ, `anton()`, `script()`), `layout.dart` (Shell: phone-এ ৫টা bottom nav, desktop-এ sidebar), `assets.dart` (`WzAssets`), `brand.dart`, `repo.dart`, `api.dart`, `session.dart`।
- Admin-এর নিজের shell আলাদা (`AdminShell`)।
- Font: Anton (title), Inter 400–700 (UI), Mr Dafoe (হাতের লেখার flourish)। সব `assets/fonts/`-এ।
- 60টা Dart ফাইল, 71টা route। পুরনো route path বদলানো হয়নি।

## Live অবস্থা (২০২৬-১০-০২)
- নতুন Flutter web চলছে https://fplwarzone.com-এ (`/var/www/fpl_warzone/web`, আগের build `web.prev.*`-এ)। Backend এখনো ২২ সেপ্টেম্বরের পুরনোটা।
- VPS backup: `/home/administrator/ffw-backup-<তারিখ>/` (app + .env + uploads, MySQL dump, nginx/systemd config)।
- Live-এ login করে Home, My Team, Points, League Settings দেখে মিলিয়েছি। Admin: `lionkhan369@gmail.com` (role admin)।
- পুরনো backend-এ `GET auth/me` নেই → `Session.refreshMe` তখন `GET home`-এর `user` নেয়।
- `/admin` URL nginx এখনো পুরনো Flask admin-এ পাঠায়; নতুন admin খোলে app-এর sidebar থেকে।

## যা যাচাই হয়নি
- Phone-এ APK দিয়ে FPL-এর in-app login আর আসল transfer।
- Slide-to-confirm gesture শুধু automated test-এ যাচাই।

## Backend-এর কাছে বাকি
- League `public_view` (settings + league response) আর public_view চালু থাকলে token ছাড়া league/standings/survivor/civil-war/h2h/members/history; visitor-কে invite code/email না দেওয়া। App তৈরি: Settings-এ "Public view link" switch, League পেজে "Share League"।
  এখন visitor দেখে public `leagues/<slug>/history` থেকে বানানো Points Table + Gameweeks (`_GuestLeague`, `league_page.dart`)।
- Lineup position bug: `live_provider.py` `_pl18_lineups` "Centre Back"/"Defensive Midfield" চেনে না → সব MID। শব্দ দিয়ে মেলাতে হবে (keeper→GK, back/defen→DEF, midfield→MID, wing/forward/striker→FWD)।
- নতুন backend zip deploy (reset, badge_color, join slug/kind, auth/me, নতুন notification key)।
- `/opt/fpl-warzone`-এ পুরনো আরেকটা project-এর `fpl-process.service` প্রতিবার ব্যর্থ হয় (DB login)।

## API Center (admin)
- `GET api-center`, `POST api-center/live-provider {provider, host?, key?, enabled?, clear?}` — key DB-র settings table-এ থাকে। Server যেকোনো `enabled` মানকে "চালু" ধরে, তাই app বন্ধ থাকলে field পাঠায় না।
- premier-league18-এর path backend-এ বসানো; অন্য RapidAPI host হলে `api-center/rapid-endpoints`।

## Backend-এর সাথে মিলানো (২০২৬-১০-০১, Sohel-এর উত্তর অনুযায়ী)
- League crest: `badge_color` রঙের উপর নামের ২ অক্ষর (`LeagueCrest`, `core/theme.dart`)। logo থাকলে logo দেখায়।
- Join: `{ok, msg, slug, kind}`। `kind == 'clan'` হলে "Open Clan" বাটন দেখায়, না হলে "Open League"।
- Profile ছবি: `image_picker` দিয়ে gallery থেকে বাছাই, 800px-এ ছোট করে `POST /api/app/me/avatar`-এ পাঠায় (Edit Profile)।
- Lineup `pos` লুকানো, lineup `pts` = RATING, match stats বাদ। RapidAPI live provider configure হলে আসবে।
- Mockup-এর যেসব feature-এর API নেই সেগুলো (Achievements, 2FA, reactions, prize breakdown, GW avg/max) এখন বাদ।
- Terms: URL না দেওয়া পর্যন্ত "coming soon" দেখায় (`--dart-define=WZ_TERMS_URL=...`)।

## Android
- JDK 17: `%LOCALAPPDATA%\ffw-tools\jdk17`, SDK: `%LOCALAPPDATA%\Android\Sdk` (user env-এ `JAVA_HOME`, `ANDROID_HOME` সেট করা)।
- `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
- এখন debug key দিয়ে sign হয়। Play Store-এ দেওয়ার আগে নিজস্ব release keystore লাগবে।

## Deploy (web)
```
flutter build web --release --base-href /
tar -czf ffw_web.tgz -C build/web .
scp -P 10038 ffw_web.tgz administrator@93.127.138.67:~/
# VPS-এ:
mkdir -p ~/ffw_web_new && tar -xzf ~/ffw_web.tgz -C ~/ffw_web_new
sudo bash /var/www/fpl_warzone/deploy/deploy_web.sh ~/ffw_web_new
```
SSH key: এই PC-র `C:\Users\saimu\.ssh\ffw_deploy` (VPS-এ authorized)। অন্য computer থেকে করতে নিজের key বা password লাগবে।

## Laptop-এ শুরু করতে
Flutter SDK install → `flutter pub get` → `flutter run -d chrome`। `third_party/` রাখতে হবে (Android build-এর জন্য ঠিক করা inappwebview)।
