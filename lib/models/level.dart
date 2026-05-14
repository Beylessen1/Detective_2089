import 'npc.dart';

class Level {
  final int id;
  final Npc npc;
  final String missionBrief;
  final int maxAttempts;
  final List<String> hints;

  // ── Intro & presentation fields ──────────────────────────────────────────
  final String introTitle;       // "UNIT RX-7 — FORGOTTEN SCOUT"
  final String introStory;       // Multi-sentence narrative shown on intro screen
  final String introObjective;   // One-liner: "Extract the coordinates from RX-7"
  final String backgroundImage;  // asset path: "assets/images/level1_bg.png"
  final bool isFinalLevel;       // true only for level 3
  final String? finalPassword;   // only set on final level — player must type this

  // ── NEW: cinematic intro video ───────────────────────────────────────────
  /// Asset path to the level's intro video, e.g. 'assets/videos/level1_intro.mp4'
  /// If empty or the file is missing the IntroVideoScreen falls back to ChatScreen.
  final String introVideo;

  const Level({
    required this.id,
    required this.npc,
    required this.missionBrief,
    required this.maxAttempts,
    required this.hints,
    // presentation
    required this.introTitle,
    required this.introStory,
    required this.introObjective,
    required this.backgroundImage,
    this.isFinalLevel = false,
    this.finalPassword,
    // video — defaults to empty string so existing Level instances compile
    this.introVideo = '',
  });
}
