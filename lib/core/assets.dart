/// Canonical image keys. Always reference images through these, never by file path,
/// so assets can be swapped (or later served from Admin → Media) in one place.
class WzAssets {
  /// FFW crowned-lion crest (transparent PNG).
  static const emblem = 'assets/img/ffw_emblem.png';
  /// #10 "WARZONE" player seen from behind (transparent PNG).
  static const player10 = 'assets/img/player_back10.png';
  /// Cinematic teal night stadium (16:9 JPEG) — auth/hero backgrounds.
  static const stadium = 'assets/img/stadium_wide.jpg';
}
