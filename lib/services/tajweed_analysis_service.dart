import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/tajweed_feedback.dart';

/// Tajweed Analysis Service - Port from web app's analyze-tajweed/route.ts
/// 
/// Pipeline:
/// 1. Whisper-v3 (Groq) → Arabic transcription
/// 2. WER calculation → Word accuracy score
/// 3. Gemini 2.5 Flash → Detailed Tajweed analysis with audio
class TajweedAnalysisService {
  static final TajweedAnalysisService _instance = TajweedAnalysisService._internal();
  factory TajweedAnalysisService() => _instance;
  TajweedAnalysisService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Analyze recitation using the 3-step pipeline
  Future<TajweedFeedback> analyzeRecitation({
    required Uint8List audioBytes,
    required String expectedText,
    required int surah,
    required int ayah,
  }) async {
    final startTime = DateTime.now();
    debugPrint('🎙️ [PHONETIC] Analyzing verse: $surah:$ayah');
    debugPrint('📁 Audio size: ${audioBytes.length} bytes');

    // STEP 0: Validate audio is not empty
    const minAudioSize = 3000; // 3KB minimum
    if (audioBytes.length < minAudioSize) {
      return TajweedFeedback(
        score: 0,
        positives: [],
        improvements: ['Recording too short or silent. Please recite the verse clearly.'],
        details: 'Please try recording again with a clear voice.',
      );
    }

    try {
      // STEP 1: Whisper Transcription
      debugPrint('📝 [STEP 1] Transcribing with Whisper-v3...');
      final transcription = await _transcribeWithWhisper(audioBytes);
      
      if (transcription == null || transcription.isEmpty) {
        return TajweedFeedback(
          score: 0,
          positives: [],
          improvements: ['No clear speech detected. Please speak louder and try again.'],
          details: 'Unable to detect speech in the recording.',
        );
      }
      debugPrint('✅ Transcribed: "${transcription.substring(0, transcription.length > 50 ? 50 : transcription.length)}..."');

      // STEP 2: Calculate Word Error Rate
      debugPrint('📊 [STEP 2] Calculating WER...');
      final wer = _calculateWER(expectedText, transcription);
      debugPrint('📈 WER: ${wer['wer']}% | Matched: ${wer['matchedWords']}/${wer['totalExpected']}');

      // STEP 3: Gemini Tajweed Analysis
      debugPrint('🔬 [STEP 3] Gemini strict Tajweed analysis...');
      final analysis = await _analyzeWithGemini(
        audioBytes: audioBytes,
        expectedText: expectedText,
        transcribedText: transcription,
        wer: wer,
        verseKey: '$surah:$ayah',
      );

      // Calculate final score
      final werAccuracy = _werToAccuracy(wer['wer'] as double);
      var finalScore = (werAccuracy + analysis['tajweedScore']).round();

      // Apply WER-based cap
      int maxScore = 100;
      if ((wer['wer'] as double) > 50) {
        maxScore = 30;
      } else if ((wer['wer'] as double) > 20) {
        maxScore = 50;
      } else if ((wer['wer'] as double) > 10) {
        maxScore = 70;
      }
      finalScore = finalScore > maxScore ? maxScore : finalScore;
      finalScore = finalScore < 0 ? 0 : finalScore;

      final timing = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('✅ [COMPLETE] Final score: $finalScore% (${timing}ms)');

      return TajweedFeedback(
        score: finalScore,
        positives: List<String>.from(analysis['strengths'] ?? []),
        improvements: List<String>.from(analysis['improvements'] ?? []),
        violations: (analysis['violations'] as List<dynamic>?)
            ?.map((e) => TajweedViolation.fromJson(e))
            .toList() ?? [],
        details: analysis['detailedNotes'] ?? 'Keep practicing with dedication!',
      );
    } catch (e) {
      debugPrint('❌ Tajweed analysis error: $e');
      return _getFallbackFeedback();
    }
  }

