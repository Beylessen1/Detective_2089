import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/level.dart';
import 'level_intro_screen.dart'; // ← CHANGED: was chat_screen.dart

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(allLevelsProvider);
    final progressAsync = ref.watch(progressProvider);
    final authService = ref.read(authServiceProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(  // ← CHANGED: app name
          'DETECTIVE 2089',
          style: TextStyle(
            color: Color(0xFFE94560),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  user.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white38),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: progressAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE94560)),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err',
              style: const TextStyle(color: Colors.white)),
        ),
        data: (progress) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score banner — identical to before
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DETECTIVE SCORE',   // ← CHANGED: label
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${progress.totalScore}',
                          style: const TextStyle(
                            color: Color(0xFFE94560),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CASES CLOSED',      // ← CHANGED: label
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${progress.completedLevels.length} / ${levels.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Text(
                  'SELECT CASE',           // ← CHANGED: label
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: levels.length,
                  itemBuilder: (context, i) {
                    final level = levels[i];
                    final isCompleted =
                        progress.completedLevels.contains(level.id);
                    final isLocked = level.id > 1 &&
                        !progress.completedLevels
                            .contains(level.id - 1);

                    return _LevelCard(
                      level: level,
                      isCompleted: isCompleted,
                      isLocked: isLocked,
                      onTap: isLocked
                          ? null
                          : () {
                              // ── CHANGED: go to intro screen, not chat ──
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LevelIntroScreen(level: level),
                                ),
                              );
                            },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// _LevelCard is UNCHANGED from original — identical widget
class _LevelCard extends StatelessWidget {
  final Level level;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.isCompleted,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLocked ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted
                ? level.npc.accentColor.withOpacity(0.12)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCompleted
                  ? level.npc.accentColor.withOpacity(0.4)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: level.npc.accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${level.id}',
                    style: TextStyle(
                      color: level.npc.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.npc.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.introTitle,  // ← CHANGED: show intro title
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      level.introObjective,  // ← CHANGED: show objective
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLocked)
                const Icon(Icons.lock, color: Colors.white38, size: 20)
              else if (isCompleted)
                const Icon(Icons.check_circle,
                    color: Color(0xFF00C851), size: 20)
              else
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white38, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
