import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/premium_gradients.dart';

/// Enhanced chat bubble with premium animations and polish
class EnhancedMessageBubble extends StatefulWidget {
  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.personaIcon,
    this.timestamp,
  });

  final String message;
  final bool isUser;
  final IconData? personaIcon;
  final DateTime? timestamp;

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.2 : -0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: widget.isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space8,
            ),
            child: Row(
              mainAxisAlignment: widget.isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isUser && widget.personaIcon != null) ...[
                  _buildPersonaAvatar(widget.personaIcon!, theme),
                  const SizedBox(width: AppSpacing.space12),
                ],
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.isUser
                          ? PremiumGradients.primaryButton
                          : null,
                      color: widget.isUser
                          ? null
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadius.large),
                        topRight: const Radius.circular(AppRadius.large),
                        bottomLeft: Radius.circular(
                          widget.isUser ? AppRadius.large : AppRadius.small,
                        ),
                        bottomRight: Radius.circular(
                          widget.isUser ? AppRadius.small : AppRadius.large,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isUser
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: widget.isUser
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                        if (widget.timestamp != null) ...[
                          const SizedBox(height: AppSpacing.space4),
                          Text(
                            _formatTime(widget.timestamp!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.isUser
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (widget.isUser) ...[
                  const SizedBox(width: AppSpacing.space12),
                  _buildUserAvatar(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaAvatar(IconData icon, ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: PremiumGradients.secondaryButton,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildUserAvatar(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: PremiumGradients.primaryButton,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Animated typing indicator for bot responses
class EnhancedTypingIndicator extends StatefulWidget {
  const EnhancedTypingIndicator({super.key});

  @override
  State<EnhancedTypingIndicator> createState() =>
      _EnhancedTypingIndicatorState();
}

class _EnhancedTypingIndicatorState extends State<EnhancedTypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );

    // Stagger the animations
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space8,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: PremiumGradients.secondaryButton,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.space12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space20,
              vertical: AppSpacing.space16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => AnimatedBuilder(
                  animation: _controllers[index],
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.4 + (_controllers[index].value * 0.6),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