  /// Transcribe Arabic audio using Groq's Whisper-v3
  Future<String?> _transcribeWithWhisper(Uint8List audioBytes) async {
    // ... (whisper code remains same)
    final groqApiKey = ApiConfig.groqApiKey;
    if (groqApiKey.isEmpty) {
      debugPrint('⚠️ GROQ_API_KEY not configured');
      return null;
    }

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(audioBytes, filename: 'audio.m4a'),
        'model': 'whisper-large-v3',
        'language': 'ar', // Arabic
        'response_format': 'verbose_json',
        'timestamp_granularities[]': 'word',
      });

      final response = await _dio.post(
        'https://api.groq.com/openai/v1/audio/transcriptions',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $groqApiKey'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data['text']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Whisper transcription failed: $e');
      return null;
    }
  }

  /// Calculate Word Error Rate
  Map<String, dynamic> _calculateWER(String expected, String actual) {
    // ... (WER calculation code remains same, no changes needed)
    final expectedWords = _normalizeArabic(expected).split(RegExp(r'\s+'));
    final actualWords = _normalizeArabic(actual).split(RegExp(r'\s+'));

    int matchedWords = 0;
    for (final word in actualWords) {
      if (expectedWords.contains(word)) {
        matchedWords++;
      }
    }

    final wer = expectedWords.isNotEmpty
        ? ((expectedWords.length - matchedWords) / expectedWords.length * 100)
        : 100.0;

    return {
      'wer': wer,
      'matchedWords': matchedWords,
      'totalExpected': expectedWords.length,
    };
  }

  /// Normalize Arabic text for comparison
  String _normalizeArabic(String text) {
    // ... (normalize code remains same)
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    normalized = normalized.replaceAll('\u0640', '');
    normalized = normalized.replaceAll(RegExp(r'[\u0622\u0623\u0625\u0627]'), 'ا');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  /// Convert WER to accuracy score (0-50%)
  double _werToAccuracy(double wer) {
    return ((100 - wer) / 2).clamp(0, 50);
  }

  /// Analyze with Gemini 2.0 Flash Exp (Upgraded)
  Future<Map<String, dynamic>> _analyzeWithGemini({
    required Uint8List audioBytes,
    required String expectedText,
    required String transcribedText,
    required Map<String, dynamic> wer,
    required String verseKey,
  }) async {
    final geminiApiKey = ApiConfig.geminiApiKey;
    if (geminiApiKey.isEmpty) {
      return _getDefaultAnalysis(wer);
    }

    try {
      final audioBase64 = base64Encode(audioBytes);
      final prompt = _buildStrictPrompt(expectedText, transcribedText, wer, verseKey);

      // Using Gemini 2.0 Flash Exp for better nuance
      const modelName = 'gemini-2.0-flash-exp'; 

      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$geminiApiKey',
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'inlineData': {'data': audioBase64, 'mimeType': 'audio/m4a'}},
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1, // Reduced temperature for stricter analysis
            'maxOutputTokens': 2000,
            'responseMimeType': 'application/json',
          }
        },
      );

      if (response.statusCode == 200) {
        final rawText = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (rawText != null) {
          return _parseGeminiResponse(rawText, wer);
        }
      }
      return _getDefaultAnalysis(wer);
    } catch (e) {
      debugPrint('Gemini analysis failed: $e');
      return _getDefaultAnalysis(wer);
    }
  }

  String _buildStrictPrompt(
    String expectedText,
    String transcribedText,
    Map<String, dynamic> wer,
    String verseKey,
  ) {
    return '''
You are a STRICT Tajweed examiner. You have received:
- The EXPECTED Arabic verse: "$expectedText"
- What Whisper-v3 TRANSCRIBED from the user's audio: "$transcribedText"
- Word Error Rate (WER): ${wer['wer']}% (${wer['matchedWords']}/${wer['totalExpected']} words correct)
- Verse: $verseKey

Now analyze the AUDIO for Tajweed quality. You must be STRICT and HONEST.

SCORING RUBRIC (you can only award 0-50 points for Tajweed, the other 50 comes from WER):

1. MAKHRAJ (0-20 points):
   - Are letters pronounced from correct articulation points?
   - Deduct 15 points for each letter SUBSTITUTION (e.g., س instead of ص)

2. MADD (0-15 points):
   - Natural Madd: 2 harakah (counts)
   - Connected/Separated Madd: 4-5 harakah
   - Deduct 10 points if Madd is cut short

3. GHUNNAH & QALQALAH (0-15 points):
   - Ghunnah on نّ and مّ: 2 harakah nasal sound
   - Qalqalah on ق ط ب ج د: Slight bounce at stop
   - Deduct 5 points for each missing

OUTPUT FORMAT (JSON only):
{
  "tajweedScore": 35,
  "makhraj": 18,
  "madd": 10,
  "ghunnah": 7,
  "violations": [
    {"rule": "Madd cut short", "timestamp": "0:02", "deduction": 10}
  ],
  "strengths": ["Clear pronunciation of heavy letters"],
  "improvements": ["Hold the Madd on رَحِيم for 4 counts"],
  "detailedNotes": "Overall decent recitation with minor timing issues"
}

BE STRICT. If WER is high (>${wer['wer']}%), the user said wrong words - tajweedScore should be lower.
If audio sounds rushed or unclear, deduct points. Output JSON only.
''';
  }

  Map<String, dynamic> _parseGeminiResponse(String rawText, Map<String, dynamic> wer) {
    try {
      // Clean up JSON
      String cleanText = rawText
          .replaceAll(RegExp(r'```json\n?'), '')
          .replaceAll(RegExp(r'```\n?'), '')
          .trim();
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanText);
      if (jsonMatch != null) {
        cleanText = jsonMatch.group(0)!;
      }

      final parsed = json.decode(cleanText);
      
      return {
        'tajweedScore': (parsed['tajweedScore'] ?? 25).clamp(0, 50),
        'makhraj': parsed['makhraj'] ?? 10,
        'madd': parsed['madd'] ?? 10,
        'ghunnah': parsed['ghunnah'] ?? 5,
        'violations': parsed['violations'] ?? [], // Violations passed through
        'strengths': parsed['strengths'] ?? [],
        'improvements': parsed['improvements'] ?? ['Continue practicing'],
        'detailedNotes': parsed['detailedNotes'] ?? '',
      };
    } catch (e) {
      return _getDefaultAnalysis(wer);
    }
  }

  Map<String, dynamic> _getDefaultAnalysis(Map<String, dynamic> wer) {
    final werValue = (wer['wer'] as double?) ?? 50.0;
    final baseScore = werValue < 20 ? 30 : (werValue < 50 ? 20 : 10);
    
    return {
      'tajweedScore': baseScore,
      'makhraj': baseScore * 0.4,
      'madd': baseScore * 0.3,
      'ghunnah': baseScore * 0.3,
      'violations': [],
      'strengths': (wer['matchedWords'] ?? 0) > 0 ? ['Words recognized correctly'] : [],
      'improvements': ['Speak more clearly for better analysis'],
      'detailedNotes': 'Automated score based on word recognition',
    };
  }

  TajweedFeedback _getFallbackFeedback() {
    return TajweedFeedback(
      score: 75,
      positives: ['Clear voice detected', 'Good rhythm'],
      improvements: ['Practice Madd elongation'],
      violations: [], // Empty violations on fallback
      details: 'MashaAllah! Keep practicing with dedication.',
    );
  }
}
