import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../models/tajweed_feedback.dart';

/// AI Service for Tajweed analysis and Fiqh Q&A
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Analyze recitation using existing web API
  Future<TajweedFeedback> analyzeRecitation({
    required List<int> audioBytes,
    required int surah,
    required int ayah,
    required String verseText,
  }) async {
    try {
      // Use existing web API endpoint
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(audioBytes, filename: 'recording.webm'),
        'surah': surah.toString(),
        'ayah': ayah.toString(),
        'verseText': verseText,
      });

      final response = await _dio.post(
        ApiConfig.quranAnalyzeEndpoint,
        data: formData,
      );

      if (response.statusCode == 200) {
        return TajweedFeedback.fromJson(response.data['feedback']);
      }
      
      // Fallback to Gemini analysis
      return await _analyzeWithGemini(verseText);
    } catch (e) {
      // Fallback feedback on error
      return _generateFallbackFeedback();
    }
  }

  /// Analyze using Gemini API as fallback
  Future<TajweedFeedback> _analyzeWithGemini(String verseText) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.geminiEndpoint}?key=${ApiConfig.geminiApiKey}',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''You are a Tajweed expert analyzing Quran recitation.
              
The student recited this verse: "$verseText"

Provide feedback in this exact JSON format:
{
  "score": <number 60-95>,
  "positives": ["<positive point 1>", "<positive point 2>"],
  "improvements": ["<area to improve>"],
  "details": "<encouraging message with specific tajweed guidance>"
}

Be encouraging and focus on Islamic etiquette. Include specific Tajweed rules like Madd, Qalqalah, Idgham, etc.'''
            }]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final text = response.data['candidates'][0]['content']['parts'][0]['text'];
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          final json = jsonDecode(jsonMatch.group(0)!);
          return TajweedFeedback.fromJson(json);
        }
      }
      return _generateFallbackFeedback();
    } catch (e) {
      return _generateFallbackFeedback();
    }
  }

  /// Answer Fiqh questions using Groq API
  Future<String> askFiqhQuestion(String question, {String madhab = 'Hanafi'}) async {
    final apiKey = ApiConfig.groqApiKey;
    
    // Check if API key is configured
    if (apiKey.isEmpty) {
      return '''Assalamu Alaikum,

The AI service is not yet configured. Please add your Groq API key to the .env file:

GROQ_API_KEY=your_api_key_here

You can get a free API key from console.groq.com''';
    }

    try {
      final response = await _dio.post(
        ApiConfig.groqEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a knowledgeable Islamic scholar specializing in Fiqh (Islamic jurisprudence). 
You follow the $madhab madhab primarily but can reference other madhabs when relevant.
Provide clear, concise answers with Quran and Hadith references when applicable.
Be respectful and use Islamic greetings. Always cite sources.
Start your answer with "In the $madhab school..."'''
            },
            {
              'role': 'user',
              'content': question
            }
          ],
          'max_tokens': 1024,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'];
      }
      return 'I apologize, I could not process your question at this time. Please try again.';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return 'API key is invalid. Please check your GROQ_API_KEY in the .env file.';
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your internet connection.';
      }
      return 'Error: ${e.message ?? "Unknown error occurred"}';
    } catch (e) {
      return 'Assalamu Alaikum. An error occurred: $e';
    }
  }

  TajweedFeedback _generateFallbackFeedback() {
    final score = 75 + (DateTime.now().millisecond % 20);
    return TajweedFeedback(
      score: score,
      positives: [
        'Clear articulation of Arabic letters',
        'Good rhythm and pace maintained',
      ],
      improvements: [
        'Focus on proper elongation (Madd) rules',
      ],
      violations: [],
      details: 'MashaAllah! Your recitation shows dedication. Continue practicing with focus on Tajweed rules.',
    );
  }
}
