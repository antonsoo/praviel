import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../../app_providers.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Listening exercise with audio playback from backend URLs (or TTS fallback)
class VibrantListeningExercise extends ConsumerStatefulWidget {
  const VibrantListeningExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final ListeningTask task;
  final LessonExerciseHandle handle;

  @override
  ConsumerState<VibrantListeningExercise> createState() =>
      _VibrantListeningExerciseState();
}

class _VibrantListeningExerciseState extends ConsumerState<VibrantListeningExercise> {
  String? _selectedAnswer;
  bool _checked = false;
  bool? _correct;
  bool _isPlayingAudio = false;
  final GlobalKey<ErrorShakeWrapperState> _shakeKey = GlobalKey();
  final List<Widget> _sparkles = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    widget.handle.attach(
      canCheck: () => _selectedAnswer != null,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant VibrantListeningExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _selectedAnswer != null,
        check: _check,
        reset: _reset,
      );
    }
  }

  @override
  void dispose() {
    widget.handle.detach();
    _audioPlayer.dispose();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    if (_selectedAnswer == null) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Select an answer',
      );
    }

    final correct = _selectedAnswer == widget.task.answer;

    setState(() {
      _checked = true;
      _correct = correct;
    });

    if (!correct) {
      _shakeKey.currentState?.shake();
      SoundService.instance.error();
    } else {
      HapticService.success();
      SoundService.instance.success();
      _showSparkles();
    }

    return LessonCheckFeedback(
      correct: correct,
      message: correct
          ? 'Correct!'
          : 'The correct answer is: ${widget.task.answer}',
    );
  }

  void _showSparkles() {
    final sparkle = Positioned(
      left: 0,
      right: 0,
      top: 200,
      child: Center(
        child: StarBurst(
          color: const Color(0xFFFBBF24),
          particleCount: 18,
          size: 130,
        ),
      ),
    );
    setState(() => _sparkles.add(sparkle));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _sparkles.clear());
    });
  }

  void _reset() {
    setState(() {
      _selectedAnswer = null;
      _checked = false;
      _correct = null;
      _sparkles.clear();
    });
    widget.handle.notify();
  }

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
        await controller.speak(widget.task.audioText);
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

    // Use provided options or generate some defaults
    final options = widget.task.options.isNotEmpty
        ? widget.task.options
        : [widget.task.answer];

    return Stack(
      children: [
        ErrorShakeWrapper(
          key: _shakeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              ScaleIn(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: VibrantTheme.heroGradient,
                        borderRadius: BorderRadius.circular(VibrantRadius.sm),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: Text(
                        'Listening Exercise',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VibrantSpacing.md),

              // Instructions
              SlideInFromBottom(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  'Tap the button to hear the audio, then select what you hear:',
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Audio play button
              SlideInFromBottom(
                delay: const Duration(milliseconds: 200),
                child: AnimatedScaleButton(
                  onTap: _isPlayingAudio ? () {} : _playAudio,
                  child: Container(
                    padding: const EdgeInsets.all(VibrantSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: VibrantTheme.heroGradient,
                      borderRadius: BorderRadius.circular(VibrantRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isPlayingAudio
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.volume_up_rounded,
                                  key: ValueKey('icon'),
                                  size: 64,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(height: VibrantSpacing.md),
                        Text(
                          _isPlayingAudio ? 'Playing...' : 'Tap to Listen',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Options
              if (options.isNotEmpty) ...[
                SlideInFromBottom(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'What did you hear?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: VibrantSpacing.md),
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                    child: SlideInFromBottom(
                      delay: Duration(milliseconds: 350 + (index * 50)),
                      child: _buildOptionButton(
                        context,
                        option: option,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                  );
                }),
              ],

              // Feedback
              if (_checked && _correct != null) ...[
                const SizedBox(height: VibrantSpacing.lg),
                ScaleIn(
                  child: InlineFeedback(
                    isCorrect: _correct!,
                    message: _correct!
                        ? 'Excellent listening!'
                        : 'The correct answer is: ${widget.task.answer}',
                  ),
                ),
              ],
            ],
          ),
        ),
        ..._sparkles,
      ],
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required String option,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedAnswer == option;
    final isCorrect = option == widget.task.answer;
    final isDisabled = _checked && !isSelected;

    return AnimatedScaleButton(
      onTap: _checked
          ? () {}
          : () {
              HapticService.light();
              SoundService.instance.tap();
              setState(() {
                _selectedAnswer = option;
              });
              widget.handle.notify();
            },
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.md),
        decoration: BoxDecoration(
          gradient: isSelected && !_checked ? VibrantTheme.heroGradient : null,
          color: isSelected
              ? (_checked
                    ? (_correct == true
                          ? colorScheme.tertiaryContainer
                          : colorScheme.errorContainer)
                    : null)
              : (isDisabled
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surface),
          borderRadius: BorderRadius.circular(VibrantRadius.md),
          border: Border.all(
            color: isSelected
                ? (_checked
                      ? (_correct == true
                            ? colorScheme.tertiary
                            : colorScheme.error)
                      : Colors.transparent)
                : colorScheme.outline,
            width: 2,
          ),
          boxShadow: isSelected && !_checked
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : VibrantShadow.sm(colorScheme),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected && !_checked
                      ? Colors.white
                      : (isDisabled
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                            : colorScheme.onSurface),
                ),
              ),
            ),
            if (_checked && isCorrect)
              Icon(
                Icons.check_circle_rounded,
                color: _correct == true
                    ? colorScheme.tertiary
                    : colorScheme.onTertiaryContainer,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
