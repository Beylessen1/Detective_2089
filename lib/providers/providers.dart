// providers.dart
// This file defines all the "providers" — the Riverpod state management layer.
//
// Think of a provider like a global variable that:
//   • Is type-safe
//   • Automatically notifies the UI when it changes
//   • Can depend on other providers
//
// To READ a provider in a widget:   ref.watch(myProvider)
// To CALL a method on a provider:   ref.read(myProvider.notifier).someMethod()

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_progress.dart';
import '../data/levels_data.dart';
import '../models/level.dart';

// ── Auth providers ─────────────────────────────────────────────────────────

// Provides the AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Provides the DatabaseService singleton
final databaseServiceProvider =
    Provider<DatabaseService>((ref) => DatabaseService());

// Streams the current Firebase user (null = logged out)
// Any widget that watches this will rebuild when login state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Progress providers ─────────────────────────────────────────────────────

// Loads and holds the current user's progress from Firestore
final progressProvider =
    StateNotifierProvider<ProgressNotifier, AsyncValue<UserProgress>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final auth = ref.watch(authStateProvider);

  return ProgressNotifier(
    db: db,
    uid: auth.value?.uid,
  );
});

class ProgressNotifier extends StateNotifier<AsyncValue<UserProgress>> {
  final DatabaseService db;
  final String? uid;

  ProgressNotifier({required this.db, required this.uid})
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    if (uid == null) {
      state = AsyncValue.data(UserProgress.fresh());
      return;
    }
    try {
      final progress = await db.loadProgress(uid!);
      state = AsyncValue.data(progress);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Call this after completing a level
  Future<void> completeLevel(int levelId) async {
    final current = state.value;
    if (current == null || uid == null) return;

    final completed = [...current.completedLevels];
    if (!completed.contains(levelId)) {
      completed.add(levelId);
    }

    final updated = current.copyWith(
      completedLevels: completed,
      currentLevel: levelId + 1,
      totalScore: current.totalScore + 100,
    );

    state = AsyncValue.data(updated);
    await db.saveProgress(uid!, updated);
  }
}

// ── Game state ─────────────────────────────────────────────────────────────

// Tracks which level the player is currently playing
final currentLevelProvider = StateProvider<Level?>((ref) => null);

// Tracks attempts remaining in the current chat
final attemptsRemainingProvider = StateProvider<int>((ref) => 20);

// All levels, for the level select screen
final allLevelsProvider = Provider<List<Level>>((ref) => allLevels);
