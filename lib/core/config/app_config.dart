import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  
  // Supabase Configuration
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  // Google AI Studio (Gemini) Configuration
  static String get geminiApiKey => dotenv.get('GEMINI_API_KEY', fallback: '');
  static String get geminiModel => dotenv.get('GEMINI_MODEL', fallback: 'gemini-2.5-flash');

}
