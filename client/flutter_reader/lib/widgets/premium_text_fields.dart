import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/vibrant_theme.dart';

/// Premium text field with floating label and smooth animations
class PremiumTextField extends StatefulWidget {
  const PremiumTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _controller;
  late Animation<double> _borderAnimation;
  late Animation<double> _labelAnimation;
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _borderAnimation = Tween<double>(begin: 2.0, end: 3.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _labelAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _controller.forward();
    } else {
      _controller.reverse();
      _validate();
    }
  }

  void _validate() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller?.text);
      setState(() {
        _hasError = error != null;
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderColor = _hasError
        ? colorScheme.error
        : (_isFocused ? colorScheme.primary : colorScheme.outline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                border: Border.all(
                  color: borderColor,
                  width: _borderAnimation.value,
                ),
                color: colorScheme.surface,
                boxShadow: _isFocused && !_hasError
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                maxLines: widget.maxLines,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                inputFormatters: widget.inputFormatters,
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  if (_hasError) _validate();
                },
                onSubmitted: widget.onSubmitted,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: widget.prefixIcon != null ? 16 : 20,
                    vertical: 18,
                  ),
                ),
              ),
            );
          },
        ),
        if (_hasError && _errorText != null) ...[
          const SizedBox(height: VibrantSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: VibrantSpacing.md),
            child: Text(
              _errorText!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Premium search field with animated icon
class PremiumSearchField extends StatefulWidget {
  const PremiumSearchField({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool autofocus;

  @override
  State<PremiumSearchField> createState() => _PremiumSearchFieldState();
}

class _PremiumSearchFieldState extends State<PremiumSearchField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animController;
  late Animation<double> _iconRotation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          prefixIcon: RotationTransition(
            turns: _iconRotation,
            child: Icon(
              Icons.search_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: _clearText,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

/// Glassmorphic input field
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final Function(String)? onChanged;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xs),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: _isFocused ? 0.15 : 0.1),
                Colors.white.withValues(alpha: _isFocused ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(VibrantRadius.md),
            border: Border.all(
              color: _isFocused
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.2),
              width: _isFocused ? 2.0 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.4),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: Colors.white.withValues(alpha: 0.7),
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon != null ? 16 : 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
