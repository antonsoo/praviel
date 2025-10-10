import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import '../app_providers.dart';
import '../theme/app_theme.dart';

class TtsPlayButton extends ConsumerStatefulWidget {
  const TtsPlayButton({
    super.key,
    required this.text,
    required this.enabled,
    this.semanticLabel,
  });

  final String text;
  final bool enabled;
  final String? semanticLabel;

  @override
  ConsumerState<TtsPlayButton> createState() => _TtsPlayButtonState();
}

class _TtsPlayButtonState extends ConsumerState<TtsPlayButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final colors = theme.colorScheme;

    final canPlay = widget.text.trim().isNotEmpty;
    final label = typography.label.copyWith(color: colors.onPrimaryContainer);
    final border = BorderRadius.circular(18);
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: _loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colors.onPrimaryContainer,
                ),
              ),
            )
          : Icon(
              Icons.volume_up_rounded,
              key: const ValueKey('icon'),
              size: 18,
              color: colors.onPrimaryContainer,
            ),
    );

    final chip = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: canPlay ? 1 : 0.5,
      child: Material(
        color: colors.primaryContainer,
        borderRadius: border,
        child: InkWell(
          borderRadius: border,
          splashColor: colors.primary.withValues(alpha: 0.12),
          highlightColor: colors.primary.withValues(alpha: 0.1),
          onTap: canPlay && !_loading ? _handlePressed : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                SizedBox(width: spacing.xs),
                Text('Listen', style: label),
              ],
            ),
          ),
        ),
      ),
    );

    final semanticsLabel = widget.semanticLabel ?? 'Play audio';

    return Tooltip(
      message: semanticsLabel,
      child: Semantics(
        button: true,
        enabled: canPlay && !_loading,
        label: semanticsLabel,
        child: chip,
      ),
    );
  }

  String _fallbackMessage(String? note, String providerLabel) {
    if (note == 'tts_failed_fell_back_to_echo') {
      return 'BYOK audio failed; using echo.';
    }
    return 'Fell back to $providerLabel audio.';
  }

  Future<void> _handlePressed() async {
    setState(() => _loading = true);
    final controller = ref.read(ttsControllerProvider);
    try {
      final playback = await controller.speak(widget.text);
      if (!mounted) return;
      if (playback.fellBack) {
        final providerLabel = playback.provider.toUpperCase();
        final message = _fallbackMessage(playback.note, providerLabel);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
