import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/brand.dart';
import '../../core/config.dart';
import '../../core/countries.dart';
import '../../core/json.dart';
import '../../core/layout.dart';
import '../../core/repo.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../fpl/fpl_client.dart';

/// Profile screens.
/// A61 My Profile (/me) — session user + GET /api/app/home (summary, leagues).
/// A62 Edit Profile (/me/edit) — POST /api/app/me {name, country, bio}; photo via POST /api/app/me/avatar (multipart "avatar").
/// A63 Settings / Connected FPL Account (/settings) — FPL link status, unlink, blocked users, delete account.
/// User Profile (/manager/:id) — GET /api/app/managers/<id> → {user, summary, clan, leagues[], favourites[]}.

BoxDecoration _box({Color? border}) => BoxDecoration(color: Wz.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: border ?? Wz.border2));
EdgeInsets _pad(BuildContext c) => Bp.compact(c) ? const EdgeInsets.fromLTRB(14, 12, 14, 24) : const EdgeInsets.fromLTRB(24, 20, 24, 28);
String _num(dynamic v) { final n = jIntN(v); return n == null ? '—' : '$n'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','); }
String _ini(String s) => s.trim().isEmpty ? '?' : s.trim().substring(0, 1).toUpperCase();
Widget _title(IconData i, Color col, String t, {Widget? trailing}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(i, color: col, size: 20), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))), if (trailing != null) trailing]));
Widget _kv(IconData i, String k, String v) => Container(padding: const EdgeInsets.symmetric(vertical: 9), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, size: 18, color: Colors.white70), const SizedBox(width: 12), SizedBox(width: 96, child: Text(k, style: const TextStyle(color: Wz.muted, fontSize: 13))), Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 13.5)))]));
Widget _stat(BuildContext c, IconData i, Color col, String v, String k) => Container(width: Bp.compact(c) ? (MediaQuery.of(c).size.width - 38) / 2 : 200, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: _box(),
    child: Row(children: [Icon(i, color: col, size: 26), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700))), Text(k, style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11.5))]))]));
Widget _gate(BuildContext c, String msg) => Scaffold(backgroundColor: Wz.bg, body: Center(child: Container(margin: const EdgeInsets.all(20), constraints: const BoxConstraints(maxWidth: 420), padding: const EdgeInsets.all(24), decoration: _box(), child: Column(mainAxisSize: MainAxisSize.min, children: [
  const Icon(Icons.account_circle_outlined, color: Wz.green, size: 40), const SizedBox(height: 12), Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Wz.muted)), const SizedBox(height: 16),
  Row(mainAxisSize: MainAxisSize.min, children: [FilledButton(onPressed: () => c.go('/login'), child: const Text('Login')), const SizedBox(width: 10), OutlinedButton(onPressed: () => c.go('/register'), child: const Text('Create Account'))])]))));

