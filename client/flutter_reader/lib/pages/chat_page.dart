import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;

import '../app_providers.dart';
import '../models/chat.dart';
import '../services/byok_controller.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/empty_state.dart';
import '../widgets/surface.dart';

enum _ChatStatus { idle, loading, error }

class ChatPage extends frp.ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  frp.ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends frp.ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_DisplayMessage> _messages = [];

  String _selectedPersona = 'athenian_merchant';
  _ChatStatus _status = _ChatStatus.idle;
  String? _errorMessage;

  static const _personas = {
    'athenian_merchant': ('Athenian Merchant', Icons.storefront),
    'spartan_warrior': ('Spartan Warrior', Icons.shield),
    'athenian_philosopher': ('Athenian Philosopher', Icons.psychology),
  };

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _status == _ChatStatus.loading) {
      return;
    }

    final userMessage = _DisplayMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _status = _ChatStatus.loading;
      _errorMessage = null;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final api = ref.read(chatApiProvider);
      final settings = await ref.read(byokControllerProvider.future);

      final context = _messages
          .where((m) => m != userMessage)
          .where((m) => m.translationHelp == null && m.grammarNotes.isEmpty)
          .map((m) => ChatMessage(role: m.role, content: m.content))
          .toList();

      final request = ChatConverseRequest(
        message: text,
        persona: _selectedPersona,
        provider: settings.chatProvider.isEmpty
            ? 'echo'
            : settings.chatProvider,
        model: settings.chatModel,
        context: context.length > 10
            ? context.sublist(context.length - 10)
            : context,
      );

      final response = await api.converse(request, settings);

      if (!mounted) return;

      final botMessage = _DisplayMessage(
        role: 'assistant',
        content: response.reply,
        timestamp: DateTime.now(),
        translationHelp: response.translationHelp,
        grammarNotes: response.grammarNotes,
        providerNote: response.meta.note,
      );

      setState(() {
        _messages.add(botMessage);
        _status = _ChatStatus.idle;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _ChatStatus.error;
        _errorMessage = error.toString();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return Column(
      children: [
        Surface(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: theme.colorScheme.primary),
              SizedBox(width: spacing.sm),
              Text(
                'Persona:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedPersona,
                  isExpanded: true,
                  items: _personas.entries.map((entry) {
                    final (name, icon) = entry.value;
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: spacing.xs),
                          Text(name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPersona = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? EmptyState(
                  type: EmptyStateType.noMessages,
                  title: 'Χαῖρε! (Hello!)',
                  message:
                      'Chat with ancient Greeks to practice conversation\n\nTry: "Πῶς ἔχεις;" (How are you?)',
                  actionLabel: 'Start Chatting',
                  onAction: () {
                    _messageController.text = 'Χαίρε φίλε';
                    HapticService.light();
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 16),
                  itemCount:
                      _messages.length +
                      (_status == _ChatStatus.loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length &&
                        _status == _ChatStatus.loading) {
                      return const TypingIndicator();
                    }
                    final message = _messages[index];
                    final personaIcon = _personas[_selectedPersona]?.$2;
                    return MessageBubble(
                      message: message.content,
                      isUser: message.role == 'user',
                      timestamp: message.timestamp,
                      personaIcon: personaIcon,
                    );
                  },
                ),
        ),
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.md),
            color: theme.colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _errorMessage = null);
                  },
                  child: Text(
                    'Dismiss',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        Surface(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type in Greek...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: _status != _ChatStatus.loading,
                ),
              ),
              SizedBox(width: spacing.sm),
              FilledButton.icon(
                onPressed: _status == _ChatStatus.loading
                    ? null
                    : () {
                        HapticService.medium();
                        _sendMessage();
                      },
                icon: _status == _ChatStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisplayMessage {
  _DisplayMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.translationHelp,
    this.grammarNotes = const [],
    this.providerNote,
  });

  final String role;
  final String content;
  final DateTime timestamp;
  final String? translationHelp;
  final List<String> grammarNotes;
  final String? providerNote;
}
