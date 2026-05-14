// Represents what we save to Firestore for each user
class UserProgress {
  final int currentLevel;
  final List<int> completedLevels;
  final int totalScore;

  const UserProgress({
    required this.currentLevel,
    required this.completedLevels,
    required this.totalScore,
  });

  // Convert to a Map so Firestore can store it
  Map<String, dynamic> toMap() {
    return {
      'currentLevel': currentLevel,
      'completedLevels': completedLevels,
      'totalScore': totalScore,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create from a Firestore document Map
  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      currentLevel: (map['currentLevel'] as num?)?.toInt() ?? 0,
      completedLevels: List<int>.from(map['completedLevels'] ?? []),
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
    );
  }

  // A fresh progress for a new user
  factory UserProgress.fresh() {
    return const UserProgress(
      currentLevel: 0,
      completedLevels: [],
      totalScore: 0,
    );
  }

  // Returns a copy with some fields changed
  UserProgress copyWith({
    int? currentLevel,
    List<int>? completedLevels,
    int? totalScore,
  }) {
    return UserProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      completedLevels: completedLevels ?? this.completedLevels,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}