/// Profile hero: stadium, big avatar, name, tagline.
/// With [onAvatar] the photo is tappable and carries a camera badge ([uploading] shows a spinner instead).
Widget _hero(BuildContext c, {required String name, required String sub, String? avatar, String? bio, required String flourish, List<Widget> chips = const [], Widget? back, VoidCallback? onAvatar, bool uploading = false, String? owner}) {
  final compact = Bp.compact(c); final img = Config.abs(avatar);
  Widget photo = Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Wz.green, width: 2.5), boxShadow: [BoxShadow(color: Wz.green.withValues(alpha: .3), blurRadius: 18)]),
    child: CircleAvatar(radius: compact ? 38 : 54, backgroundColor: Wz.panel2, foregroundImage: img == null ? null : NetworkImage(img), onForegroundImageError: img == null ? null : (_, __) {}, child: Text(_ini(owner ?? name), style: anton(compact ? 30 : 42, color: Wz.green))));
  if (onAvatar != null) {
    photo = Tooltip(message: 'Change photo', child: InkWell(onTap: uploading ? null : onAvatar, customBorder: const CircleBorder(), child: Stack(children: [
      photo,
      Positioned(right: 0, bottom: 0, child: Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Wz.green, border: Border.all(color: Wz.bg, width: 2)),
        child: uploading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.onPrimary)) : const Icon(Icons.photo_camera_rounded, size: 16, color: Wz.onPrimary))),
    ])));
  }
  return Container(clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
    Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
    Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .5)], stops: const [.45, 1])))),
    if (!compact) Positioned(right: 26, top: 24, child: Transform.rotate(angle: -.14, child: Text(flourish, textAlign: TextAlign.center, style: script(30)))),
    Padding(padding: EdgeInsets.all(compact ? 16 : 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (back != null) ...[back, const SizedBox(height: 12)],
      Row(children: [
        photo,
        SizedBox(width: compact ? 14 : 22),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Flexible(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: anton(compact ? 26 : 40, color: Colors.white, spacing: .6))), const SizedBox(width: 10), FfwCrown(size: compact ? 20 : 28)]),
          Text(sub, style: const TextStyle(color: Wz.green, fontSize: 15, fontWeight: FontWeight.w600)),
          if (chips.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 6, children: chips)],
        ])),
      ]),
      if ((bio ?? '').isNotEmpty) ...[const SizedBox(height: 14), Container(constraints: const BoxConstraints(maxWidth: 620), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Text('"$bio"', style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 13.5, height: 1.4)))],
    ])),
  ]));
}
Widget _chip(IconData i, String t, Color col) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withValues(alpha: .6))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 14, color: col), const SizedBox(width: 5), Text(t, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w600))]));

Widget _leagues(BuildContext c, List<Map<String, dynamic>> leagues, {String title = 'Leagues', bool viewAll = false}) => Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
  _title(Icons.emoji_events_rounded, Wz.gold, '$title (${leagues.length})', trailing: viewAll ? InkWell(onTap: () => c.go('/leagues'), child: const Text('View All ›', style: TextStyle(color: Wz.green, fontSize: 13, fontWeight: FontWeight.w600))) : null),
  if (leagues.isEmpty) const Text('No leagues yet.', style: TextStyle(color: Wz.muted)),
  for (final l in leagues) InkWell(onTap: () => c.go('/league/${l['slug']}'), child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
    HexAvatar(_ini(jStr(l['name'])), size: 30), const SizedBox(width: 10),
    Expanded(child: Text(jStr(l['name']), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14))),
    Text(l['rank'] == null ? '—' : 'Rank ${_num(l['rank'])}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
  ]))),
]));

// ======================================================================================
// A61 — My Profile
// ======================================================================================

class MePage extends StatelessWidget {
  const MePage({super.key});
  static String? _joined(int? j) { if (j == null) return null; if (j > 1000000000) { final d = DateTime.fromMillisecondsSinceEpoch(j * 1000); return '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}'; } return j >= 2000 && j < 2100 ? '$j' : null; }

