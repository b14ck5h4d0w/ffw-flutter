import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import 'fpl_client.dart';

/// Shows FPL's REAL login page. We never read the form — we only wait for FPL's session cookie (pl_profile / sessionid)
/// to appear, store it on the device and pop with the entry id.
class FplLoginPage extends StatefulWidget { const FplLoginPage({super.key}); @override State<FplLoginPage> createState() => _S(); }
class _S extends State<FplLoginPage> {
  bool done = false;
  Future<void> _check() async {
    if (done) return;
    final cm = CookieManager.instance();
    final cs = [...await cm.getCookies(url: WebUri('https://fantasy.premierleague.com')), ...await cm.getCookies(url: WebUri('https://premierleague.com'))];
    final has = cs.any((c) => c.name == 'pl_profile' || c.name == 'sessionid');
    if (!has) return;
    done = true;
    final cookie = {for (final c in cs) c.name: c.value}.entries.map((e) => '${e.key}=${e.value}').join('; ');
    final entry = await MobileFplClient().storeCookie(cookie);
    if (mounted) Navigator.of(context).pop(entry ?? -1);
  }
  @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('Sign in to Fantasy Premier League'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(c).pop(null))),
      body: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(10), color: Wz.panel2, child: const Text('This page is provided by the Premier League. Your login stays on this device and is never sent to FPL Warzone.', style: TextStyle(color: Wz.muted, fontSize: 12))),
        Expanded(child: InAppWebView(initialUrlRequest: URLRequest(url: WebUri(Config.fplLogin)), initialSettings: InAppWebViewSettings(userAgent: MobileFplClient.ua, javaScriptEnabled: true, domStorageEnabled: true, thirdPartyCookiesEnabled: true, clearCache: false),
            onWebViewCreated: (ctrl) async { await CookieManager.instance().deleteAllCookies(); }, onLoadStop: (ctrl, url) => _check(), onUpdateVisitedHistory: (ctrl, url, _) => _check())),
      ]));
}
