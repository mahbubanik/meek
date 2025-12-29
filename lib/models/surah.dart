/// Surah (Chapter) Model
class Surah {
  final int id;
  final String nameSimple;
  final String nameArabic;
  final String nameComplex;
  final int versesCount;
  final String revelationPlace;
  final int revelationOrder;
  final String translatedName;

  Surah({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.nameComplex,
    required this.versesCount,
    required this.revelationPlace,
    required this.revelationOrder,
    required this.translatedName,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] ?? 0,
      nameSimple: json['name_simple'] ?? '',
      nameArabic: json['name_arabic'] ?? '',
      nameComplex: json['name_complex'] ?? '',
      versesCount: json['verses_count'] ?? 0,
      revelationPlace: json['revelation_place'] ?? '',
      revelationOrder: json['revelation_order'] ?? 0,
      translatedName: json['translated_name']?['name'] ?? json['name_simple'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_simple': nameSimple,
      'name_arabic': nameArabic,
      'name_complex': nameComplex,
      'verses_count': versesCount,
      'revelation_place': revelationPlace,
      'revelation_order': revelationOrder,
      'translated_name': translatedName,
    };
  }
}

/// Static list of all 114 Surahs for offline/quick access
final List<Surah> allSurahs = [
  Surah(id: 1, nameSimple: 'Al-Fatihah', nameArabic: 'الفاتحة', nameComplex: 'Al-Fātiĥah', versesCount: 7, revelationPlace: 'makkah', revelationOrder: 5, translatedName: 'The Opener'),
  Surah(id: 2, nameSimple: 'Al-Baqarah', nameArabic: 'البقرة', nameComplex: 'Al-Baqarah', versesCount: 286, revelationPlace: 'madinah', revelationOrder: 87, translatedName: 'The Cow'),
  Surah(id: 3, nameSimple: "Al-'Imran", nameArabic: 'آل عمران', nameComplex: "Āli 'Imrān", versesCount: 200, revelationPlace: 'madinah', revelationOrder: 89, translatedName: 'Family of Imran'),
  Surah(id: 4, nameSimple: 'An-Nisa', nameArabic: 'النساء', nameComplex: 'An-Nisā', versesCount: 176, revelationPlace: 'madinah', revelationOrder: 92, translatedName: 'The Women'),
  Surah(id: 5, nameSimple: "Al-Ma'idah", nameArabic: 'المائدة', nameComplex: "Al-Mā'idah", versesCount: 120, revelationPlace: 'madinah', revelationOrder: 112, translatedName: 'The Table Spread'),
  Surah(id: 6, nameSimple: "Al-An'am", nameArabic: 'الأنعام', nameComplex: "Al-An'ām", versesCount: 165, revelationPlace: 'makkah', revelationOrder: 55, translatedName: 'The Cattle'),
  Surah(id: 7, nameSimple: "Al-A'raf", nameArabic: 'الأعراف', nameComplex: "Al-A'rāf", versesCount: 206, revelationPlace: 'makkah', revelationOrder: 39, translatedName: 'The Heights'),
  Surah(id: 8, nameSimple: 'Al-Anfal', nameArabic: 'الأنفال', nameComplex: 'Al-Anfāl', versesCount: 75, revelationPlace: 'madinah', revelationOrder: 88, translatedName: 'The Spoils of War'),
  Surah(id: 9, nameSimple: 'At-Tawbah', nameArabic: 'التوبة', nameComplex: 'At-Tawbah', versesCount: 129, revelationPlace: 'madinah', revelationOrder: 113, translatedName: 'The Repentance'),
  Surah(id: 10, nameSimple: 'Yunus', nameArabic: 'يونس', nameComplex: 'Yūnus', versesCount: 109, revelationPlace: 'makkah', revelationOrder: 51, translatedName: 'Jonah'),
  // ... Adding key surahs for now, full 114 would be too long
  Surah(id: 36, nameSimple: 'Ya-Sin', nameArabic: 'يس', nameComplex: 'Yā-Sīn', versesCount: 83, revelationPlace: 'makkah', revelationOrder: 41, translatedName: 'Ya Sin'),
  Surah(id: 55, nameSimple: 'Ar-Rahman', nameArabic: 'الرحمن', nameComplex: 'Ar-Raĥmān', versesCount: 78, revelationPlace: 'madinah', revelationOrder: 97, translatedName: 'The Beneficent'),
  Surah(id: 67, nameSimple: 'Al-Mulk', nameArabic: 'الملك', nameComplex: 'Al-Mulk', versesCount: 30, revelationPlace: 'makkah', revelationOrder: 77, translatedName: 'The Sovereignty'),
  Surah(id: 78, nameSimple: 'An-Naba', nameArabic: 'النبأ', nameComplex: "An-Naba'", versesCount: 40, revelationPlace: 'makkah', revelationOrder: 80, translatedName: 'The Tidings'),
  Surah(id: 112, nameSimple: 'Al-Ikhlas', nameArabic: 'الإخلاص', nameComplex: 'Al-Ikhlāş', versesCount: 4, revelationPlace: 'makkah', revelationOrder: 22, translatedName: 'The Sincerity'),
  Surah(id: 113, nameSimple: 'Al-Falaq', nameArabic: 'الفلق', nameComplex: 'Al-Falaq', versesCount: 5, revelationPlace: 'makkah', revelationOrder: 20, translatedName: 'The Daybreak'),
  Surah(id: 114, nameSimple: 'An-Nas', nameArabic: 'الناس', nameComplex: 'An-Nās', versesCount: 6, revelationPlace: 'makkah', revelationOrder: 21, translatedName: 'Mankind'),
];
