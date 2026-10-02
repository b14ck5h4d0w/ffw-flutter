import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/assets.dart';
import '../../core/json.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../auth/auth_chrome.dart';
import '../fpl/fpl_stage.dart';

/// A10 — Notification Preferences (/settings/notifications).
/// The API exposes preferences as one flat map of key → on/off (GET notifications → prefs,
/// POST notifications/prefs). Whatever keys the server sends are shown; known keys get a label,
/// icon and section, unknown ones fall into "General" with a readable name. Changes are kept as a
/// draft and sent together with "Save Preferences". There are no per-channel (push/email/SMS)
/// settings in the API, so the mockup's channel tabs are not shown.
class NotificationPrefsPage extends StatefulWidget { const NotificationPrefsPage({super.key}); @override State<NotificationPrefsPage> createState() => _PrefsState(); }

enum _Sec { gameplay, community, general }

class _Meta { final String title, detail; final IconData icon; final Color color; final _Sec sec; const _Meta(this.title, this.detail, this.icon, this.color, this.sec); }

/// Server keys (GET /api/app/notifications → prefs): deadline, transfers, live, results, survivor,
/// civilwar, clan, chat, announce, system. `h2h` is not sent today (H2H updates ride on results/live)
/// but is labelled in case it is added.
const _known = <String, _Meta>{
  'deadline': _Meta('Deadline Reminders', 'Get reminded before the gameweek deadline.', Icons.alarm_rounded, Wz.gold, _Sec.gameplay),
  'transfers': _Meta('Transfers & Price Changes', 'Transfer confirmations and player price changes.', Icons.swap_horiz_rounded, Wz.green, _Sec.gameplay),
  'live': _Meta('Live Match Alerts', 'Live match events and points updates.', Icons.sensors_rounded, Wz.red, _Sec.gameplay),
  'results': _Meta('Gameweek Results', 'Your points and rank when a gameweek finishes.', Icons.emoji_events_rounded, Wz.gold, _Sec.gameplay),
  'survivor': _Meta('Last Survivor Status', 'When your status changes: SAFE, AT RISK or OUT.', Icons.dangerous_outlined, Colors.white, _Sec.community),
  'civilwar': _Meta('Civil War Battle Updates', 'Clan battles, results and War Points.', Icons.close_rounded, Wz.red, _Sec.community),
  'clan': _Meta('Clan Activity', 'Members joining or leaving, and role changes.', Icons.groups_rounded, Wz.cyan, _Sec.community),
  'chat': _Meta('Chat Mentions', 'When you are mentioned in league or clan chat.', Icons.alternate_email_rounded, Wz.cyan, _Sec.community),
  'h2h': _Meta('Head-to-Head Matchups', 'Your fixtures and results.', Icons.sports_kabaddi_rounded, Wz.purple2, _Sec.community),
  'announce': _Meta('Announcements', 'Announcements from league owners and clan captains.', Icons.campaign_rounded, Wz.green, _Sec.general),
  'system': _Meta('Account & System', 'Account notices and platform updates.', Icons.workspace_premium_rounded, Wz.gold, _Sec.general),
};

/// Match server keys loosely ("civil_war", "announcements", "clan_requests" …).
_Meta _meta(String key) {
  final k = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  for (final e in _known.entries) { if (k == e.key || k.startsWith(e.key)) return e.value; }
  final words = key.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  final title = words.isEmpty ? key : words.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  return _Meta(title, 'Notifications about $words.', Icons.notifications_none_rounded, Colors.white, _Sec.general);
}

