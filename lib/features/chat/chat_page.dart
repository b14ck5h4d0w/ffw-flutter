import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/theme.dart';

/// Clan / league chat (/chat/:kind/:slug).
/// GET /api/app/chat/<kind>/<slug>?after=<id> → {name, can_announce, messages[{id, text, kind ('announce'|…), at, user{id,name,me,avatar}}]}
/// POST same path {text, announce}. Report and block per message. Polls every 5s for new messages.
/// The API has no reactions, voice channel or external links, so those parts of the mockup are not shown.
class ChatPage extends StatefulWidget { final String kind, slug; const ChatPage(this.kind, this.slug, {super.key}); @override State<ChatPage> createState() => _ChatState(); }

class _ChatState extends State<ChatPage> {
  List<Map<String, dynamic>> msgs = []; String name = ''; bool canAnnounce = false, announce = false, onlyAnn = false, loading = true, sending = false; String? err;
  Timer? _timer; final ctrl = TextEditingController(), scroll = ScrollController();

  @override void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(after: msgs.isEmpty ? 0 : jInt(msgs.last['id']))); }
  @override void dispose() { _timer?.cancel(); ctrl.dispose(); scroll.dispose(); super.dispose(); }

  Future<void> _load({int after = 0}) async {
    try {
      final j = await Repo.I.chat(widget.kind, widget.slug, after: after); final m = jList(j['messages']);
      if (!mounted) return;
      setState(() { name = jStr(j['name']); canAnnounce = jBool(j['can_announce']); if (after == 0) { msgs = m; } else { final seen = {for (final x in msgs) x['id']}; msgs.addAll(m.where((x) => !seen.contains(x['id']))); } err = null; loading = false; });
      if (m.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) { if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent); });
    } catch (e) { if (mounted && msgs.isEmpty) setState(() { err = e.toString(); loading = false; }); }
  }

  Future<void> _send() async {
    final txt = ctrl.text.trim(); if (txt.isEmpty || sending) return;
    setState(() => sending = true);
    try { await Repo.I.send(widget.kind, widget.slug, txt, announce: announce); ctrl.clear(); announce = false; await _load(after: msgs.isEmpty ? 0 : jInt(msgs.last['id'])); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => sending = false); }
  }

  static String _time(String at) { final d = DateTime.tryParse(at)?.toLocal(); return d == null ? '' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; }
  static String _ini(String s) => s.trim().isEmpty ? '?' : s.trim().substring(0, 1).toUpperCase();

  void _menu(Map<String, dynamic> m) {
    final u = jMap(m['user']); if (jBool(u['me']) || u['id'] == null) return;
    showModalBottomSheet(context: context, backgroundColor: Wz.panel, builder: (s) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.flag_outlined, color: Wz.gold), title: const Text('Report message'), onTap: () async { Navigator.pop(s); try { await Repo.I.report(widget.kind, widget.slug, jInt(m['id']), 'inappropriate'); if (mounted) toast(context, 'Reported. Thank you.'); } catch (e) { if (mounted) toast(context, e.toString(), error: true); } }),
      ListTile(leading: const Icon(Icons.block_rounded, color: Wz.red), title: Text('Block ${u['name']}'), subtitle: const Text('You will no longer see their messages'), onTap: () async { Navigator.pop(s); try { await Repo.I.block(jInt(u['id'])); if (mounted) { toast(context, 'Blocked'); _load(); } } catch (e) { if (mounted) toast(context, e.toString(), error: true); } }),
    ])));
  }

  @override Widget build(BuildContext c) {
    final shown = onlyAnn ? msgs.where((m) => jStr(m['kind']) == 'announce').toList() : msgs;
    final pinned = msgs.where((m) => jStr(m['kind']) == 'announce').lastOrNull;
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 980), child: Column(children: [
      Container(padding: EdgeInsets.fromLTRB(Bp.compact(c) ? 6 : 16, 10, 12, 10), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))), child: Row(children: [
        IconButton(onPressed: () => c.canPop() ? c.pop() : c.go(widget.kind == 'clan' ? '/clan/${widget.slug}' : '/league/${widget.slug}'), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
        const Icon(Icons.forum_rounded, color: Wz.green), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isEmpty ? 'Chat' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          Text('${widget.kind == 'clan' ? 'Clan' : 'League'} chat', style: const TextStyle(color: Wz.muted, fontSize: 12)),
        ])),
        SegmentedButton<bool>(showSelectedIcon: false, segments: const [ButtonSegment(value: false, label: Text('All')), ButtonSegment(value: true, icon: Icon(Icons.campaign_outlined, size: 17), label: Text('Announcements'))], selected: {onlyAnn}, onSelectionChanged: (v) => setState(() => onlyAnn = v.first),
          style: ButtonStyle(visualDensity: VisualDensity.compact, backgroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Wz.green.withValues(alpha: .18) : Wz.bg), foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Wz.green : Wz.muted), side: const WidgetStatePropertyAll(BorderSide(color: Wz.border2)))),
      ])),
      if (pinned != null && !onlyAnn) Container(margin: const EdgeInsets.fromLTRB(12, 10, 12, 0), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.gold.withValues(alpha: .08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.gold.withValues(alpha: .45))), child: Row(children: [
        const Icon(Icons.push_pin_rounded, color: Wz.gold, size: 18), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('LATEST ANNOUNCEMENT', style: TextStyle(color: Wz.gold, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1)), Text(jStr(pinned['text']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5))])),
      ])),
      Expanded(child: loading ? const Center(child: CircularProgressIndicator(color: Wz.green))
        : err != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(err!, textAlign: TextAlign.center, style: const TextStyle(color: Wz.muted)), const SizedBox(height: 10), OutlinedButton(onPressed: () { setState(() { loading = true; err = null; }); _load(); }, child: const Text('Retry'))]))
        : shown.isEmpty ? Center(child: Text(onlyAnn ? 'No announcements yet.' : 'No messages yet. Say hello!', style: const TextStyle(color: Wz.muted)))
        : ListView.builder(controller: scroll, padding: const EdgeInsets.all(14), itemCount: shown.length, itemBuilder: (c, i) {
            final m = shown[i]; final u = jMap(m['user']); final me = jBool(u['me']); final ann = jStr(m['kind']) == 'announce';
            final bubble = GestureDetector(onLongPress: () => _menu(m), child: Container(constraints: const BoxConstraints(maxWidth: 460), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: ann ? Wz.gold.withValues(alpha: .1) : me ? Wz.green.withValues(alpha: .16) : Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: ann ? Wz.gold.withValues(alpha: .55) : me ? Wz.green.withValues(alpha: .4) : Wz.border2)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (ann) const Padding(padding: EdgeInsets.only(right: 5), child: Icon(Icons.campaign_rounded, color: Wz.gold, size: 15)),
                  Text(me ? 'You' : jStr(u['name'], 'System'), style: TextStyle(color: ann ? Wz.gold : me ? Wz.green : Wz.cyan, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8), Text(_time(jStr(m['at'])), style: const TextStyle(color: Wz.muted, fontSize: 10.5)),
                ]),
                const SizedBox(height: 3),
                Text(jStr(m['text']), style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
              ])));
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!me) ...[HexAvatar(_ini(jStr(u['name'], 'S')), url: jStrN(u['avatar']), size: 32, color: ann ? Wz.gold : Wz.green), const SizedBox(width: 8)],
              Flexible(child: bubble),
              if (!me && u['id'] != null) IconButton(onPressed: () => _menu(m), tooltip: 'Report or block', visualDensity: VisualDensity.compact, icon: const Icon(Icons.more_horiz_rounded, color: Wz.faint, size: 18)),
            ]));
          })),
      Container(padding: const EdgeInsets.fromLTRB(10, 8, 10, 10), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Wz.border))), child: Row(children: [
        if (canAnnounce) IconButton(onPressed: () => setState(() => announce = !announce), tooltip: announce ? 'Sending as announcement' : 'Send as announcement', icon: Icon(Icons.campaign_rounded, color: announce ? Wz.gold : Wz.muted)),
        Expanded(child: TextField(controller: ctrl, onSubmitted: (_) => _send(), maxLength: 500, style: const TextStyle(color: Wz.text), textInputAction: TextInputAction.send,
            decoration: InputDecoration(counterText: '', isDense: true, hintText: announce ? 'Announce to everyone…' : 'Type a message…', enabledBorder: announce ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Wz.gold)) : null))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: sending ? null : _send, tooltip: 'Send', style: IconButton.styleFrom(backgroundColor: Wz.green, foregroundColor: Wz.onPrimary), icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.onPrimary)) : const Icon(Icons.send_rounded)),
      ])),
    ])))));
  }
}