  @override Widget build(BuildContext c) => ListenableBuilder(listenable: Session.I, builder: (c, _) {
    final u = Session.I.user;
    if (u == null) return _gate(c, 'Log in to see your profile.');
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: () => Repo.I.home().catchError((_) => <String, dynamic>{}), builder: (c, j, _) {
      final sm = jMap(j['summary']); final leagues = jList(j['leagues']); final clan = leagues.map((l) => jStrN(l['clan'])).whereType<String>().firstOrNull;
      final about = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.person_outline_rounded, Wz.green, 'About Me', trailing: InkWell(onTap: () => c.go('/me/edit'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_outlined, size: 15, color: Wz.green), SizedBox(width: 4), Text('Edit', style: TextStyle(color: Wz.green, fontSize: 13, fontWeight: FontWeight.w600))]))),
        _kv(Icons.badge_outlined, 'Name', u.name), _kv(Icons.mail_outline_rounded, 'Email', u.email),
        _kv(Icons.shield_outlined, 'FPL Team', u.fpl == null ? 'Not connected' : '${u.team.isEmpty ? 'Team' : u.team} · ID ${u.fpl}'),
        if (_joined(u.joined) != null) _kv(Icons.calendar_month_outlined, 'Joined FFW', _joined(u.joined)!),
        _kv(Icons.location_on_outlined, 'Location', (u.country ?? '').isEmpty ? 'Not set' : u.country!),
        _kv(Icons.notes_rounded, 'Bio', (u.bio ?? '').isEmpty ? 'Not set' : u.bio!),
      ]));
      final quick = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.flash_on_rounded, Wz.gold, 'Quick Actions'),
        FilledButton.icon(onPressed: () => c.go('/me/edit'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)), icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Edit Profile')), const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => c.go('/settings'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.settings_outlined, size: 18), label: const Text('Account Settings')), const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => c.go('/settings/notifications'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2)), icon: const Icon(Icons.notifications_none_rounded, size: 18), label: const Text('Notification Settings')),
        if (u.admin) ...[const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => c.go('/admin'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), foregroundColor: Wz.purple2, side: BorderSide(color: Wz.purple2.withValues(alpha: .7))), icon: const Icon(Icons.admin_panel_settings_outlined, size: 18), label: const Text('Admin Panel'))],
      ]));
      final wide = MediaQuery.of(c).size.width >= 1100;
      return ListView(padding: _pad(c), children: [
        _hero(c, name: u.name, sub: u.team.isEmpty ? 'FPL Manager' : u.team, avatar: u.avatar, bio: u.bio, flourish: 'Same passion.\nBigger community.', chips: [
          _chip(u.fpl != null ? Icons.link_rounded : Icons.link_off_rounded, u.fpl != null ? 'FPL connected' : 'FPL not connected', u.fpl != null ? Wz.green : Wz.gold),
          if (u.admin) _chip(Icons.admin_panel_settings_outlined, 'Admin', Wz.purple2),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _stat(c, Icons.emoji_events_rounded, Wz.gold, _num(sm['total']), 'Total Points'),
          _stat(c, Icons.bar_chart_rounded, Wz.cyan, _num(sm['orank']), 'Overall Rank'),
          _stat(c, Icons.groups_rounded, Wz.green, '${leagues.length}', 'Leagues Joined'),
          _stat(c, Icons.shield_rounded, Wz.red, clan ?? '—', 'Clan'),
        ]),
        const SizedBox(height: 14),
        wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: about), const SizedBox(width: 16), Expanded(flex: 2, child: Column(children: [_leagues(c, leagues, title: 'My Leagues', viewAll: true), const SizedBox(height: 14), quick]))])
             : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [about, const SizedBox(height: 14), _leagues(c, leagues, title: 'My Leagues', viewAll: true), const SizedBox(height: 14), quick]),
      ]);
    })));
  });
}

// ======================================================================================
// A62 — Edit Profile
// ======================================================================================

class EditProfilePage extends StatefulWidget { const EditProfilePage({super.key}); @override State<EditProfilePage> createState() => _EditState(); }
class _EditState extends State<EditProfilePage> {
  late final name = TextEditingController(text: Session.I.user?.name ?? ''), bio = TextEditingController(text: Session.I.user?.bio ?? '');
  late String? country = (Session.I.user?.country ?? '').isEmpty ? null : Session.I.user!.country; bool busy = false, uploading = false; String? nameErr;
  @override void dispose() { name.dispose(); bio.dispose(); super.dispose(); }

