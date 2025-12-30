/// Tajweed Feedback Model
class TajweedFeedback {
  final int score;
  final List<String> positives;
  final List<String> improvements;
  final List<TajweedViolation> violations; // Added violations
  final String details;

  TajweedFeedback({
    required this.score,
    required this.positives,
    required this.improvements,
    required this.violations,
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
      violations: (json['violations'] as List<dynamic>?)
          ?.map((e) => TajweedViolation.fromJson(e))
          .toList() ?? [],
      details: json['details'] ?? 'Keep practicing!',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'positives': positives,
      'improvements': improvements,
      'violations': violations.map((e) => e.toJson()).toList(),
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

/// Detailed Tajweed Violation
class TajweedViolation {
  final String rule;
  final String timestamp;
  final int deduction;

  TajweedViolation({
    required this.rule,
    required this.timestamp,
    required this.deduction,
  });

  factory TajweedViolation.fromJson(Map<String, dynamic> json) {
    return TajweedViolation(
      rule: json['rule']?.toString() ?? 'General Rule',
      timestamp: json['timestamp']?.toString() ?? '',
      deduction: json['deduction'] is int ? json['deduction'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rule': rule,
      'timestamp': timestamp,
      'deduction': deduction,
    };
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
