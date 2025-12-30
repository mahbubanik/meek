/// API Configuration for MEEK App
/// API keys should be added via environment or secure storage
/// DO NOT commit real API keys to version control

class ApiConfig {
  ApiConfig._();

  // ============================================
  // SUPABASE (Public - OK to commit)
  // ============================================
  static const String supabaseUrl = 'https://lwqajokojdrktzkptzrt.supabase.co';
  static const String supabaseAnonKey = 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3cWFqb2tvamRya3R6a3B0enJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMTg2NzgsImV4cCI6MjA4MjU5NDY3OH0.11FWo9rakEW-odDAxn8UnkXkz7mv0e99bvO3T5ZatiY';
  static const String projectId = 'lwqajokojdrktzkptzrt';

  // ============================================
  // AI SERVICES - Keys loaded from secure storage
  // Set these in your local .env or secure storage
  // ============================================
  
  /// Google Gemini API - Set via environment
  static String geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  /// Groq API - Set via environment (for Whisper + Llama 3.3 70B)
  static String groqApiKey = const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  
  /// OpenAI API - Set via environment (fallback for Fiqh)
  static String openaiApiKey = const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String openaiEndpoint = 'https://api.openai.com/v1/chat/completions';


  // ============================================
  // QURAN API (Free, no key needed)
  // ============================================
  static const String quranApiBase = 'https://api.quran.com/api/v4';
  static const String quranVerseEndpoint = '/verses/by_key';
  static const String quranAudioEndpoint = '/recitations/7/by_ayah'; // Mishary Rashid
  
  // ============================================
  // PRAYER TIMES API (Free, no key needed)
  // ============================================
  static const String aladhanApiBase = 'https://api.aladhan.com/v1';
  static const String prayerTimesEndpoint = '/timings';

  // ============================================
  // TAJWEED ANALYSIS (Existing Web API)
  // ============================================
  static const String tajweedAnalysisEndpoint = 'https://meek-zeta.vercel.app/api/analyze-tajweed';
  static const String quranAnalyzeEndpoint = 'https://meek-zeta.vercel.app/api/quran/analyze';

  // ============================================
  // FIREBASE (for Push Notifications)
  // ============================================
  static const String firebaseVapidKey = '';  // Add via Firebase config
  
  // ============================================
  // Helper to set keys at runtime
  // ============================================
  static void setApiKeys({
    String? gemini,
    String? groq,
    String? openai,
  }) {
    if (gemini != null && gemini.isNotEmpty) geminiApiKey = gemini;
    if (groq != null && groq.isNotEmpty) groqApiKey = groq;
    if (openai != null && openai.isNotEmpty) openaiApiKey = openai;
  }
}