  /// Picks a photo from the gallery (downscaled on device) and uploads it straight away.
  Future<void> _photo() async {
    final XFile? f;
    try { f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85); }
    catch (_) { if (mounted) toast(context, 'Could not open your photos. Check the app permission.', error: true); return; }
    if (f == null) return;
    setState(() => uploading = true);
    try { await Repo.I.avatar(await f.readAsBytes(), f.name); await Session.I.refreshMe(); if (mounted) toast(context, 'Profile photo updated'); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => uploading = false); }
  }

  Future<void> _save() async {
    if (name.text.trim().length < 2) { setState(() => nameErr = 'Enter your name'); return; }
    setState(() { busy = true; nameErr = null; });
    try { await Repo.I.updateMe({'name': name.text.trim(), 'country': country ?? '', 'bio': bio.text.trim()}); await Session.I.refreshMe(); if (mounted) { toast(context, 'Profile updated'); context.go('/me'); } }
    catch (e) { if (mounted) { toast(context, e.toString(), error: true); setState(() => busy = false); } }
  }

  Future<void> _pick() async {
    String q = '';
    final v = await showDialog<String>(context: context, builder: (d) => StatefulBuilder(builder: (d, set) { final list = q.isEmpty ? kCountries : kCountries.where((x) => x.toLowerCase().contains(q.toLowerCase())).toList();
      return Dialog(backgroundColor: Wz.panel, child: SizedBox(width: 420, height: 540, child: Column(children: [
        Padding(padding: const EdgeInsets.all(14), child: TextField(autofocus: true, onChanged: (x) => set(() => q = x.trim()), decoration: const InputDecoration(hintText: 'Search country', prefixIcon: Icon(Icons.search_rounded), isDense: true))),
        Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (_, i) => ListTile(dense: true, title: Text(list[i]), trailing: list[i] == country ? const Icon(Icons.check_rounded, color: Wz.green) : null, onTap: () => Navigator.pop(d, list[i])))),
      ]))); }));
    if (v != null) setState(() => country = v);
  }

  @override Widget build(BuildContext c) {
    final u = Session.I.user; if (u == null) return _gate(c, 'Log in to edit your profile.');
    Widget label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8, top: 4), child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)));
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: _pad(c), children: [
      _hero(c, name: 'Edit Profile', sub: 'Make it yours.', avatar: u.avatar, flourish: 'Good players\nbuild teams.', onAvatar: _photo, uploading: uploading, owner: u.name, back: InkWell(onTap: () => c.go('/me'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70), SizedBox(width: 6), Text('My Profile', style: TextStyle(color: Colors.white70, fontSize: 13))]))),
      const SizedBox(height: 16),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: Container(padding: const EdgeInsets.all(20), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        label('Profile Photo'),
        Row(children: [
          const Expanded(child: Text('JPG or PNG. Shown on standings, clans and chat.', style: TextStyle(color: Wz.muted, fontSize: 12.5))),
          OutlinedButton.icon(onPressed: uploading || busy ? null : _photo, style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)),
            icon: uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Wz.green)) : const Icon(Icons.photo_camera_outlined, size: 18), label: Text(uploading ? 'Uploading…' : 'Change Photo')),
        ]),
        const SizedBox(height: 14), label('Full Name'), TextField(controller: name, maxLength: 40, style: const TextStyle(color: Wz.text), decoration: InputDecoration(counterText: '', errorText: nameErr, prefixIcon: const Icon(Icons.person_outline_rounded, color: Wz.muted))),
        const SizedBox(height: 10), label('Email'), TextField(enabled: false, controller: TextEditingController(text: u.email), style: const TextStyle(color: Wz.muted), decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded, color: Wz.muted), helperText: 'Your email cannot be changed here.')),
        const SizedBox(height: 10), label('Country / Region'),
        InkWell(onTap: _pick, borderRadius: BorderRadius.circular(12), child: InputDecorator(decoration: const InputDecoration(prefixIcon: Icon(Icons.language_rounded, color: Wz.muted), suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Wz.muted)), child: Text(country ?? 'Select your country', style: TextStyle(color: country == null ? Wz.faint : Wz.text, fontSize: 15)))),
        const SizedBox(height: 10), label('Bio'), TextField(controller: bio, maxLines: 4, maxLength: 200, style: const TextStyle(color: Wz.text), decoration: const InputDecoration(hintText: 'Football is more than a game…')),
        const SizedBox(height: 14),
        Row(children: [
          OutlinedButton(onPressed: busy ? null : () => c.go('/me'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Wz.border2), minimumSize: const Size(110, 46)), child: const Text('Cancel')), const Spacer(),
          FilledButton.icon(onPressed: busy ? null : _save, style: FilledButton.styleFrom(minimumSize: const Size(170, 46)), icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Wz.onPrimary)) : const Icon(Icons.save_rounded, size: 18), label: Text(busy ? 'Saving…' : 'Save Changes')),
        ]),
      ])))),
    ])));
  }
}

