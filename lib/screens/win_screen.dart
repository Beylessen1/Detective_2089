import 'package:flutter/material.dart';
import '../models/level.dart';
import 'home_screen.dart';

class WinScreen extends StatefulWidget {
  final Level level;
  const WinScreen({super.key, required this.level});

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect to home after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    return Scaffold(
      backgroundColor: level.npc.themeColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: level.npc.accentColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'MISSION COMPLETE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You extracted the secret from ${level.npc.name}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: level.npc.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: level.npc.accentColor.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'EXTRACTED SECRET',
                        style: TextStyle(
                          color: level.npc.accentColor,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        level.npc.secret,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Returning to missions...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                // Tap to skip the countdown
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: level.npc.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'NEXT MISSION',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1),
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
