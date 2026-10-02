import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/theme.dart';

/// Notifications inbox (/notifications).
/// GET /api/app/notifications → {items[{id, kind, title, body, ago, url, read}], prefs{}}; POST notifications/read {ids?}.
/// Preferences live on their own screen (A10, /settings/notifications).
class NotificationsPage extends StatefulWidget { const NotificationsPage({super.key}); @override State<NotificationsPage> createState() => _NotifState(); }

class _NotifState extends State<NotificationsPage> {
  bool unreadOnly = false;
  static const _kind = {
    'deadline': (Icons.alarm_rounded, Wz.gold), 'transfers': (Icons.swap_horiz_rounded, Wz.green), 'live': (Icons.sensors_rounded, Wz.red), 'results': (Icons.emoji_events_rounded, Wz.gold),
    'survivor': (Icons.dangerous_outlined, Wz.purple2), 'civilwar': (Icons.close_rounded, Wz.red), 'clan': (Icons.groups_rounded, Wz.cyan), 'chat': (Icons.alternate_email_rounded, Wz.cyan),
    'announce': (Icons.campaign_rounded, Wz.green), 'system': (Icons.info_outline_rounded, Wz.muted),
  };
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: Repo.I.notifications, builder: (c, j, reload) {
    final all = jList(j['items']); final unread = all.where((n) => !jBool(n['read'])).length; final items = unreadOnly ? all.where((n) => !jBool(n['read'])).toList() : all;
    Future<void> open(Map<String, dynamic> n) async {
      try { if (!jBool(n['read'])) await Repo.I.markRead([jInt(n['id'])]); } catch (_) {}
      var u = jStr(n['url']).replaceFirst('/app#', ''); if (u.startsWith('/app/')) u = u.substring(4);
      if (u.startsWith('/') && c.mounted) { c.go(u); } else { await reload(); }
    }
    return ListView(padding: Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28), children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NOTIFICATIONS', style: anton(Bp.compact(c) ? 30 : 40, color: Colors.white, spacing: 1)), Text(unread == 0 ? 'You are all caught up.' : '$unread unread', style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600))])),
        IconButton(onPressed: () => c.go('/settings/notifications'), tooltip: 'Notification settings', icon: const Icon(Icons.tune_rounded, color: Colors.white)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        for (final o in [(false, 'All', all.length), (true, 'Unread', unread)]) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(selected: unreadOnly == o.$1, onSelected: (_) => setState(() => unreadOnly = o.$1), showCheckmark: false, label: Text('${o.$2}  ${o.$3}'),
            labelStyle: TextStyle(color: unreadOnly == o.$1 ? Wz.onPrimary : Colors.white, fontWeight: FontWeight.w600), selectedColor: Wz.green, backgroundColor: Wz.panel, side: const BorderSide(color: Wz.border2))),
        const Spacer(),
        if (unread > 0) TextButton.icon(onPressed: () async { try { await Repo.I.markRead(); await reload(); } catch (e) { if (c.mounted) toast(c, e.toString(), error: true); } }, style: TextButton.styleFrom(foregroundColor: Wz.green), icon: const Icon(Icons.done_all_rounded, size: 18), label: const Text('Mark all read')),
      ]),
      const SizedBox(height: 12),
      if (items.isEmpty) Container(padding: const EdgeInsets.all(34), decoration: BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Wz.border2)), child: Column(children: [const Icon(Icons.notifications_off_outlined, color: Wz.faint, size: 40), const SizedBox(height: 10), Text(unreadOnly ? 'No unread notifications.' : 'Nothing here yet.', style: const TextStyle(color: Wz.muted))])),
      for (final n in items) () { final k = _kind[jStr(n['kind'])] ?? (Icons.notifications_none_rounded, Wz.green); final read = jBool(n['read']);
        return InkWell(onTap: () => open(n), borderRadius: BorderRadius.circular(12), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: read ? Wz.panel : Wz.green.withValues(alpha: .07), borderRadius: BorderRadius.circular(12), border: Border.all(color: read ? Wz.border2 : Wz.green.withValues(alpha: .45))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: k.$2.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)), child: Icon(k.$1, color: k.$2, size: 22)), const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(jStr(n['title']), style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: read ? FontWeight.w500 : FontWeight.w700)),
              if (jStr(n['body']).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(jStr(n['body']), style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 13, height: 1.35))),
              if (jStr(n['ago']).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(jStr(n['ago']), style: const TextStyle(color: Wz.muted, fontSize: 11.5))),
            ])),
            if (!read) Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 5, left: 8), decoration: const BoxDecoration(shape: BoxShape.circle, color: Wz.green)),
          ]))); }(),
    ]);
  })));
}
