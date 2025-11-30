import 'env.dart';

class AppConfig {
  // Groq API Configuration
  static const String groqApiKey = Env.groqApiKey;
  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel =
      'llama-3.3-70b-versatile'; // Powerful and versatile model

  // Alternative models you can use:
  // - 'llama-3.3-70b-versatile' (More powerful for complex tasks)
  // - 'llama-3.1-8b-instant' (Fastest for simple tasks)
  // - 'mixtral-8x7b-32768' (Balanced speed and quality)

  // Feature flags
  static const bool useAIForHabitSuggestions = true;
  static const bool useAIForCoaching = true;
  static const bool useAIForMoodAnalysis = true;

  // AI parameters
  static const double aiTemperature = 0.7; // Creativity level (0.0 - 1.0)
  static const int maxTokens = 150; // Max response length (short responses)

  // Check if API is configured
  static bool get isApiConfigured =>
      groqApiKey != 'YOUR_GROQ_API_KEY_HERE' && groqApiKey.isNotEmpty;
}
