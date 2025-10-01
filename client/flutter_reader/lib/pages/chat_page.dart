import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;

import '../app_providers.dart';
import '../models/chat.dart';
import '../services/byok_controller.dart';
import '../theme/app_theme.dart';
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
          .where((m) => m.translationHelp == null && m.grammarNotes.isEmpty)
          .map((m) => ChatMessage(role: m.role, content: m.content))
          .toList();

      final request = ChatConverseRequest(
        message: text,
        persona: _selectedPersona,
        provider: settings.chatProvider.isEmpty ? 'echo' : settings.chatProvider,
        model: settings.chatModel,
        context: context.length > 10 ? context.sublist(context.length - 10) : context,
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
                          Icon(icon, size: 20, color: theme.colorScheme.primary),
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
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        SizedBox(height: spacing.lg),
                        Text(
                          'Χαῖρε! (Hello!)',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        Text(
                          'Chat with ancient Greeks to practice conversation',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: spacing.md),
                        Container(
                          padding: EdgeInsets.all(spacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Try these:',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: spacing.xs),
                              Text('• Πῶς ἔχεις; (How are you?)', style: theme.textTheme.bodySmall),
                              Text('• Τί ἐστιν; (What is it?)', style: theme.textTheme.bodySmall),
                              Text('• Χαίρε φίλε (Hello friend)', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(spacing.md),
                  itemCount: _messages.length + (_status == _ChatStatus.loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _status == _ChatStatus.loading) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
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
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
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
                onPressed: _status == _ChatStatus.loading ? null : _sendMessage,
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

  Widget _buildMessageBubble(_DisplayMessage message) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final isUser = message.role == 'user';

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: spacing.md),
        child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(width: spacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isUser
                        ? null
                        : Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                  ),
                  child: Text(
                    message.content,
                    style: ReaderTheme.typographyOf(context).greekBody.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (message.translationHelp != null) ...[
                  SizedBox(height: spacing.xs),
                  Container(
                    padding: EdgeInsets.all(spacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.translate,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        SizedBox(width: spacing.xs),
                        Flexible(
                          child: Text(
                            message.translationHelp!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (message.grammarNotes.isNotEmpty) ...[
                  SizedBox(height: spacing.xs),
                  Wrap(
                    spacing: spacing.xs,
                    runSpacing: spacing.xs,
                    children: message.grammarNotes.map((note) {
                      return Chip(
                        label: Text(
                          note,
                          style: theme.textTheme.bodySmall,
                        ),
                        backgroundColor: theme.colorScheme.tertiaryContainer
                            .withValues(alpha: 0.5),
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.xs,
                          vertical: spacing.xs,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: spacing.sm),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(width: spacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: Duration.zero),
                SizedBox(width: 4),
                _TypingDot(delay: const Duration(milliseconds: 200)),
                SizedBox(width: 4),
                _TypingDot(delay: const Duration(milliseconds: 400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});

  final Duration delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
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
