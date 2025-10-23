import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

/// Message types for different chat interactions
enum MessageType {
  user,
  assistant,
  system,
  suggestion,
}

/// Message source for context-aware responses
enum MessageContext {
  general,
  translation,
  grammar,
  etymology,
  pronunciation,
  culture,
  reading,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageContext? context;
  final String? languageCode;
  final bool isTyping;
  final List<String>? suggestedFollowUps;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.context,
    this.languageCode,
    this.isTyping = false,
    this.suggestedFollowUps,
  });
}

/// Premium AI tutor chat interface with context-aware responses
class PremiumChatInterface extends StatefulWidget {
  const PremiumChatInterface({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.onSuggestionTap,
    this.currentContext,
    this.languageCode = 'lat',
    this.isLoading = false,
  });

  final List<ChatMessage> messages;
  final Function(String message, MessageContext context) onSendMessage;
  final Function(String suggestion)? onSuggestionTap;
  final MessageContext? currentContext;
  final String languageCode;
  final bool isLoading;

  @override
  State<PremiumChatInterface> createState() => _PremiumChatInterfaceState();
}

class _PremiumChatInterfaceState extends State<PremiumChatInterface> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;
  MessageContext _selectedContext = MessageContext.general;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    if (widget.currentContext != null) {
      _selectedContext = widget.currentContext!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticService.light();
    SoundService.instance.tap();

    widget.onSendMessage(text, _selectedContext);
    _textController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
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

    return Column(
      children: [
        // Context selector
        _ContextSelector(
          selectedContext: _selectedContext,
          onContextChanged: (context) {
            setState(() => _selectedContext = context);
            HapticService.light();
            SoundService.instance.tap();
          },
        ),

        const SizedBox(height: VibrantSpacing.md),

        // Messages list
        Expanded(
          child: widget.messages.isEmpty
              ? _EmptyState(languageCode: widget.languageCode)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.messages[index];
                    return _MessageBubble(
                      message: message,
                      onSuggestionTap: widget.onSuggestionTap,
                      typingAnimation: _typingController,
                    );
                  },
                ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Ask your AI tutor...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(VibrantRadius.xl),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.lg,
                      vertical: VibrantSpacing.md,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: VibrantSpacing.sm),
              // Send button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isLoading ? null : _handleSend,
                  borderRadius: BorderRadius.circular(VibrantRadius.full),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: widget.isLoading
                          ? null
                          : VibrantTheme.heroGradient,
                      color: widget.isLoading
                          ? colorScheme.surfaceContainerHighest
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Context selector for AI tutor specialization
class _ContextSelector extends StatelessWidget {
  const _ContextSelector({
    required this.selectedContext,
    required this.onContextChanged,
  });

  final MessageContext selectedContext;
  final Function(MessageContext) onContextChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.md),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: MessageContext.values.map((context) {
          final isSelected = context == selectedContext;
          return Padding(
            padding: const EdgeInsets.only(right: VibrantSpacing.sm),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onContextChanged(context),
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.md,
                    vertical: VibrantSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? VibrantTheme.heroGradient : null,
                    color: isSelected ? null : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getContextIcon(context),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: VibrantSpacing.xs),
                      Text(
                        _getContextLabel(context),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getContextIcon(MessageContext context) {
    switch (context) {
      case MessageContext.general:
        return Icons.chat_rounded;
      case MessageContext.translation:
        return Icons.translate_rounded;
      case MessageContext.grammar:
        return Icons.auto_stories_rounded;
      case MessageContext.etymology:
        return Icons.history_edu_rounded;
      case MessageContext.pronunciation:
        return Icons.record_voice_over_rounded;
      case MessageContext.culture:
        return Icons.public_rounded;
      case MessageContext.reading:
        return Icons.menu_book_rounded;
    }
  }

  String _getContextLabel(MessageContext context) {
    switch (context) {
      case MessageContext.general:
        return 'General';
      case MessageContext.translation:
        return 'Translation';
      case MessageContext.grammar:
        return 'Grammar';
      case MessageContext.etymology:
        return 'Etymology';
      case MessageContext.pronunciation:
        return 'Pronunciation';
      case MessageContext.culture:
        return 'Culture';
      case MessageContext.reading:
        return 'Reading';
    }
  }
}

/// Message bubble with animations
class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.onSuggestionTap,
    required this.typingAnimation,
  });

  final ChatMessage message;
  final Function(String)? onSuggestionTap;
  final AnimationController typingAnimation;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = widget.message.type == MessageType.user;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _slideController,
        child: Padding(
          padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: VibrantTheme.heroGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.sm),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.md),
                      decoration: BoxDecoration(
                        gradient: isUser ? VibrantTheme.heroGradient : null,
                        color: isUser ? null : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(VibrantRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: isUser
                                ? colorScheme.primary.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: widget.message.isTyping
                          ? _TypingIndicator(animation: widget.typingAnimation)
                          : Text(
                              widget.message.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isUser ? Colors.white : colorScheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                    ),
                    // Suggested follow-ups
                    if (widget.message.suggestedFollowUps != null &&
                        widget.message.suggestedFollowUps!.isNotEmpty) ...[
                      const SizedBox(height: VibrantSpacing.sm),
                      Wrap(
                        spacing: VibrantSpacing.xs,
                        runSpacing: VibrantSpacing.xs,
                        children: widget.message.suggestedFollowUps!.map((suggestion) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onSuggestionTap?.call(suggestion),
                              borderRadius: BorderRadius.circular(VibrantRadius.md),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: VibrantSpacing.sm,
                                  vertical: VibrantSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                                ),
                                child: Text(
                                  suggestion,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: VibrantSpacing.sm),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Typing indicator animation
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.animation});

  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (animation.value + delay) % 1.0;
            final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.3, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Empty state with quick start suggestions
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final suggestions = [
      'Translate "hello" to ${_getLanguageName(languageCode)}',
      'Explain ${_getLanguageName(languageCode)} verb conjugation',
      'What is the etymology of "amor"?',
      'How do I pronounce "καλημέρα"?',
      'Tell me about ancient Roman culture',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: VibrantTheme.heroGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: VibrantSpacing.xl),
            Text(
              'Your AI Tutor is Ready',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'Ask anything about ${_getLanguageName(languageCode)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xl),
            Text(
              'Try asking:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: VibrantSpacing.md),
            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: VibrantSpacing.sm),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'lat':
        return 'Latin';
      case 'grc-cls':
        return 'Classical Greek';
      case 'grc-koi':
        return 'Koine Greek';
      case 'hbo':
        return 'Biblical Hebrew';
      default:
        return 'the language';
    }
  }
}
