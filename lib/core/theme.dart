import 'package:flutter/material.dart';
import 'config.dart';

/// FFW design tokens — locked to the final design pack (shared by web, app and admin).
/// `green` is the primary neon teal; the name is kept so existing screens pick it up.
/// Type: Anton (via [anton]) for hero/section titles, Inter 400–700 for everything else.
class Wz {
  static const bg = Color(0xFF03080D), panel = Color(0xFF07131A), panel2 = Color(0xFF0A1B23);
  static const text = Color(0xFFF4F8FA), muted = Color(0xFF87A3AE), faint = Color(0xFF557079);
  static const green = Color(0xFF12EFB4), green2 = Color(0xFF6CF6D0), greenD = Color(0xFF0CB88A), teal = Color(0xFF12EFB4), cyan = Color(0xFF2BCDFF);
  static const purple = Color(0xFF8B5CF6), purple2 = Color(0xFFA78BFA), gold = Color(0xFFF4BF3A), red = Color(0xFFFF455D), blue = Color(0xFF8FA8FF);
  static const border = Color(0xFF0F2E36), border2 = Color(0xFF14434D);
  static const onPrimary = Color(0xFF02110C);
  static Color hex(String h) { var s = h.replaceAll('#', ''); if (s.length == 6) s = 'FF$s'; return Color(int.tryParse(s, radix: 16) ?? 0xFF333333); }

  static ThemeData theme() {
    const font = 'Inter';
    return ThemeData(
      useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: bg, fontFamily: font,
      colorScheme: const ColorScheme.dark(primary: green, secondary: cyan, tertiary: gold, surface: panel, surfaceContainerHighest: panel2, outline: border2, error: red, onPrimary: onPrimary, onSurface: text),
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: text, elevation: 0, centerTitle: false, titleTextStyle: TextStyle(fontFamily: font, fontSize: 20, fontWeight: FontWeight.w700, color: text)),
      cardTheme: CardThemeData(color: panel, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: border))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: green)), labelStyle: const TextStyle(color: muted), hintStyle: const TextStyle(color: faint)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: onPrimary, textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .5), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: text, side: const BorderSide(color: border2), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      chipTheme: const ChipThemeData(backgroundColor: panel2, side: BorderSide(color: border2), labelStyle: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)),
      dividerColor: border, snackBarTheme: const SnackBarThemeData(backgroundColor: panel2, contentTextStyle: TextStyle(color: text), behavior: SnackBarBehavior.floating),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: panel, indicatorColor: green.withValues(alpha: .18), labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? green : muted))),
      tabBarTheme: const TabBarThemeData(labelColor: green, unselectedLabelColor: muted, indicatorColor: green, dividerColor: border),
    );
  }
}

// ---------- small widgets ----------
class WzCard extends StatelessWidget {
  final Widget child; final EdgeInsets padding; final Color? border; final VoidCallback? onTap;
  const WzCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.border, this.onTap});
  @override Widget build(BuildContext c) {
    final card = Container(decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: border ?? Wz.border)), padding: padding, child: child);
    return onTap == null ? card : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: card);
  }
}
class Eyebrow extends StatelessWidget { final String text; final Color color; const Eyebrow(this.text, {super.key, this.color = Wz.green});
  @override Widget build(BuildContext c) => Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.6)); }
class Big extends StatelessWidget { final String text; final double size; final Color? color; const Big(this.text, {super.key, this.size = 34, this.color});
  @override Widget build(BuildContext c) => Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, height: 1, letterSpacing: -.5, color: color)); }
class Muted extends StatelessWidget { final String text; final double size; const Muted(this.text, {super.key, this.size = 12.5});
  @override Widget build(BuildContext c) => Text(text, style: TextStyle(color: Wz.muted, fontSize: size)); }

