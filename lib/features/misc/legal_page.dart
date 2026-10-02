import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config.dart';
import '../../core/theme.dart';

/// /legal/terms · /legal/privacy — in-app entry point for legal documents.
/// Opens the published document when [LegalLinks] has a URL, otherwise shows a placeholder.
class LegalPage extends StatelessWidget {
  final String kind; const LegalPage(this.kind, {super.key});
  String get _title => kind == 'privacy' ? 'Privacy Policy' : 'Terms of Service';
  @override Widget build(BuildContext c) {
    final url = LegalLinks.url(kind);
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(padding: const EdgeInsets.all(20), children: [
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => c.canPop() ? c.pop() : c.go('/home'), style: TextButton.styleFrom(foregroundColor: Colors.white70), icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('Back'))),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: Wz.border2)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(kind == 'privacy' ? Icons.privacy_tip_outlined : Icons.gavel_rounded, color: Wz.green, size: 30),
        const SizedBox(height: 12),
        Text(_title.toUpperCase(), style: anton(26, color: Wz.text)),
        const SizedBox(height: 8),
        Text(url == null ? 'The FFW $_title is being finalised and will be published here soon.' : 'Read the full FFW $_title.', style: const TextStyle(color: Wz.muted, fontSize: 14, height: 1.5)),
        if (url != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: () => launchUrl(Uri.parse(url)), icon: const Icon(Icons.open_in_new, size: 18), label: Text('Open $_title')),
        ],
      ])),
    ])))));
  }
}
