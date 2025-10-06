import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;
import '../app_providers.dart';
import '../models/chat.dart';
import '../services/byok_controller.dart';
import '../theme/professional_theme.dart';

/// PROFESSIONAL chat interface - clean like iMessage, organized like Slack
/// No cute avatars or gradients - just clear, functional design
class ProChatPage extends frp.ConsumerStatefulWidget {
  const ProChatPage({super.key});

  @override
  frp.ConsumerState<ProChatPage> createState() => _ProChatPageState();
}

enum _ChatStatus { idle, loading, error }

class _ProChatPageState extends frp.ConsumerState<ProChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_DisplayMessage> _messages = [];

  // Limit message history to prevent memory leaks
  static const int _maxMessages = 50;

  String _selectedPersona = 'athenian_merchant';
  _ChatStatus _status = _ChatStatus.idle;
  String? _errorMessage;

  static const _personas = {
    'athenian_merchant': ('Athenian Merchant', Icons.storefront_outlined),
    'spartan_warrior': ('Spartan Warrior', Icons.shield_outlined),
    'athenian_philosopher': ('Athenian Philosopher', Icons.psychology_outlined),
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
      // Trim old messages to prevent memory leak
      if (_messages.length > _maxMessages) {
        _messages.removeRange(0, _messages.length - _maxMessages);
      }
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Chat', style: theme.textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outline,
          ),
        ),
      ),
      body: Column(
        children: [
          // Persona selector
          _buildPersonaSelector(theme, colorScheme),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme, colorScheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ProSpacing.xl,
                      vertical: ProSpacing.lg,
                    ),
                    itemCount: _messages.length +
                        (_status == _ChatStatus.loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length &&
                          _status == _ChatStatus.loading) {
                        return _buildTypingIndicator(theme, colorScheme);
                      }
                      final message = _messages[index];
                      return _buildMessageBubble(
                        theme,
                        colorScheme,
                        message,
                      );
                    },
                  ),
          ),

          // Error banner
          if (_errorMessage != null) _buildErrorBanner(theme, colorScheme),

          // Input
          _buildInputBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPersonaSelector(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(ProSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Conversation with:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: ProSpacing.md),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPersona,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ProSpacing.md,
                  vertical: ProSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ProRadius.md),
                  borderSide: BorderSide(color: colorScheme.outline, width: 1),
                ),
              ),
              items: _personas.entries.map((entry) {
                final (name, icon) = entry.value;
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: colorScheme.primary),
                      const SizedBox(width: ProSpacing.sm),
                      Text(name, style: theme.textTheme.bodyMedium),
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
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: ProSpacing.lg),
            Text(
              'Start a conversation',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: ProSpacing.sm),
            Text(
              'Practice Ancient Greek with historical personas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ThemeData theme,
    ColorScheme colorScheme,
    _DisplayMessage message,
  ) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: ProSpacing.lg),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(theme, colorScheme, false),
            const SizedBox(width: ProSpacing.md),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProSpacing.lg,
                    vertical: ProSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(ProRadius.lg),
                      topRight: const Radius.circular(ProRadius.lg),
                      bottomLeft: Radius.circular(
                        isUser ? ProRadius.lg : ProRadius.sm,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? ProRadius.sm : ProRadius.lg,
                      ),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: colorScheme.outline, width: 1),
                  ),
                  child: Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: ProSpacing.xs),
                Text(
                  _formatTime(message.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: ProSpacing.md),
            _buildAvatar(theme, colorScheme, true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, ColorScheme colorScheme, bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Icon(
        isUser ? Icons.person_outline : _personas[_selectedPersona]!.$2,
        size: 16,
        color: isUser ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProSpacing.lg),
      child: Row(
        children: [
          _buildAvatar(theme, colorScheme, false),
          const SizedBox(width: ProSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ProSpacing.lg,
              vertical: ProSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(ProRadius.lg),
              border: Border.all(color: colorScheme.outline, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(colorScheme, 0),
                const SizedBox(width: 4),
                _buildDot(colorScheme, 1),
                const SizedBox(width: 4),
                _buildDot(colorScheme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(ColorScheme colorScheme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final offset = (value + index * 0.33) % 1.0;
        final opacity = 0.3 + (offset * 0.7);
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {}); // Repeat animation
      },
    );
  }

  Widget _buildErrorBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(ProSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        border: Border(
          top: BorderSide(color: colorScheme.error, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: colorScheme.error,
          ),
          const SizedBox(width: ProSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colorScheme.error),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(ProSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type in Greek...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ProSpacing.lg,
                    vertical: ProSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ProRadius.md),
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: _status != _ChatStatus.loading,
              ),
            ),
            const SizedBox(width: ProSpacing.md),
            FilledButton(
              onPressed: _status == _ChatStatus.loading ? null : _sendMessage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(ProSpacing.md),
                minimumSize: const Size(44, 44),
              ),
              child: _status == _ChatStatus.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
