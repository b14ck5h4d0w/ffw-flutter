# FFW — Fantasy Football Warzone (Flutter: Android · iOS · Web · Admin)

One codebase against the live backend `https://fplwarzone.com` (`/api/app/*`, `/api/admin/*`).

## Setup (first time)
```bash
flutter create --platforms android,ios,web --org com.ffwarzone --project-name fpl_warzone .   # adds android/ ios/ web/ around this lib/
flutter pub get
flutter analyze && flutter test
```
Android: in `android/app/build.gradle` set `applicationId "com.ffwarzone.app"`, minSdk 24. Add to `android/app/src/main/AndroidManifest.xml`: `<uses-permission android:name="android.permission.INTERNET"/>`; app label `FFW`.
Web: `flutter build web --release` → copy `build/web` to the VPS (`deploy/deploy_web.sh` on the backend), nginx from `deploy/nginx-flutter-web.conf`.
CI: `.github/workflows/build.yml` builds web + debug APK on every push (use this if your PC blocks Flutter builds).

## How it's organised
- `lib/core/` — `api.dart` (Dio + bearer + error envelope), `session.dart` (login state, flags), `repo.dart` (every /api/app call), `theme.dart` (design tokens + widgets), `layout.dart` (responsive shell: bottom nav / rail / top bar)
- `lib/models/` — user, player (+club, photo/badge urls), league/row/clan, fixture
- `lib/features/` — auth, home (dashboard, My Team, Points), transfers (planner + confirm), players, fixtures (live + match), leagues (list, detail tabs Table/Survivor/Civil War/H2H/Members/Rules, create, manage), modes, clans (+captain tools), chat, notifications, profile (Me, manager), fpl (connect), admin (11 screens)
- FPL connection (`features/fpl/`): **mobile** — FPL's own login page in an in-app WebView, cookie kept in secure storage, transfers posted phone→FPL; **web** — link by public entry id, writes hand off to the app. The server never sees FPL credentials.

## Routes
Same paths as the old website (`/league/<slug>`, `/players/<id>`, `/clan/<slug>`, `/manage/<slug>`, `/admin/*` …) so old links work.
