/// Verse Model with word-by-word support
class Verse {
  final int id;
  final String verseKey;
  final int verseNumber;
  final int surahNumber;
  final String textUthmani;
  final String? textSimple;
  final List<Word> words;
  final List<Translation> translations;

  Verse({
    required this.id,
    required this.verseKey,
    required this.verseNumber,
    required this.surahNumber,
    required this.textUthmani,
    this.textSimple,
    this.words = const [],
    this.translations = const [],
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    final verseKey = json['verse_key'] ?? '';
    final parts = verseKey.split(':');
    
    return Verse(
      id: json['id'] ?? 0,
      verseKey: verseKey,
      verseNumber: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : json['verse_number'] ?? 0,
      surahNumber: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : json['chapter_id'] ?? 0,
      textUthmani: json['text_uthmani'] ?? json['text'] ?? '',
      textSimple: json['text_imlaei_simple'],
      words: (json['words'] as List<dynamic>?)
          ?.map((w) => Word.fromJson(w))
          .toList() ?? [],
      translations: (json['translations'] as List<dynamic>?)
          ?.map((t) => Translation.fromJson(t))
          .toList() ?? [],
    );
  }

  /// Get English translation
  String get englishTranslation {
    final english = translations.firstWhere(
      (t) => t.resourceId == 131, // Sahih International
      orElse: () => translations.isNotEmpty ? translations.first : Translation.empty(),
    );
    return english.text;
  }

  /// Get Bangla translation
  String get banglaTranslation {
    final bangla = translations.firstWhere(
      (t) => t.resourceId == 161, // Bengali
      orElse: () => Translation.empty(),
    );
    return bangla.text;
  }
}

/// Word model for word-by-word display
class Word {
  final int id;
  final int position;
  final String textUthmani;
  final String? translation;
  final String? transliteration;
  final String charTypeName;

  Word({
    required this.id,
    required this.position,
    required this.textUthmani,
    this.translation,
    this.transliteration,
    this.charTypeName = 'word',
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] ?? 0,
      position: json['position'] ?? 0,
      textUthmani: json['text_uthmani'] ?? json['text'] ?? '',
      translation: json['translation']?['text'],
      transliteration: json['transliteration']?['text'],
      charTypeName: json['char_type_name'] ?? 'word',
    );
  }

  bool get isWord => charTypeName == 'word';
  bool get isEnd => charTypeName == 'end';
}

/// Translation model
class Translation {
  final int resourceId;
  final String text;
  final String? resourceName;

  Translation({
    required this.resourceId,
    required this.text,
    this.resourceName,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    // Clean HTML tags from text
    String rawText = json['text'] ?? '';
    rawText = rawText.replaceAll(RegExp(r'<[^>]*>'), '');
    
    return Translation(
      resourceId: json['resource_id'] ?? 0,
      text: rawText,
      resourceName: json['resource_name'],
    );
  }

  factory Translation.empty() => Translation(resourceId: 0, text: '');
}
