import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../theme/advanced_micro_interactions.dart';
import '../buttons/action_buttons.dart';

/// Modern search bar for 2025 UI standards
/// Animated, glassmorphic, with voice search and filters

class ModernSearchBar extends StatefulWidget {
  const ModernSearchBar({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.onVoiceSearch,
    this.onFilter,
    this.hint = 'Search...',
    this.showVoiceSearch = false,
    this.showFilter = false,
    this.controller,
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVoiceSearch;
  final VoidCallback? onFilter;
  final String hint;
  final bool showVoiceSearch;
  final bool showFilter;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _focusController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _focusController = AnimationController(
      vsync: this,
      duration: VibrantDuration.normal,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _focusController, curve: VibrantCurve.smooth),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _isFocused) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
        if (_focusNode.hasFocus) {
          _focusController.forward();
        } else {
          _focusController.reverse();
        }
      }
    });

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VibrantRadius.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: _isFocused
                  ? colorScheme.surface.withValues(alpha: 0.95)
                  : colorScheme.surfaceContainer.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(VibrantRadius.full),
              border: Border.all(
                color: _isFocused
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: _isFocused ? 2 : 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                const SizedBox(width: VibrantSpacing.lg),
                Icon(
                  Icons.search_rounded,
                  color: _isFocused
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: VibrantSpacing.lg,
                      ),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  AnimatedIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                      AdvancedHaptics.light();
                    },
                    size: 40,
                    iconSize: 20,
                    backgroundColor: Colors.transparent,
                  ),
                if (widget.showVoiceSearch && widget.onVoiceSearch != null)
                  AnimatedIconButton(
                    icon: Icons.mic_rounded,
                    onPressed: () {
                      widget.onVoiceSearch!();
                      AdvancedHaptics.medium();
                    },
                    size: 40,
                    iconSize: 20,
                    backgroundColor: Colors.transparent,
                  ),
                if (widget.showFilter && widget.onFilter != null)
                  AnimatedIconButton(
                    icon: Icons.tune_rounded,
                    onPressed: () {
                      widget.onFilter!();
                      AdvancedHaptics.light();
                    },
                    size: 40,
                    iconSize: 20,
                    backgroundColor: Colors.transparent,
                  ),
                const SizedBox(width: VibrantSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact search bar for smaller spaces
class CompactSearchBar extends StatelessWidget {
  const CompactSearchBar({
    super.key,
    required this.onTap,
    this.hint = 'Search...',
  });

  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        AdvancedHaptics.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.lg,
          vertical: VibrantSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(VibrantRadius.full),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Text(
              hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search suggestions dropdown
class SearchSuggestions extends StatelessWidget {
  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<SearchSuggestion> suggestions;
  final ValueChanged<SearchSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: VibrantSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < suggestions.length; i++)
              SlideInFromBottom(
                delay: Duration(milliseconds: 30 * i),
                child: ListTile(
                  leading: Icon(
                    suggestions[i].icon ?? Icons.search_rounded,
                    color: colorScheme.primary,
                  ),
                  title: Text(suggestions[i].title),
                  subtitle: suggestions[i].subtitle != null
                      ? Text(suggestions[i].subtitle!)
                      : null,
                  onTap: () {
                    AdvancedHaptics.light();
                    onSelected(suggestions[i]);
                  },
                  trailing: suggestions[i].trailing,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SearchSuggestion {
  const SearchSuggestion({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.data,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final dynamic data;
}
