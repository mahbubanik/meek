import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/surah.dart';
import '../models/verse.dart';

/// Quran API Service - Fetches Quran data from quran.com API
class QuranApiService {
  static final QuranApiService _instance = QuranApiService._internal();
  factory QuranApiService() => _instance;
  QuranApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.quranApiBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Get verse by key (surah:ayah format)
  Future<Verse> getVerse(int surah, int ayah, {bool includeWords = true}) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.quranVerseEndpoint}/$surah:$ayah',
        queryParameters: {
          'language': 'en',
          'words': includeWords,
          'translations': '131,161', // Sahih International + Bengali
          'word_fields': 'text_uthmani,translation',
        },
      );

      if (response.statusCode == 200) {
        return Verse.fromJson(response.data['verse']);
      }
      throw Exception('Failed to fetch verse');
    } catch (e) {
      throw Exception('Error fetching verse: $e');
    }
  }

  /// Get verses for a surah
  Future<List<Verse>> getVersesBySurah(int surahId, {int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get(
        '/verses/by_chapter/$surahId',
        queryParameters: {
          'language': 'en',
          'words': true,
          'translations': '131,161',
          'page': page,
          'per_page': perPage,
          'word_fields': 'text_uthmani,translation',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> verses = response.data['verses'];
        return verses.map((v) => Verse.fromJson(v)).toList();
      }
      throw Exception('Failed to fetch verses');
    } catch (e) {
      throw Exception('Error fetching verses: $e');
    }
  }

  /// Get audio URL for a verse
  Future<String> getAudioUrl(int surah, int ayah) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.quranAudioEndpoint}/$surah:$ayah',
      );

      if (response.statusCode == 200) {
        final audioFile = response.data['audio_files']?[0];
        if (audioFile != null) {
          return 'https://verses.quran.com/${audioFile['url']}';
        }
      }
      // Fallback audio URL pattern
      return 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$surah$ayah.mp3';
    } catch (e) {
      // Return fallback URL if API fails
      return 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$surah$ayah.mp3';
    }
  }

  /// Get all surahs (chapters) list
  Future<List<Surah>> getAllSurahs() async {
    try {
      final response = await _dio.get('/chapters', queryParameters: {
        'language': 'en',
      });

      if (response.statusCode == 200) {
        final List<dynamic> chapters = response.data['chapters'];
        return chapters.map((c) => Surah.fromJson(c)).toList();
      }
      throw Exception('Failed to fetch surahs');
    } catch (e) {
      throw Exception('Error fetching surahs: $e');
    }
  }

  /// Get surah info
  Future<Surah> getSurah(int surahId) async {
    try {
      final response = await _dio.get('/chapters/$surahId', queryParameters: {
        'language': 'en',
      });

      if (response.statusCode == 200) {
        return Surah.fromJson(response.data['chapter']);
      }
      throw Exception('Failed to fetch surah');
    } catch (e) {
      throw Exception('Error fetching surah: $e');
    }
  }
}
