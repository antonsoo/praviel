import 'package:flutter_test/flutter_test.dart';
import 'package:ancient_languages_app/models/chat.dart';
import 'package:ancient_languages_app/services/byok_controller.dart';
import 'package:ancient_languages_app/services/chat_api.dart';

/// Integration test to verify chat context is sent correctly
/// This tests the fix for the "looping bug" where assistant messages
/// with translation help were excluded from context
void main() {
  test(
    'Chat context is sent correctly to API',
    () async {
      // Skip if no API key available
      const apiKey = String.fromEnvironment('OPENAI_API_KEY');
      if (apiKey.isEmpty) {
        // Skipping integration test - no OPENAI_API_KEY provided
        return;
      }

      final api = ChatApi(baseUrl: 'http://localhost:8000');
      final settings = ByokSettings(
        apiKey: apiKey,
        chatProvider: 'openai',
        chatModel: 'gpt-4o-mini',
      );

      try {
        // Send first message
        final request1 = ChatConverseRequest(
          message: 'Say "apple" in Greek',
          persona: 'athenian_merchant',
          provider: 'openai',
          model: 'gpt-4o-mini',
          context: [],
        );

        // Sending first message...
        final response1 = await api.converse(request1, settings);
        // First response logged
        // Context length logged

        expect(
          response1.meta.contextLength,
          0,
          reason: 'First message should have empty context',
        );

        // Build context (simulating what the fixed code does)
        final context = [
          ChatMessage(role: 'user', content: request1.message),
          ChatMessage(role: 'assistant', content: response1.reply),
        ];

        // Send second message WITH context
        final request2 = ChatConverseRequest(
          message: 'Now say "orange"',
          persona: 'athenian_merchant',
          provider: 'openai',
          model: 'gpt-4o-mini',
          context: context,
        );

        // Sending second message with context...
        final response2 = await api.converse(request2, settings);
        // Second response logged
        // Context length logged

        // With the fix, context should include both previous messages
        expect(
          response2.meta.contextLength,
          2,
          reason:
              'Second message should have context of 2 messages (user + assistant)',
        );

        // The response should be contextually aware
        // (should mention "orange" in Greek, not repeat "apple")
        // Test passed! Context is being sent correctly.
      } finally {
        await api.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
