import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';

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
    final canPlay = widget.text.trim().isNotEmpty;
    return IconButton(
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.volume_up),
      tooltip: widget.semanticLabel ?? 'Play audio',
      onPressed: canPlay && !_loading ? _handlePressed : null,
    );
  }

  Future<void> _handlePressed() async {
    setState(() => _loading = true);
    final controller = ref.read(ttsControllerProvider);
    try {
      final result = await controller.speak(widget.text);
      if (!mounted) return;
      if (result.fellBack) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TTS provider unavailable, using offline audio.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
