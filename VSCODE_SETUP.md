# FFW — VS Code + Claude Code setup

Build the Flutter app in VS Code with Claude Code (the CLI agent). Backend stays live on the VPS; you only build/deploy the Flutter front-end.

## 0. One-time installs (Windows)
- **VS Code** + extensions: "Flutter" (Dart-Code) and "Claude Code" (or run Claude Code in the integrated terminal).
- **Flutter SDK** — https://docs.flutter.dev/get-started/install/windows → unzip to `C:\flutter`, add `C:\flutter\bin` to PATH, restart terminal, run `flutter doctor`.
- **Android**: Android Studio once (for the SDK + an emulator) OR a physical phone in USB-debug mode. VS Code uses that SDK; you don't code in Android Studio.
- **Claude Code CLI**: install per Anthropic docs, then `claude` in the project terminal.

## 1. Open the project
1. Unzip `ffw_for_android_studio.zip` (it's just the Flutter project — name doesn't matter) to e.g. `C:\dev\ffw`.
2. In VS Code: **File → Open Folder →** `C:\dev\ffw`.
3. Open the integrated terminal (Ctrl+`), then once:
   ```
   flutter create --platforms android,ios,web --org com.ffwarzone --project-name fpl_warzone .
   flutter pub get
   flutter analyze
   ```
   `flutter create` generates the `android/ ios/ web/` folders around the existing `lib/`; it will NOT overwrite your `lib/` or `pubspec.yaml`.

## 2. Start Claude Code
In the same terminal:
```
claude
```
Then paste the **entire** `CLAUDE_CODE_MASTER_PROMPT.md` as your first message, and tell it: "Read PROJECT_STATUS.md and the lib/ folder, then wait for mockups." Both docs are inside the project root.

Work one screen at a time: send Claude Code a mockup image → it asks what it needs → you answer → it builds the screen, runs `flutter analyze`, and reports DONE.

## 3. Run while developing
- **Web (fastest to check design):** `flutter run -d chrome` — hot-reload in the browser.
- **Phone:** plug in an Android phone (USB debugging on) or start an emulator, then `flutter run` and pick the device. Hot reload with `r`.
- Point at the live API (default) or override: `flutter run -d chrome --dart-define=WZ_BASE_URL=https://fplwarzone.com`.

## 4. Deploy the web build to the VPS
From VS Code terminal:
```
flutter build web --release --base-href /
```
Then upload `build/web` to the server (PowerShell):
```
scp -P 10038 -r build/web/* administrator@93.127.138.67:/tmp/ffwweb/
```
On the server:
```
sudo bash /var/www/fpl_warzone/deploy/deploy_web.sh /tmp/ffwweb
```
(Or keep building on the VPS as before — either works. Nginx already routes /api, /admin, /avatar, /img, /login/google, /auth to Flask and everything else to the Flutter build.)

## 5. Build the Android APK (for your phone / Play Store)
```
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`. Install on your phone to test the in-app FPL login + transfers. For Play Store use `flutter build appbundle --release`.

## Tips for Claude Code
- Tell it: "Backend is fixed and live — never invent endpoints; if one is missing, stop and ask." (This is in the master prompt.)
- Give it the mockup image for each screen; it matches pixel-close, responsive (phone + web).
- After each screen: it must run `flutter analyze` clean before moving on.
- If `analyze` shows real errors, paste them back to Claude Code to fix.