// ======================================================================================
// A63 — Settings / Connected FPL Account
// ======================================================================================

class SettingsPage extends StatefulWidget { const SettingsPage({super.key}); @override State<SettingsPage> createState() => _SettingsState(); }
class _SettingsState extends State<SettingsPage> {
  bool busy = false;

  Future<void> _unlink() async {
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Disconnect FPL team?'), content: const Text('Your points, squad and league standings stop updating until you connect again. Your FPL account itself is not affected.'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, true), style: FilledButton.styleFrom(backgroundColor: Wz.red, foregroundColor: Colors.white), child: const Text('Disconnect'))]));
    if (ok != true) return;
    setState(() => busy = true);
    try { await FplClient.I.logout(); await Repo.I.fplUnlink(); await Session.I.refreshMe(); if (mounted) toast(context, 'FPL team disconnected'); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _delete() async {
    final t = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Delete account'), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('This permanently removes your FFW account, league memberships and history. Your team on fantasy.premierleague.com is not affected.', style: TextStyle(color: Wz.muted, fontSize: 13.5)), const SizedBox(height: 12), TextField(controller: t, autofocus: true, decoration: const InputDecoration(labelText: 'Type DELETE to confirm'))]), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, t.text.trim() == 'DELETE'), style: FilledButton.styleFrom(backgroundColor: Wz.red, foregroundColor: Colors.white), child: const Text('Delete'))]));
    if (ok != true) return;
    try { await Repo.I.deleteAccount(); await FplClient.I.logout(); await Session.I.logout(); if (mounted) context.go('/welcome'); }
    catch (e) { if (mounted) toast(context, e.toString(), error: true); }
  }

  Widget _row(IconData i, String t, String s, {String? action, VoidCallback? on, Color color = Wz.green}) => Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Wz.border))), child: Row(children: [
    Icon(i, size: 20, color: Colors.white70), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), if (s.isNotEmpty) Text(s, style: const TextStyle(color: Wz.muted, fontSize: 12.5))])),
    if (action != null) TextButton(onPressed: on, style: TextButton.styleFrom(foregroundColor: color), child: Text(action, style: const TextStyle(fontWeight: FontWeight.w600))),
  ]));

  @override Widget build(BuildContext c) => ListenableBuilder(listenable: Session.I, builder: (c, _) {
    final u = Session.I.user; if (u == null) return _gate(c, 'Log in to manage your settings.');
    final linked = u.fpl != null; final compact = Bp.compact(c);
    final fpl = Container(padding: const EdgeInsets.all(18), decoration: _box(border: (linked ? Wz.green : Wz.gold).withValues(alpha: .45)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [const Expanded(child: Text('Connected FPL Account', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))), Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: linked ? Wz.green : Wz.gold)), const SizedBox(width: 8), Text(linked ? 'Connected' : 'Not connected', style: TextStyle(color: linked ? Wz.green : Wz.gold, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 4),
      Text(linked ? 'Your Fantasy Premier League team is connected to FFW.' : 'Connect your Fantasy Premier League team to see points, squad and standings.', style: const TextStyle(color: Wz.muted, fontSize: 13)),
      const SizedBox(height: 14),
      if (linked) Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(10), border: Border.all(color: Wz.border2)), child: Wrap(spacing: 36, runSpacing: 12, children: [
        for (final r in [('FPL Manager', u.name), ('Team Name', u.team.isEmpty ? '—' : u.team), ('Team ID', '${u.fpl}')]) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.$1, style: const TextStyle(color: Wz.muted, fontSize: 12)), Text(r.$2, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600))]),
      ])),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        OutlinedButton.icon(onPressed: busy ? null : () => c.go('/connect-fpl'), style: OutlinedButton.styleFrom(foregroundColor: Wz.green, side: const BorderSide(color: Wz.green)), icon: const Icon(Icons.link_rounded, size: 18), label: Text(linked ? 'Relink Account' : 'Connect with FPL')),
        if (linked) OutlinedButton.icon(onPressed: busy ? null : _unlink, style: OutlinedButton.styleFrom(foregroundColor: Wz.red, side: const BorderSide(color: Wz.red)), icon: const Icon(Icons.link_off_rounded, size: 18), label: const Text('Disconnect')),
      ]),
    ]));
    final account = Container(padding: const EdgeInsets.all(18), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Account & Security', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 6),
      _row(Icons.person_outline_rounded, 'Profile', 'Name, country and bio', action: 'Edit', on: () => c.go('/me/edit')),
      _row(Icons.mail_outline_rounded, 'Email Address', u.email),
      _row(Icons.lock_outline_rounded, 'Password', 'Send a reset link to your email', action: 'Reset', on: () => c.go('/forgot?email=${Uri.encodeQueryComponent(u.email)}')),
      _row(Icons.logout_rounded, 'Log Out', 'Sign out on this device', action: 'Log Out', on: () async { await Session.I.logout(); if (c.mounted) c.go('/welcome'); }),
    ]));
    final privacy = Container(padding: const EdgeInsets.all(18), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Privacy & Data', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 6),
      _row(Icons.notifications_none_rounded, 'Notifications', 'Choose what you are notified about', action: 'Manage', on: () => c.go('/settings/notifications')),
      _row(Icons.block_rounded, 'Blocked Users', 'People whose chat messages you hide', action: 'View', on: _blocked),
      _row(Icons.privacy_tip_outlined, 'Privacy Policy', 'How we use your data', action: 'View', on: () => c.push('/legal/privacy')),
      _row(Icons.gavel_rounded, 'Terms of Service', '', action: 'View', on: () => c.push('/legal/terms')),
      _row(Icons.delete_forever_outlined, 'Delete My Account', 'Permanently remove your FFW account', action: 'Delete', on: _delete, color: Wz.red),
    ]));
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: ListView(padding: _pad(c), children: [
      Container(clipBehavior: Clip.antiAlias, decoration: _box(border: Wz.green.withValues(alpha: .35)), child: Stack(children: [
        Positioned.fill(child: Image.asset(WzAssets.stadium, fit: BoxFit.cover, alignment: Alignment.topCenter)),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Wz.bg.withValues(alpha: .94), Wz.bg.withValues(alpha: .5)], stops: const [.4, 1])))),
        if (!compact) Positioned(right: 26, top: 22, child: Transform.rotate(angle: -.14, child: Text('Same game.\nBigger minds.', textAlign: TextAlign.center, style: script(30)))),
        Padding(padding: EdgeInsets.all(compact ? 18 : 26), child: Row(children: [
          Icon(Icons.settings_outlined, color: Wz.green, size: compact ? 44 : 60), const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SETTINGS', style: anton(compact ? 30 : 42, color: Colors.white, spacing: 1)), Text('Manage your account, connected FPL and preferences.', style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 14))])),
        ])),
      ])),
      const SizedBox(height: 14),
      fpl, const SizedBox(height: 14),
      MediaQuery.of(c).size.width >= 1100 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: account), const SizedBox(width: 16), Expanded(child: privacy)])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [account, const SizedBox(height: 14), privacy]),
      const SizedBox(height: 18),
      const Center(child: Text('FFW · Fantasy Football Warzone · unofficial fan app, not affiliated with the Premier League', textAlign: TextAlign.center, style: TextStyle(color: Wz.faint, fontSize: 11.5))),
    ])));
  });

  Future<void> _blocked() async {
    List<Map<String, dynamic>> bs;
    try { bs = await Repo.I.blocks(); } catch (e) { if (mounted) toast(context, e.toString(), error: true); return; }
    if (!mounted) return;
    showDialog(context: context, builder: (d) => StatefulBuilder(builder: (d, set) => AlertDialog(backgroundColor: Wz.panel, title: const Text('Blocked Users'), content: SizedBox(width: 380, child: bs.isEmpty ? const Text('You have not blocked anyone.', style: TextStyle(color: Wz.muted))
      : Column(mainAxisSize: MainAxisSize.min, children: [for (final b in bs) ListTile(contentPadding: EdgeInsets.zero, title: Text(jStr(b['name'])), trailing: TextButton(onPressed: () async { try { await Repo.I.unblock(jInt(b['user_id'])); set(() => bs = bs.where((x) => x != b).toList()); } catch (e) { if (d.mounted) toast(d, e.toString(), error: true); } }, child: const Text('Unblock')))])), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))])));
  }
}

