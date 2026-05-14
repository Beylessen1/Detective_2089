import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/level.dart';
import '../providers/providers.dart';
import 'chat_screen.dart';
import 'home_screen.dart';

class GameOverScreen extends ConsumerWidget {
  final Level level;
  const GameOverScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cancel_outlined,
                  size: 80,
                  color: Color(0xFFE94560),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MISSION FAILED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${level.npc.name} didn\'t reveal their secret. '
                  'Your cover may be blown.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    ref.read(attemptsRemainingProvider.notifier).state =
                        level.maxAttempts;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(level: level),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'TRY AGAIN',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    );
                  },
                  child: Text(
                    'Back to mission select',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
