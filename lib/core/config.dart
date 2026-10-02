class Config {
  static const baseUrl = String.fromEnvironment('WZ_BASE_URL', defaultValue: 'https://fplwarzone.com');
  static const appName = 'FFW';
  static const fplBase = 'https://fantasy.premierleague.com';
  static const fplLogin = 'https://users.premierleague.com/accounts/login/?redirect_uri=https://fantasy.premierleague.com/&app=plfpl-web';
  static const privacyUrl = '$baseUrl/privacy';
  /// Server media paths come back site-relative ("/static/…"); make them loadable.
  static String? abs(String? u) => u == null || u.isEmpty ? null : (u.startsWith('/') ? '$baseUrl$u' : u);
}

/// Legal documents shown in-app at /legal/<kind>. A null URL means the document isn't
/// published yet and the page shows a placeholder. Override at build time with
/// --dart-define=WZ_TERMS_URL=… / WZ_PRIVACY_URL=…; switch to a backend/admin setting
/// once one exists.
class LegalLinks {
  static const _terms = String.fromEnvironment('WZ_TERMS_URL');
  static const _privacy = String.fromEnvironment('WZ_PRIVACY_URL', defaultValue: Config.privacyUrl);
  static String? url(String kind) {
    final u = switch (kind) { 'terms' => _terms, 'privacy' => _privacy, _ => '' };
    return u.isEmpty ? null : u;
  }
}
