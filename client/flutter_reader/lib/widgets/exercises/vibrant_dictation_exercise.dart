import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../app_providers.dart';
import 'exercise_control.dart';

/// Dictation exercise with audio playback and text input
class VibrantDictationExercise extends ConsumerStatefulWidget {
  const VibrantDictationExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final DictationTask task;
  final LessonExerciseHandle handle;

  @override
  ConsumerState<VibrantDictationExercise> createState() =>
      _VibrantDictationExerciseState();
}

class _VibrantDictationExerciseState extends ConsumerState<VibrantDictationExercise>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _checked = false;
  bool? _correct;
  bool _isPlayingAudio = false;
  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    widget.handle.attach(
      canCheck: () => _controller.text.trim().isNotEmpty,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _feedbackController.dispose();
    _audioPlayer.dispose();
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    final correct = _controller.text.trim() == widget.task.targetText;
    if (correct) {
      _feedbackController.forward(from: 0);
    }
    setState(() {
      _checked = true;
      _correct = correct;
    });
    return LessonCheckFeedback(
      correct: correct,
      message: correct
          ? 'Perfect spelling! ✍️'
          : 'Correct: ${widget.task.targetText}',
    );
  }

  void _reset() => setState(() {
        _controller.clear();
        _checked = false;
        _correct = null;
        _feedbackController.reset();
      });

  Future<void> _playAudio() async {
    setState(() => _isPlayingAudio = true);
    try {
      // If audio URL is provided, use pre-generated audio from backend
      if (widget.task.audioUrl != null && widget.task.audioUrl!.isNotEmpty) {
        final config = ref.read(appConfigProvider);
        final audioUrl = widget.task.audioUrl!.startsWith('http')
            ? widget.task.audioUrl!
            : '${config.apiBaseUrl}${widget.task.audioUrl}';

        await _audioPlayer.play(UrlSource(audioUrl));
        // Wait for playback to complete
        await _audioPlayer.onPlayerComplete.first;
      } else {
        // Fall back to TTS synthesis if no audio URL provided
        final controller = ref.read(ttsControllerProvider);
        await controller.speak(widget.task.targetText);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio playback error: $error'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideInFromBottom(
      delay: const Duration(milliseconds: 150),
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title with microphone icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.6),
                        colorScheme.secondaryContainer.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Icon(
                    Icons.mic,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    'Write what you hear',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: VibrantSpacing.xl),

            // Audio play button
            Center(
              child: GestureDetector(
                onTap: _isPlayingAudio ? null : _playAudio,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: _isPlayingAudio ? null : VibrantTheme.heroGradient,
                    color: _isPlayingAudio ? colorScheme.surfaceContainerHighest : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isPlayingAudio
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.play_arrow_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                ),
              ),
            ),

            const SizedBox(height: VibrantSpacing.lg),

            // Hint card (if available)
            if (widget.task.hint != null) ...[
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                  border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                    Expanded(
                      child: Text(
                        'Hint: ${widget.task.hint}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VibrantSpacing.md),
            ],

            // Text input field with enhanced styling
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(VibrantRadius.lg),
                boxShadow: [
                  if (_checked && _correct == true)
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  else if (_checked && _correct == false)
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: TextField(
                controller: _controller,
                enabled: !_checked,
                maxLines: 3,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _checked
                      ? (_correct == true
                          ? Colors.green[800]
                          : Colors.red[800])
                      : colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Type here',
                  hintText: 'Listen carefully and type what you hear...',
                  labelStyle: TextStyle(
                    color: _checked
                        ? (_correct == true ? Colors.green : Colors.red)
                        : colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    borderSide: BorderSide(
                      color: _correct == true ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: _checked
                      ? (_correct == true
                          ? Colors.green.withValues(alpha: 0.05)
                          : Colors.red.withValues(alpha: 0.05))
                      : colorScheme.surfaceContainerHighest,
                  suffixIcon: _checked
                      ? Icon(
                          _correct == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _correct == true ? Colors.green : Colors.red,
                          size: 32,
                        )
                      : null,
                  contentPadding: const EdgeInsets.all(VibrantSpacing.lg),
                ),
              ),
            ),

            if (_checked) ...[
              const SizedBox(height: VibrantSpacing.xl),
              _buildFeedback(theme, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(ThemeData theme, ColorScheme colorScheme) {
    return ScaleIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          color: _correct == true
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: _correct == true ? Colors.green : Colors.orange,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _correct == true
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: _correct == true ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    _correct == true
                        ? 'Perfect spelling! ✍️'
                        : 'Not quite right',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _correct == true
                          ? Colors.green[800]
                          : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            if (_correct == false) ...[
              const SizedBox(height: VibrantSpacing.md),
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Row(
                  children: [
                    Text(
                      'Correct: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.task.targetText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
