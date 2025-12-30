import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Source citation in Fiqh responses
class FiqhCitation {
  final String source;
  final String reference;
  final String text;
  final bool verified;

  FiqhCitation({
    required this.source,
    required this.reference,
    required this.text,
    this.verified = true,
  });

  factory FiqhCitation.fromJson(Map<String, dynamic> json) {
    return FiqhCitation(
      source: json['source']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      verified: json['verified'] ?? true,
    );
  }
}

/// Different madhab position
class MadhabPosition {
  final String madhab;
  final String position;

  MadhabPosition({required this.madhab, required this.position});

  factory MadhabPosition.fromJson(Map<String, dynamic> json) {
    return MadhabPosition(
      madhab: json['madhab']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
    );
  }
}

/// Complete Fiqh response
class FiqhResponse {
  final String directAnswer;
  final String reasoning;
  final List<MadhabPosition> otherSchools;
  final List<FiqhCitation> citations;
  final String hallucinationRisk;
  final String confidenceLevel;

  FiqhResponse({
    required this.directAnswer,
    required this.reasoning,
    required this.otherSchools,
    required this.citations,
    required this.hallucinationRisk,
    required this.confidenceLevel,
  });

  factory FiqhResponse.fromJson(Map<String, dynamic> json) {
    return FiqhResponse(
      directAnswer: json['directAnswer']?.toString() ?? '',
      reasoning: json['reasoning']?.toString() ?? '',
      otherSchools: (json['otherSchools'] as List<dynamic>?)
              ?.map((e) => MadhabPosition.fromJson(e))
              .toList() ?? [],
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => FiqhCitation.fromJson(e))
              .toList() ?? [],
      hallucinationRisk: json['sourceVerification']?['hallucinationRisk']?.toString() ?? 'Unknown',
      confidenceLevel: json['sourceVerification']?['confidenceLevel']?.toString() ?? 'Unknown',
    );
  }
}

/// Fiqh Service - Port from web app's groq.ts and openai.ts
/// 
/// Primary: Groq Llama 3.3 70B with madhab-specific prompts
/// Fallback: OpenAI GPT-4o-mini
class FiqhService {
  static final FiqhService _instance = FiqhService._internal();
  factory FiqhService() => _instance;
  FiqhService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Ask a Fiqh question
  Future<FiqhResponse> askQuestion({
    required String question,
    required String madhab,
  }) async {
    debugPrint('📖 Fiqh query: "$question" (Madhab: $madhab)');

    // Try Groq first
    try {
      return await _askGroq(question, madhab);
    } catch (e) {
      debugPrint('⚠️ Groq failed, trying OpenAI fallback: $e');
    }

    // Fallback to OpenAI
    try {
      return await _askOpenAI(question, madhab);
    } catch (e) {
      debugPrint('❌ OpenAI also failed: $e');
    }

    // Return error response
    return FiqhResponse(
      directAnswer: 'We are currently having trouble connecting to the AI Mufti. Please try again in a moment.',
      reasoning: '',
      otherSchools: [],
      citations: [],
      hallucinationRisk: 'N/A',
      confidenceLevel: 'Connection Error',
    );
  }

  /// Query Groq Llama 3.3 70B
  Future<FiqhResponse> _askGroq(String question, String madhab) async {
    final apiKey = ApiConfig.groqApiKey;
    if (apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not configured');
    }

    final systemPrompt = _buildSystemPrompt(madhab);
    final userPrompt = _buildUserPrompt(question, madhab);

    final response = await _dio.post(
      'https://api.groq.com/openai/v1/chat/completions',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      }),
      data: {
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.2,
        'max_tokens': 2500,
        'response_format': {'type': 'json_object'},
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final rawContent = response.data['choices'][0]['message']['content'];
    final parsed = json.decode(rawContent);
    
    // Validate madhab mention
    var fiqhResponse = FiqhResponse.fromJson(parsed);
    if (!fiqhResponse.directAnswer.toLowerCase().contains(madhab.toLowerCase())) {
      fiqhResponse = FiqhResponse(
        directAnswer: 'In the $madhab school, ${fiqhResponse.directAnswer}',
        reasoning: fiqhResponse.reasoning,
        otherSchools: fiqhResponse.otherSchools,
        citations: fiqhResponse.citations,
        hallucinationRisk: fiqhResponse.hallucinationRisk,
        confidenceLevel: fiqhResponse.confidenceLevel,
      );
    }

    debugPrint('✅ Groq response received');
    return fiqhResponse;
  }

