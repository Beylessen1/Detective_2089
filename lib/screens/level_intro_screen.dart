import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/level.dart';
import '../providers/providers.dart';
import 'intro_video_screen.dart';   // ← NEW import

// LevelIntroScreen sits BEFORE each ChatScreen.
// Flow: HomeScreen → LevelIntroScreen → IntroVideoScreen → ChatScreen
class LevelIntroScreen extends ConsumerStatefulWidget {
  final Level level;
  const LevelIntroScreen({super.key, required this.level});

  @override
  ConsumerState<LevelIntroScreen> createState() => _LevelIntroScreenState();
}

class _LevelIntroScreenState extends ConsumerState<LevelIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startMission() {
    // Reset attempts for this level
    ref.read(attemptsRemainingProvider.notifier).state =
        widget.level.maxAttempts;

    // ── CHANGED: go to IntroVideoScreen first ────────────────────────────
    // IntroVideoScreen will navigate to ChatScreen when the video ends.
    // If the level has no introVideo, IntroVideoScreen falls back immediately.
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            IntroVideoScreen(level: widget.level),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final accentColor = level.npc.accentColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image (dimmed) ────────────────────────────────────
          _BackgroundImage(assetPath: level.backgroundImage),

          // ── Dark overlay ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.82),
                  Colors.black.withOpacity(0.95),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: accentColor.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'MISSION ${level.id} OF 3',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Level title
                    Text(
                      level.introTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Accent line
                    Container(
                      width: 48,
                      height: 2,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Story images
                    _StoryImageRow(level: level),

                    const SizedBox(height: 28),

                    // Story text
                    Text(
                      level.introStory,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Objective box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: accentColor.withOpacity(0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OBJECTIVE',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            level.introObjective,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Attempts info
                    Row(
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            size: 14,
                            color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 6),
                        Text(
                          '${level.maxAttempts} messages before the connection drops.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── BEGIN MISSION button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startMission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'BEGIN MISSION',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Back button
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to mission select',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background image ─────────────────────────────────────────────────────────
class _BackgroundImage extends StatelessWidget {
  final String assetPath;
  const _BackgroundImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A1A), Color(0xFF1A0A0A)],
          ),
        ),
      ),
    );
  }
}

// ── Story image row ───────────────────────────────────────────────────────────
class _StoryImageRow extends StatelessWidget {
  final Level level;
  const _StoryImageRow({required this.level});

  String _sceneImagePath() =>
      level.backgroundImage.replaceAll('_bg.png', '_scene.png');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SceneImage(path: level.backgroundImage)),
        const SizedBox(width: 8),
        Expanded(child: _SceneImage(path: _sceneImagePath())),
      ],
    );
  }
}

class _SceneImage extends StatelessWidget {
  final String path;
  const _SceneImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.white.withOpacity(0.04),
            child: Center(
              child: Icon(Icons.image_outlined,
                  color: Colors.white.withOpacity(0.15), size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