// ======================================================================================
// User Profile
// ======================================================================================

class ManagerPage extends StatelessWidget {
  final int id; const ManagerPage(this.id, {super.key});
  @override Widget build(BuildContext c) {
    if (!Session.I.loggedIn) return _gate(c, 'Log in to see manager profiles.');
    return Scaffold(backgroundColor: Wz.bg, body: SafeArea(child: Async(load: () => Repo.I.manager(id), builder: (c, j, _) {
      final u = jMap(j['user']); final s = jMap(j['summary']); final cl = j['clan'] is Map ? jMap(j['clan']) : null; final favs = jList(j['favourites']); final leagues = jList(j['leagues']);
      final me = Session.I.user?.id == id;
      final keys = Container(padding: const EdgeInsets.all(16), decoration: _box(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(Icons.star_outline_rounded, Wz.gold, 'Key Players'),
        if (favs.isEmpty) const Text('No squad data yet.', style: TextStyle(color: Wz.muted)),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final f in favs) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Wz.bg.withValues(alpha: .6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Wz.border2)), child: Text('${f['name']} · ${f['club']}', style: const TextStyle(color: Colors.white, fontSize: 13)))]),
      ]));
      return ListView(padding: _pad(c), children: [
        _hero(c, name: jStr(u['name'], 'Manager'), sub: jStr(u['team'], 'FPL Manager'), avatar: jStrN(u['avatar']), bio: jStrN(u['bio']), flourish: 'Good players.\nGreat people.',
          back: InkWell(onTap: () => c.canPop() ? c.pop() : c.go('/rankings'), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70), SizedBox(width: 6), Text('Back', style: TextStyle(color: Colors.white70, fontSize: 13))])),
          chips: [if (jStr(u['country']).isNotEmpty) _chip(Icons.location_on_outlined, jStr(u['country']), Colors.white70), if (cl != null) _chip(Icons.shield_rounded, jStr(cl['name']), Wz.red), if (me) _chip(Icons.person_rounded, 'This is you', Wz.green)]),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _stat(c, Icons.emoji_events_rounded, Wz.gold, _num(s['total']), 'Total Points'), _stat(c, Icons.bolt_rounded, Wz.green, _num(s['gw_pts']), 'Gameweek Points'),
          _stat(c, Icons.bar_chart_rounded, Wz.cyan, _num(s['orank']), 'Overall Rank'), _stat(c, Icons.groups_rounded, Colors.white, '${leagues.length}', 'Leagues'),
        ]),
        const SizedBox(height: 14),
        MediaQuery.of(c).size.width >= 1100 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _leagues(c, leagues)), const SizedBox(width: 16), Expanded(child: keys)])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_leagues(c, leagues), const SizedBox(height: 14), keys]),
        if (cl != null && jStrN(cl['slug']) != null) Padding(padding: const EdgeInsets.only(top: 14), child: Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: () => c.go('/clan/${cl['slug']}'), style: OutlinedButton.styleFrom(foregroundColor: Wz.red, side: BorderSide(color: Wz.red.withValues(alpha: .7))), icon: const Icon(Icons.shield_outlined, size: 18), label: Text('View ${cl['name']}')))),
      ]);
    })));
  }
}