class _PrefsState extends State<NotificationPrefsPage> {
  Map<String, bool>? saved; Map<String, bool> draft = {}; String? loadErr, saveErr; bool saving = false;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { loadErr = null; saved = null; });
    try {
      final p = jMap((await Repo.I.notifications())['prefs']);
      final m = {for (final k in p.keys) k: jBool(p[k])};
      if (mounted) setState(() { saved = m; draft = Map.of(m); });
    } on ApiException catch (x) { if (mounted) setState(() => loadErr = x.message); }
    catch (_) { if (mounted) setState(() => loadErr = 'Could not load your preferences.'); }
  }

  Map<String, bool> get _changes => {for (final e in draft.entries) if (saved?[e.key] != e.value) e.key: e.value};

  Future<void> _save() async {
    final ch = _changes; if (ch.isEmpty || saving) return;
    setState(() { saving = true; saveErr = null; });
    try {
      await Repo.I.prefs(ch);
      if (!mounted) return;
      setState(() { saved = Map.of(draft); saving = false; });
      toast(context, 'Preferences saved');
    } on ApiException catch (x) { if (mounted) setState(() { saving = false; saveErr = x.message; }); }
    catch (_) { if (mounted) setState(() { saving = false; saveErr = 'Could not save. Please try again.'; }); }
  }

  void _discard() => setState(() { draft = Map.of(saved ?? {}); saveErr = null; });

  List<MapEntry<String, _Meta>> _items(_Sec s) => [for (final k in draft.keys) if (_meta(k).sec == s) MapEntry(k, _meta(k))];

  static const _secInfo = {
    _Sec.gameplay: ('Gameplay Alerts', 'Keep track of the on-pitch action and important deadlines.'),
    _Sec.community: ('Clan & Community', 'Never miss clan activity or a mode update.'),
    _Sec.general: ('General Notifications', 'Important updates from FFW.'),
  };

  @override Widget build(BuildContext c) {
    if (!Session.I.loggedIn) return FplStage(flourish: '', back: '/welcome', desktop: (_) => _gate(), mobile: (_) => _gate());
    return FplStage.wide(c) ? _desktop(c) : _mobile(c);
  }

  Widget _gate() => Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Container(width: 400, padding: const EdgeInsets.all(24), decoration: fplPanel(), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text('Log in to manage alerts', style: anton(24, color: Colors.white)), const SizedBox(height: 16),
    FilledButton(onPressed: () => context.go('/login'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)), child: const Text('Login')),
  ]))));

  // ---------- pieces ----------
  Widget _toggleRow(String key, _Meta m, {required bool compact}) => Container(margin: const EdgeInsets.only(bottom: 8), padding: EdgeInsets.fromLTRB(compact ? 12 : 14, compact ? 8 : 10, 6, compact ? 8 : 10),
    decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .55), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)),
    child: Row(children: [
      Icon(m.icon, color: m.color, size: compact ? 24 : 28), SizedBox(width: compact ? 12 : 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.title, style: TextStyle(color: Colors.white, fontSize: compact ? 13.5 : 14.5, fontWeight: FontWeight.w600)), const SizedBox(height: 2),
        Text(m.detail, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: compact ? 11.5 : 12.5, height: 1.35)),
      ])),
      Switch(value: draft[key] ?? false, onChanged: saving ? null : (v) => setState(() => draft[key] = v),
          activeThumbColor: Colors.white, activeTrackColor: Wz.green, inactiveThumbColor: Colors.white, inactiveTrackColor: Wz.border2, trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent)),
    ]));

  Widget _body(Widget Function(_Sec, List<MapEntry<String, _Meta>>) section, {required bool wide}) {
    if (loadErr != null) return Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: AuthErrorBanner(loadErr!, onRetry: _load));
    if (saved == null) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Wz.green)));
    if (draft.isEmpty) return Container(padding: const EdgeInsets.all(20), decoration: fplPanel(), child: const Text('There are no notification settings for your account yet.', style: TextStyle(color: Wz.muted)));
    final secs = [for (final s in _Sec.values) if (_items(s).isNotEmpty) s];
    return wide
        ? IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final (i, s) in secs.indexed) ...[if (i > 0) const SizedBox(width: 14), Expanded(child: section(s, _items(s)))]]))
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final s in secs) section(s, _items(s))]);
  }

  Widget _saveBar({required bool wide}) {
    final dirty = _changes.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (saveErr != null) AuthErrorBanner(saveErr!, onRetry: _save),
      Row(children: [
        Expanded(child: SizedBox(height: wide ? 50 : 48, child: FilledButton.icon(onPressed: dirty && !saving ? _save : null,
          style: FilledButton.styleFrom(disabledBackgroundColor: Wz.green.withValues(alpha: .35), disabledForegroundColor: Wz.onPrimary.withValues(alpha: .7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Wz.onPrimary)) : const Icon(Icons.save_rounded, size: 20),
          label: Text(saving ? 'Saving…' : dirty ? 'Save Preferences (${_changes.length})' : 'All changes saved', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))))),
        if (wide) ...[
          const SizedBox(width: 14),
          Expanded(child: SizedBox(height: 50, child: OutlinedButton.icon(onPressed: dirty && !saving ? _discard : null,
            style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: BorderSide(color: dirty ? Wz.green : Wz.border2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.undo_rounded, size: 20), label: const Text('Discard Changes', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600))))),
        ],
      ]),
      if (!wide && dirty && !saving) Center(child: TextButton(onPressed: _discard, style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text('Discard changes'))),
    ]);
  }

  // ---------- desktop ----------
  Widget _desktop(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: Stack(fit: StackFit.expand, children: [
    const AuthBackdrop(),
    Column(children: [
      const AuthTopNav(),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(48, 22, 48, 22), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1240), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(height: 150, clipBehavior: Clip.antiAlias, decoration: fplPanel(), child: Stack(fit: StackFit.expand, children: [
          Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .92), Wz.bg.withValues(alpha: .35)], stops: const [.35, 1]))),
          Positioned(right: 230, top: 4, bottom: -190, child: Image.asset(WzAssets.player10, fit: BoxFit.fitHeight, alignment: Alignment.topCenter)),
          Positioned(right: 24, top: 18, child: Transform.rotate(angle: -.16, child: Text('Real players.\nReal moments.\nStay connected.', textAlign: TextAlign.center, style: script(28)))),
          Padding(padding: const EdgeInsets.fromLTRB(28, 0, 0, 0), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notification Preferences', style: anton(40, color: Colors.white, spacing: .5)), const SizedBox(height: 6),
            const Text('Stay updated. Never miss a moment in the Warzone.', style: TextStyle(color: Wz.green, fontSize: 17, fontWeight: FontWeight.w600)),
          ])),
        ])),
        const SizedBox(height: 16),
        _body((s, items) => Container(padding: const EdgeInsets.fromLTRB(14, 16, 14, 8), decoration: fplPanel(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_secInfo[s]!.$1, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 4),
          Text(_secInfo[s]!.$2, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12.5)), const SizedBox(height: 12),
          for (final e in items) _toggleRow(e.key, e.value, compact: false),
        ])), wide: true),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(14), decoration: fplPanel(), child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: Wz.green, size: 26), SizedBox(width: 12),
          Expanded(child: Text('Alerts appear in your FFW notifications. Deadline reminders are recommended to keep enabled.', style: TextStyle(color: Colors.white70, fontSize: 13))),
        ])),
        const SizedBox(height: 14),
        if (saved != null && draft.isNotEmpty) _saveBar(wide: true),
      ]))))),
      const AuthFooter(),
    ]),
  ]));

  // ---------- phone ----------
  Widget _mobile(BuildContext c) => Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Column(children: [
    const AuthMobileBar(fallback: '/onboarding'),
    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Notification Preferences', style: anton(26, color: Colors.white, spacing: .4)), const SizedBox(height: 4),
      Text('Stay updated. Never miss a moment.', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 13.5)),
      const SizedBox(height: 14),
      _body((s, items) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: Text(_secInfo[s]!.$1.toUpperCase(), style: const TextStyle(color: Wz.green, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 1))),
        for (final e in items) _toggleRow(e.key, e.value, compact: true),
      ]), wide: false),
    ]))),
    if (saved != null && draft.isNotEmpty) Container(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), decoration: const BoxDecoration(color: Wz.bg, border: Border(top: BorderSide(color: Wz.border))), child: _saveBar(wide: false)),
  ])));
}
