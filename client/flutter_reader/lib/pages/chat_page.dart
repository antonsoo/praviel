import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;

import '../app_providers.dart';
import '../models/chat.dart';
import '../services/byok_controller.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_cards.dart';
import '../widgets/premium_buttons.dart';
import '../widgets/premium_snackbars.dart';

enum _ChatStatus { idle, loading }

class ChatPage extends frp.ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  frp.ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends frp.ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_DisplayMessage> _messages = [];

  String _selectedPersona = 'athenian_merchant';
  _ChatStatus _status = _ChatStatus.idle;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const int _maxMessages = 100;
  static const _personas = {
    'athenian_merchant': ('Athenian Merchant', Icons.storefront),
    'spartan_warrior': ('Spartan Warrior', Icons.shield),
    'athenian_philosopher': ('Athenian Philosopher', Icons.psychology),
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
        // Trim old messages to prevent memory leak
        if (_messages.length > _maxMessages) {
          _messages.removeRange(0, _messages.length - _maxMessages);
        }
        _status = _ChatStatus.idle;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _ChatStatus.idle;
      });
      PremiumSnackBar.error(
        context,
        title: 'Chat Error',
        message: error.toString(),
      );
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
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
        ElevatedCard(
          elevation: 1,
          margin: const EdgeInsets.all(VibrantSpacing.md),
          padding: const EdgeInsets.all(VibrantSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Text(
                'Persona:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.md,
                    vertical: VibrantSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPersona,
                      isExpanded: true,
                      isDense: true,
                      items: _personas.entries.map((entry) {
                        final (name, icon) = entry.value;
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: VibrantSpacing.sm),
                              Text(
                                name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          HapticService.light();
                          setState(() => _selectedPersona = value);
                        }
                      },
                    ),
                  ),
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
        ElevatedCard(
          elevation: 2,
          margin: const EdgeInsets.all(VibrantSpacing.md),
          padding: const EdgeInsets.all(VibrantSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type in Greek...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(VibrantRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: VibrantSpacing.md,
                        vertical: VibrantSpacing.sm,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: _status != _ChatStatus.loading,
                  ),
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              PremiumButton(
                label: 'Send',
                icon: Icons.send_rounded,
                height: 52,
                width: 120,
                onPressed: _status == _ChatStatus.loading
                    ? null
                    : () {
                        HapticService.medium();
                        _sendMessage();
                      },
              ),
            ],
          ),
        ),
      ],
    ),
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