class StatusPill extends StatelessWidget {
  final String text; const StatusPill(this.text, {super.key});
  @override Widget build(BuildContext c) {
    final t = text.toUpperCase(); Color bg; Color fg = Colors.white;
    switch (t) { case 'SAFE': bg = Wz.green; fg = const Color(0xFF02110C); break; case 'AT RISK': bg = Wz.red; break; case 'OUT': bg = Wz.border2; fg = Wz.muted; break; case 'LEADING': bg = Wz.gold; fg = const Color(0xFF1A1205); break; case 'CHASING': bg = Wz.purple.withValues(alpha: .35); fg = Wz.purple2; break; case 'IN BATTLE': bg = Wz.red.withValues(alpha: .25); fg = const Color(0xFFFF8EA0); break; case 'LIVE': case 'ON PLAY': bg = Wz.red; break; case 'FINISHED': bg = Wz.border2; fg = Wz.muted; break; case 'UPCOMING': bg = Wz.panel2; fg = Wz.muted; break; default: bg = Wz.panel2; fg = Wz.muted; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Text(t, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .8)));
  }
}
class HexAvatar extends StatelessWidget {
  final String text; final String? url; final double size; final Color color;
  const HexAvatar(this.text, {super.key, this.url, this.size = 40, this.color = Wz.green});
  @override Widget build(BuildContext c) => ClipPath(clipper: _Hex(), child: Container(width: size, height: size, color: color, alignment: Alignment.center,
      child: Config.abs(url) != null ? Image.network(Config.abs(url)!, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _t()) : _t()));
  // Dark ink on light fills (the default green), white on dark fills such as league badge colours.
  Widget _t() => Text(text, style: TextStyle(color: color.computeLuminance() > .35 ? const Color(0xFF02110C) : Colors.white, fontWeight: FontWeight.w900, fontSize: size * .34));
}
/// League crest: the uploaded logo if any, else the backend's `badge_color` with the name's first two letters.
class LeagueCrest extends StatelessWidget {
  final String name; final String? badgeColor, logo; final double size;
  const LeagueCrest(this.name, {super.key, this.badgeColor, this.logo, this.size = 40});
  @override Widget build(BuildContext c) {
    final n = name.trim();
    return HexAvatar(n.isEmpty ? '?' : n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase(), url: logo, size: size, color: (badgeColor ?? '').isEmpty ? Wz.green : Wz.hex(badgeColor!));
  }
}
class _Hex extends CustomClipper<Path> {
  @override Path getClip(Size s) => Path()..moveTo(s.width * .25, 0)..lineTo(s.width * .75, 0)..lineTo(s.width, s.height * .5)..lineTo(s.width * .75, s.height)..lineTo(s.width * .25, s.height)..lineTo(0, s.height * .5)..close();
  @override bool shouldReclip(covariant CustomClipper<Path> o) => false;
}
class StatTile extends StatelessWidget { final String label, value; final Color? color; const StatTile(this.label, this.value, {super.key, this.color});
  @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .04), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)), Muted(label.toUpperCase(), size: 10)])); }

TextStyle anton(double size, {Color? color, double spacing = 1.0, FontWeight w = FontWeight.w400}) => TextStyle(fontFamily: 'Anton', fontSize: size, color: color, letterSpacing: spacing, height: .98, fontWeight: w);
/// Handwritten flourish (Mr Dafoe, bundled) — hero accents only, never UI text.
TextStyle script(double size, {Color color = Colors.white}) => TextStyle(fontFamily: 'MrDafoe', fontSize: size, color: color, height: 1.1, shadows: [Shadow(color: Wz.green.withValues(alpha: .35), blurRadius: 12)]);
class Wz2 { static const bg = Wz.bg; }
void toast(BuildContext c, String msg, {bool error = false}) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? const Color(0xFF3A0B16) : Wz.panel2));

/// Async helper: loading / error / data with retry.
class Async<T> extends StatefulWidget {
  final Future<T> Function() load; final Widget Function(BuildContext, T, Future<void> Function() reload) builder; final Duration? poll;
  /// Optional custom first-load error view; return null to fall back to the default retry panel.
  final Widget? Function(BuildContext, Object error)? onError;
  const Async({super.key, required this.load, required this.builder, this.poll, this.onError});
  @override State<Async<T>> createState() => _AsyncState<T>();
}
class _AsyncState<T> extends State<Async<T>> {
  T? data; Object? error; bool loading = true;
  @override void initState() { super.initState(); _go(); if (widget.poll != null) _loop(); }
  bool _alive = true; @override void dispose() { _alive = false; super.dispose(); }
  Future<void> _loop() async { while (_alive) { await Future.delayed(widget.poll!); if (!_alive) return; await _go(quiet: true); } }
  Future<void> _go({bool quiet = false}) async {
    if (!quiet) setState(() { loading = true; error = null; });
    try { final d = await widget.load(); if (mounted) setState(() { data = d; loading = false; error = null; }); } catch (e) { if (mounted) setState(() { error = e; loading = false; }); }
  }
  @override Widget build(BuildContext c) {
    if (loading && data == null) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Wz.green)));
    if (error != null && data == null) { final custom = widget.onError?.call(c, error!); if (custom != null) return custom; }
    if (error != null && data == null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.wifi_off, color: Wz.muted, size: 36), const SizedBox(height: 10), Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Wz.muted)), const SizedBox(height: 12), OutlinedButton(onPressed: _go, child: const Text('Retry'))])));
    return RefreshIndicator(color: Wz.green, onRefresh: () => _go(quiet: true), child: widget.builder(c, data as T, () => _go(quiet: true)));
  }
}
