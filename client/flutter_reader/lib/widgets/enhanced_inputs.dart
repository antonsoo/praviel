import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';

/// Enhanced input fields with floating labels and modern styling
/// Provides beautiful, accessible form inputs

/// Floating label text field
class FloatingLabelTextField extends StatefulWidget {
  const FloatingLabelTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.inputFormatters,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<FloatingLabelTextField> createState() => _FloatingLabelTextFieldState();
}

class _FloatingLabelTextFieldState extends State<FloatingLabelTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _labelScale;
  late Animation<Offset> _labelPosition;
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.fast,
    );

    _labelScale = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));

    _labelPosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));

    _focusNode.addListener(_handleFocusChange);
    widget.controller?.addListener(_handleTextChange);

    if (widget.controller?.text.isNotEmpty ?? false) {
      _hasText = true;
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus || _hasText) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handleTextChange() {
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText || _focusNode.hasFocus) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SlideTransition(
              position: _labelPosition,
              child: ScaleTransition(
                scale: _labelScale,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _focusNode.hasFocus
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: _focusNode.hasFocus || _hasText
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: VibrantSpacing.xs),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              borderSide: BorderSide(color: colorScheme.outline, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              borderSide: BorderSide(color: colorScheme.outline, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              borderSide: BorderSide(color: colorScheme.primary, width: 3),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              borderSide: BorderSide(color: colorScheme.error, width: 3),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
        ),
      ],
    );
  }
}

/// Search field with animated icon
class AnimatedSearchField extends StatefulWidget {
  const AnimatedSearchField({
    super.key,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.controller,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;

  @override
  State<AnimatedSearchField> createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<AnimatedSearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.normal,
    );

    _iconRotation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: AnimatedBuilder(
          animation: _iconRotation,
          builder: (context, child) {
            return RotationTransition(
              turns: _iconRotation,
              child: const Icon(Icons.search),
            );
          },
        ),
        suffixIcon: widget.controller?.text.isNotEmpty ?? false
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.controller?.clear();
                  widget.onChanged?.call('');
                },
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VibrantRadius.full),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.lg,
          vertical: VibrantSpacing.md,
        ),
      ),
    );
  }
}

/// Chip input field - for tags/topics
class ChipInputField extends StatefulWidget {
  const ChipInputField({
    super.key,
    required this.label,
    this.chips = const [],
    this.onChipsChanged,
    this.maxChips,
  });

  final String label;
  final List<String> chips;
  final ValueChanged<List<String>>? onChipsChanged;
  final int? maxChips;

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  late List<String> _chips;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chips = List.from(widget.chips);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addChip(String value) {
    if (value.isEmpty) return;
    if (widget.maxChips != null && _chips.length >= widget.maxChips!) return;
    if (_chips.contains(value)) return;

    setState(() {
      _chips.add(value);
      _controller.clear();
    });
    widget.onChipsChanged?.call(_chips);
  }

  void _removeChip(String value) {
    setState(() {
      _chips.remove(value);
    });
    widget.onChipsChanged?.call(_chips);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VibrantSpacing.xs),
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(VibrantRadius.md),
            border: Border.all(color: colorScheme.outline, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_chips.isNotEmpty) ...[
                Wrap(
                  spacing: VibrantSpacing.xs,
                  runSpacing: VibrantSpacing.xs,
                  children: _chips.map((chip) {
                    return Chip(
                      label: Text(chip),
                      onDeleted: () => _removeChip(chip),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      backgroundColor: colorScheme.primaryContainer,
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: VibrantSpacing.xs),
              ],
              TextField(
                controller: _controller,
                onSubmitted: _addChip,
                decoration: InputDecoration(
                  hintText: 'Type and press enter...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.sm,
                    vertical: VibrantSpacing.xs,
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

/// OTP input field - for verification codes
class OTPInputField extends StatefulWidget {
  const OTPInputField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<OTPInputField> createState() => _OTPInputFieldState();
}

class _OTPInputFieldState extends State<OTPInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);

    if (otp.length == widget.length) {
      widget.onCompleted?.call(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 50,
          height: 60,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            onChanged: (value) => _onChanged(index, value),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                borderSide: BorderSide(color: colorScheme.outline, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                borderSide: BorderSide(color: colorScheme.outline, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                borderSide: BorderSide(color: colorScheme.primary, width: 3),
              ),
            ),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      }),
    );
  }
}
