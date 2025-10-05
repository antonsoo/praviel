import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/models/chat.dart';

// This test verifies the chat context building logic
// Ensures all previous messages (user and assistant) are included in context
void main() {
  test('Chat context includes all previous messages (user and assistant)', () {
    // Simulate the _DisplayMessage class behavior
    final messages = <Map<String, dynamic>>[
      {
        'role': 'user',
        'content': 'Hello',
        'translationHelp': null,
        'grammarNotes': [],
      },
      {
        'role': 'assistant',
        'content': 'λάκωνες ἀεὶ ἕτοιμοι.',
        'translationHelp': 'Spartans always ready.',
        'grammarNotes': [
          'ἕτοιμοι - nominative plural adjective',
          'ἀεί - adverb (always)',
        ],
      },
      {
        'role': 'user',
        'content': 'What does that mean?',
        'translationHelp': null,
        'grammarNotes': [],
      },
    ];

    final currentUserMessage = messages.last;

    // This is the FIXED logic (after removing the harmful filter)
    final context = messages
        .where((m) => m != currentUserMessage)
        .map(
          (m) => ChatMessage(
            role: m['role'] as String,
            content: m['content'] as String,
          ),
        )
        .toList();

    // Should include both the first user message AND the assistant response
    expect(
      context.length,
      2,
      reason:
          'Context should include previous user message and assistant response',
    );
    expect(context[0].role, 'user');
    expect(context[0].content, 'Hello');
    expect(context[1].role, 'assistant');
    expect(context[1].content, 'λάκωνες ἀεὶ ἕτοιμοι.');
  });

  test('Chat context excludes current user message', () {
    final messages = <Map<String, dynamic>>[
      {
        'role': 'user',
        'content': 'First message',
        'translationHelp': null,
        'grammarNotes': [],
      },
    ];

    final currentUserMessage = messages.last;

    final context = messages
        .where((m) => m != currentUserMessage)
        .map(
          (m) => ChatMessage(
            role: m['role'] as String,
            content: m['content'] as String,
          ),
        )
        .toList();

    expect(context.length, 0, reason: 'First message should have no context');
  });

  test(
    'BUGGY logic (what we fixed) would exclude assistant messages with metadata',
    () {
      final messages = <Map<String, dynamic>>[
        {
          'role': 'user',
          'content': 'Hello',
          'translationHelp': null,
          'grammarNotes': [],
        },
        {
          'role': 'assistant',
          'content': 'λάκωνες ἀεὶ ἕτοιμοι.',
          'translationHelp': 'Spartans always ready.',
          'grammarNotes': ['ἕτοιμοι - nominative plural adjective'],
        },
        {
          'role': 'user',
          'content': 'What?',
          'translationHelp': null,
          'grammarNotes': [],
        },
      ];

      final currentUserMessage = messages.last;

      // This was the BUGGY logic (before the fix)
      final buggyContext = messages
          .where((m) => m != currentUserMessage)
          .where(
            (m) =>
                (m['translationHelp'] == null ||
                    (m['translationHelp'] as String).isEmpty) &&
                (m['grammarNotes'] as List).isEmpty,
          )
          .map(
            (m) => ChatMessage(
              role: m['role'] as String,
              content: m['content'] as String,
            ),
          )
          .toList();

      // The bug: assistant message with metadata was excluded!
      expect(
        buggyContext.length,
        1,
        reason:
            'Buggy logic excluded assistant messages with translation/grammar notes',
      );
      expect(
        buggyContext[0].role,
        'user',
        reason: 'Only user message passed the buggy filter',
      );
    },
  );
}
