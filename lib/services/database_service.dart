import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_progress.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Returns a reference to the user's progress document
  DocumentReference<Map<String, dynamic>> _progressRef(String uid) {
    return _db.collection('users').doc(uid).collection('data').doc('progress');
  }

  // Load the player's progress from Firestore.
  // Returns fresh progress if none exists yet.
  Future<UserProgress> loadProgress(String uid) async {
    try {
      final doc = await _progressRef(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProgress.fromMap(doc.data()!);
      }
    } catch (e) {
      // If anything goes wrong, return fresh progress
      print('❌ Load progress failed: $e');
    }
    return UserProgress.fresh();
  }

  // Save the player's progress to Firestore.
  // merge: true means we only update the fields we send (safe).
  Future<void> saveProgress(String uid, UserProgress progress) async {
    print('💾 Saving to Firestore — uid: $uid, data: ${progress.toMap()}');
    try {
      await _progressRef(uid).set(
        progress.toMap(),
        SetOptions(merge: true),
      );
      print('✅ Firestore save successful');
    } catch (e) {
      print('❌ Firestore save failed: $e');
    }
  }

  // Record a level completion with extra details
  Future<void> recordLevelComplete({
    required String uid,
    required int levelId,
    required String extractedSecret,
    required int attemptsUsed,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('completions')
        .doc('level_$levelId')
        .set({
      'levelId': levelId,
      'extractedSecret': extractedSecret,
      'attemptsUsed': attemptsUsed,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
