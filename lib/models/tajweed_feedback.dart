/// Tajweed Feedback Model
class TajweedFeedback {
  final int score;
  final List<String> positives;
  final List<String> improvements;
  final String details;

  TajweedFeedback({
    required this.score,
    required this.positives,
    required this.improvements,
    required this.details,
  });

  factory TajweedFeedback.fromJson(Map<String, dynamic> json) {
    return TajweedFeedback(
      score: json['score'] ?? 75,
      positives: (json['positives'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      improvements: (json['improvements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      details: json['details'] ?? 'Keep practicing!',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'positives': positives,
      'improvements': improvements,
      'details': details,
    };
  }

  /// Get emotional message based on score
  EmotionalMessage get emotionalMessage {
    if (score >= 90) {
      return EmotionalMessage(
        emoji: '🌟',
        arabic: 'ماشاء الله',
        english: 'Excellent recitation! May Allah bless you.',
      );
    } else if (score >= 75) {
      return EmotionalMessage(
        emoji: '✨',
        arabic: 'ماشاء الله',
        english: 'Beautiful effort! Keep going.',
      );
    } else if (score >= 60) {
      return EmotionalMessage(
        emoji: '💪',
        arabic: 'جزاك الله خيرا',
        english: 'Good progress! Practice makes perfect.',
      );
    } else {
      return EmotionalMessage(
        emoji: '🤲',
        arabic: 'بارك الله فيك',
        english: 'Every attempt brings you closer to perfection.',
      );
    }
  }
}

/// Emotional message for feedback display
class EmotionalMessage {
  final String emoji;
  final String arabic;
  final String english;

  EmotionalMessage({
    required this.emoji,
    required this.arabic,
    required this.english,
  });
}
