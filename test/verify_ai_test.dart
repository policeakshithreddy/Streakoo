// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:streakoo/config/app_config.dart';
import 'package:streakoo/services/groq_ai_service.dart';

void main() {
  test('Verify Groq API Connection', () async {
    print('\n🚀 Testing Groq API Connection...');
    print('Key configured: ${AppConfig.isApiConfigured}');
    print('Model: ${AppConfig.groqModel}');

    if (!AppConfig.isApiConfigured) {
      fail('API Key not configured!');
    }

    final service = GroqAIService.instance;

    final response = await service.generateResponse(
      systemPrompt: 'You are a test assistant.',
      userPrompt: 'Say "Hello Streakoo!" if you can hear me.',
      maxTokens: 20,
    );

    print('Response: $response');

    if (response != null && response.contains('Streakoo')) {
      print('✅ API Connection Successful!');
    } else {
      fail('❌ API Call Failed or returned unexpected response');
    }
  });
}