  /// Query OpenAI GPT-4o-mini (fallback)
  Future<FiqhResponse> _askOpenAI(String question, String madhab) async {
    final apiKey = ApiConfig.openaiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not configured');
    }

    final systemPrompt = _buildOpenAISystemPrompt(madhab);
    final userPrompt = _buildUserPrompt(question, madhab);

    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      }),
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
        'max_tokens': 2000,
        'response_format': {'type': 'json_object'},
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }

    final rawContent = response.data['choices'][0]['message']['content'];
    final parsed = json.decode(rawContent);
    
    var fiqhResponse = FiqhResponse.fromJson(parsed);
    if (!fiqhResponse.directAnswer.toLowerCase().contains(madhab.toLowerCase())) {
      fiqhResponse = FiqhResponse(
        directAnswer: 'In the $madhab school, ${fiqhResponse.directAnswer}',
        reasoning: fiqhResponse.reasoning,
        otherSchools: fiqhResponse.otherSchools,
        citations: fiqhResponse.citations,
        hallucinationRisk: 'Medium - GPT fallback',
        confidenceLevel: 'Medium (70%)',
      );
    }

    debugPrint('✅ OpenAI response received');
    return fiqhResponse;
  }

  /// Build system prompt for Groq
  String _buildSystemPrompt(String madhab) {
    return '''
You are a scholarly Islamic knowledge assistant with deep expertise in all four Sunni madhabs. Your responses are based exclusively on verified, documented Islamic sources.

USER'S MADHAB: ${madhab.toUpperCase()}

CRITICAL RULES:
1. The user follows $madhab school - your PRIMARY answer MUST be from $madhab perspective
2. You are an EDUCATOR explaining established scholarship, NOT a mufti issuing fatwas
3. Religious questions about prayer, dua, fasting, zakat are WELCOMED and ENCOURAGED
4. Never refuse to answer with "consult a scholar" - you ARE the educational resource
5. Start your direct answer with: "In the $madhab school..."
6. VERIFICATION MANDATE: Every citation MUST include source, reference, and verified text
7. DO NOT hallucinate sources, Hadith, or Quranic verses - only cite what you can verify
8. Include confidence level assessment
9. Flag any areas of scholarly disagreement or uncertainty

${_getMadhabSources(madhab)}
${_getMadhabScholars(madhab)}
${_getMadhabMethodology(madhab)}

OUTPUT FORMAT (JSON ONLY):
{
  "directAnswer": "In the $madhab school, [2-3 sentence clear answer based on verified sources]",
  "reasoning": "Detailed explanation of WHY $madhab scholars hold this view. Reference Quranic evidence, authenticated Hadith, and scholarly methodology. 200-300 words.",
  "otherSchools": [
    {"madhab": "Shafi'i", "position": "Their verified position if significantly different"}
  ],
  "citations": [
    {"source": "Quran", "reference": "Surah [Name] [X:Y]", "text": "verse text", "verified": true},
    {"source": "Hadith", "reference": "Sahih Bukhari [XXXX]", "text": "hadith text", "verified": true},
    {"source": "Scholar", "reference": "Imam [Name] in [Book]", "text": "opinion", "verified": true}
  ],
  "sourceVerification": {
    "primarySourcesUsed": true,
    "hallucinationRisk": "Low/Medium/High",
    "confidenceLevel": "High (95%)/Medium (70%)/Low (40%)"
  }
}
''';
  }

  String _buildOpenAISystemPrompt(String madhab) {
    return '''
You are an expert Islamic scholar AI. Your primary role is to answer questions from the ${madhab.toUpperCase()} school perspective.

CRITICAL RULES:
1. Start every answer with "In the $madhab school..."
2. Provide REASONING before the final answer
3. Always include specific citations (Quran verses, Hadith references, scholar opinions)
4. Be educational, not issuing fatwas
5. Never refuse religious questions - you ARE the educational resource

OUTPUT FORMAT (JSON only):
{
  "directAnswer": "In the $madhab school, [clear 2-3 sentence answer]",
  "reasoning": "[200-300 words explaining WHY with evidence]",
  "otherSchools": [{"madhab": "Name", "position": "Their view if different"}],
  "citations": [
    {"source": "Quran", "reference": "Surah X:Y", "text": "verse text", "verified": true},
    {"source": "Hadith", "reference": "Bukhari/Muslim XXXX", "text": "hadith text", "verified": true},
    {"source": "Scholar", "reference": "Imam Name - Book", "text": "opinion", "verified": true}
  ],
  "sourceVerification": {
    "primarySourcesUsed": true,
    "hallucinationRisk": "Low/Medium/High",
    "confidenceLevel": "High (95%)/Medium (70%)/Low (40%)"
  }
}
''';
  }

  String _buildUserPrompt(String question, String madhab) {
    return '''
Question: "$question"

Provide a comprehensive educational answer following the JSON format.

MANDATORY REQUIREMENTS:
1. Direct answer from $madhab perspective (start with "In the $madhab school...")
2. Detailed reasoning with VERIFIED evidence only
3. Other madhabs only if positions differ and are DOCUMENTED
4. Minimum 3 citations with specific, verifiable references
5. Source verification assessment
6. Confidence level (High/Medium/Low)
7. NO hallucinated sources, Hadith references, or scholarly attributions
8. If uncertain about a source, flag it as uncertain

Do NOT invent citations. Only reference documented Islamic sources.

Output valid JSON only, no markdown formatting.
''';
  }

  String _getMadhabSources(String madhab) {
    final sources = {
      'Hanafi': 'PRIMARY SOURCES FOR HANAFI:\nAl-Hidayah (Al-Marghinani), Al-Mabsut (Al-Sarakhshi), Fatawa Alamgiri, Radd al-Muhtar (Ibn Abidin)',
      "Shafi'i": "PRIMARY SOURCES FOR SHAFI'I:\nAl-Umm (Imam al-Shafi'i), Al-Majmu' (An-Nawawi), Minhaj al-Talibin (An-Nawawi)",
      'Maliki': "PRIMARY SOURCES FOR MALIKI:\nAl-Muwatta' (Malik ibn Anas), Al-Mudawwana (Sahnun), Risalah (Ibn Abi Zayd)",
      'Hanbali': 'PRIMARY SOURCES FOR HANBALI:\nMusnad Ahmad, Al-Mughni (Ibn Qudamah), Kashaf al-Qina (Al-Bahuti)',
    };
    return sources[madhab] ?? 'Classical fiqh texts';
  }

  String _getMadhabScholars(String madhab) {
    final scholars = {
      'Hanafi': 'KEY HANAFI SCHOLARS:\nImam Abu Hanifa (d. 150 AH), Abu Yusuf, Muhammad al-Shaybani, Ibn Abidin',
      "Shafi'i": "KEY SHAFI'I SCHOLARS:\nImam al-Shafi'i, An-Nawawi, Ibn Hajar al-Asqalani",
      'Maliki': 'KEY MALIKI SCHOLARS:\nImam Malik ibn Anas, Sahnun, Ibn Abi Zayd al-Qayrawani',
      'Hanbali': 'KEY HANBALI SCHOLARS:\nImam Ahmad ibn Hanbal, Ibn Qudamah, Ibn Taymiyyah',
    };
    return scholars[madhab] ?? 'Classical Islamic scholars';
  }

  String _getMadhabMethodology(String madhab) {
    final methods = {
      'Hanafi': "HANAFI METHODOLOGY:\nEmphasizes logical reasoning (Ra'y), analogical deduction (Qiyas), and juristic preference (Istihsan).",
      "Shafi'i": "SHAFI'I METHODOLOGY:\nStrict adherence to authenticated Hadith with systematic legal theory. Clear hierarchy: Quran > Sunnah > Ijma' > Qiyas.",
      'Maliki': 'MALIKI METHODOLOGY:\nPractices of Medina (Amal Ahl al-Madinah) as key source. Masalih Mursalah (public interests).',
      'Hanbali': 'HANBALI METHODOLOGY:\nStrong preference for Hadith over analogical reasoning. Follows explicit textual evidence closely.',
    };
    return methods[madhab] ?? 'Classical usul al-fiqh principles';
  }
}
