/// Centralized asset paths for the brand mascot's illustrated states.
///
/// Keeping every path here (rather than sprinkled through screens) means a
/// future re-export of the mascot art only requires editing this file.
class MascotAssets {
  const MascotAssets._();

  /// Key art: splash screen, major onboarding moments.
  static const String hero = 'assets/Mascot/mascot_hero.png';

  /// App icon source image (consumed by flutter_launcher_icons at build
  /// time, not loaded at runtime).
  static const String appIcon = 'assets/Mascot/mascot_icon.png';

  /// Quiz: correct answer, duel victory.
  static const String win = 'assets/Mascot/mascot_win.png';

  /// Quiz: loading a question, AI "thinking" state.
  static const String think = 'assets/Mascot/mascot_think.png';

  /// Quiz: incorrect answer, duel defeat (comedic).
  static const String lose = 'assets/Mascot/mascot_lose.png';
}

/// The mascot's mood, driving which [MascotAssets] illustration is shown.
enum MascotMood {
  idle,
  thinking,
  victory,
  defeat,
}
