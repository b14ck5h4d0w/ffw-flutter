# FFW — Fantasy Football Warzone · Master Prompt for Claude Code

Paste this whole file to Claude Code (Android Studio) as the first message, then attach the `ffw` project + the `mockups/` and `assets/` folders.

## What this project is
A cross-platform **Flutter** app (Android + iOS + Web) for **Fantasy Premier League private-league tournaments**: Ranking, Last Survivor, Civil War, Head-to-Head. It talks to an existing **Python/Flask backend** (already live at `https://fplwarzone.com`) over JSON. You are building/finishing the **Flutter UI only** — do NOT rebuild the backend.

- Brand: **FFW — Fantasy Football Warzone**. Package id: `com.ffwarzone.app`. Website label stays "FPL Warzone".
- Design language: dark cinematic (stadium imagery on auth), **Anton** font for hero/section titles (uppercase, letter-spacing 0.5–1.5), **Inter** for all UI (400–700). Accent green `#16E88A`, teal `#14E0C8`, purple `#8B5CF6`, gold `#F5B942`, red `#EF4444`, bg `#060B12`.
- Data-heavy screens stay clean (cards, soft rounded, readable) — cinematic look is for splash/auth/hero only.

## Golden rules
1. **Backend is fixed and live.** Every screen gets its data from `lib/core/repo.dart` (one method per `/api/app/*` endpoint) and admin from `lib/features/admin/admin_repo.dart` (`/api/admin/*`). Never invent endpoints — if you need one that isn't there, STOP and ask; don't stub fake data.
2. **Design comes from the mockups.** Each screen has a numbered mockup (A01, A02, … and section screens). Build the screen to match its mockup pixel-close, responsive: phone (bottom-nav, one column) and desktop/web (top bar, multi-column). The same widget serves both via `MediaQuery` width breakpoints (≥950 = wide).
3. **One screen at a time.** For each mockup: build it, run `flutter analyze` (must be error-free), then `flutter run`/build web to verify. Only then move on.
4. **Auth model:** bearer token from `/api/app/auth/login|register`, stored in secure storage (mobile) / shared_preferences (web) — already wired in `lib/core/api.dart` + `session.dart`. Google sign-in via `/login/google?next=/auth/google/done` → `#token=` → `auth/exchange`. Apple button shows "coming soon" until Apple credentials are configured.
5. **FPL connection is on-device, never server-side.** Mobile: user logs into FPL's own page in an in-app WebView (`flutter_inappwebview`), cookie kept in secure storage, transfers posted phone→FPL. Web: link by public entry id, writes hand off to the app. Code is in `lib/features/fpl/`. Never send FPL credentials to our server.
6. **Errors:** the API returns `{ok:false,error:{code,message,problems}}`. `ApiClient` already parses this into `ApiException`. Show `message`; use the `Async` widget (`lib/core/theme.dart`) for load/error/retry.

## Current status (what's already built — verify, don't redo blindly)
- **Core** (`lib/core/`): `config.dart` (baseUrl), `json.dart` (tolerant parse helpers jInt/jStr/jBool/jMap/jListOf), `api.dart` (Dio bearer client + error envelope), `session.dart` (login state, flags, forgot/reset), `repo.dart` (~70 endpoint methods), `theme.dart` (design tokens, `anton()` helper, WzCard/Eyebrow/StatusPill/HexAvatar/Async widgets), `layout.dart` (responsive Shell: bottom-nav phone / rail tablet / top-bar desktop; WzPage; Guard), `slide_nav.dart`.
- **Models** (`lib/models/`): user, player (photo/badge via same-origin proxy `/img/player/<code>.png`), league/row/clan, fixture.
- **Auth**: A01 Splash (`splash_page.dart`), A02 Welcome (`welcome_page.dart`), A03 Login + Reset (`login_page.dart`), Google done (`auth_pages.dart`). A04 Register currently reuses LoginPage(register:true) — REBUILD to match the A04 mockup.
- **Features** built (functional, may need restyle to final design): home, leagues (+detail tabs Table/Survivor/CivilWar/H2H/Members/Rules/History, create, manage), modes, clans (+captain tools), players (+profile weather-card), fixtures (live + match), transfers (planner + confirm), chat, notifications, profile (me, manager), misc (table/results/history/hof), manager_area (squad/hits/chips/gw-history), admin (11 screens).
- **Routes**: 55 in `lib/app.dart`, mirroring the old website paths so deep links work (`/league/:slug`, `/players/:id`, `/clan/:slug`, `/manage/:slug`, `/admin/*`, `/table`, `/results`, `/history`, `/squad`, `/chips`, …).
- **Assets**: `assets/img/{stadium.jpg,player10.png,logo.png}`, `assets/fonts/Anton-Regular.ttf` (declared in pubspec).
- **Backend live**: `/api/app/*` (public + manager), `/api/admin/*` (admin), FPL sync loop, Google OAuth, `/img/*` photo proxy, `/avatar/<id>.svg` generated default avatars, SMTP (welcome/reset/test email).

## The ~60 screens to finish (design from mockups)
Auth & onboarding: A01 Splash ✅, A02 Welcome ✅, A03 Login ✅, A04 Register (rebuild to mockup). Then, per the mockup set: Home/dashboard, My Team (pitch), Points, Player profile, Modes, Transfers, Player sheet, Leagues list, League table, Civil War (overview/standings/gameweeks/clans), Last Survivor (overview/rounds), Head-to-Head bracket, Live matches, Match detail, Rankings, Clans directory, Clan detail, Clan chat, Create league (+ Survivor auto-schedule wizard), Manage league, Hall of Fame, Notifications, Me/profile, User profile, News, plus the 11 Admin screens (dashboard, leagues, users, clans, modes, HOF, live, API center, media, branding, settings, broadcast). Match each to its mockup.

## Environment / build
- `flutter create --platforms android,ios,web --org com.ffwarzone --project-name fpl_warzone .` (once, to generate platform folders around `lib/`).
- Android: `applicationId "com.ffwarzone.app"`, minSdk 24, INTERNET permission, app label "FFW". Add `flutter_inappwebview` + `flutter_secure_storage` (already in pubspec).
- Base URL defaults to `https://fplwarzone.com` (override with `--dart-define=WZ_BASE_URL=...`).
- Web build: `flutter build web --release --base-href /` → deploy `build/web`. Nginx already routes `/api/`, `/admin`, `/avatar/`, `/img/`, `/login/google`, `/auth/` to Flask and everything else to the Flutter build.

## Workflow with the user (Sohel)
For each screen: user sends the mockup image → you say exactly what you need (any new asset, any missing endpoint, any decision) → user submits → you build the Flutter screen to match, run `flutter analyze` clean, and confirm "DONE" with what changed. Never guess an endpoint or fake data; ask instead. Keep the backend untouched.
