import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../../app_providers.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Speaking exercise with TTS playback and record button
/// Note: Full speech recognition to be implemented in future version
class VibrantSpeakingExercise extends ConsumerStatefulWidget {
  const VibrantSpeakingExercise({
    super.key,
    required this.task,
    required this.handle,
  });

  final SpeakingTask task;
  final LessonExerciseHandle handle;

  @override
  ConsumerState<VibrantSpeakingExercise> createState() =>
      _VibrantSpeakingExerciseState();
}

class _VibrantSpeakingExerciseState
    extends ConsumerState<VibrantSpeakingExercise> {
  bool _hasRecorded = false;
  bool _checked = false;
  bool? _correct;
  bool _isPlayingAudio = false;
  bool _isRecording = false;
  final GlobalKey<ErrorShakeWrapperState> _shakeKey = GlobalKey();
  final List<Widget> _sparkles = [];

  @override
  void initState() {
    super.initState();
    widget.handle.attach(
      canCheck: () => _hasRecorded,
      check: _check,
      reset: _reset,
    );
  }

  @override
  void didUpdateWidget(covariant VibrantSpeakingExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.handle, widget.handle)) {
      oldWidget.handle.detach();
      widget.handle.attach(
        canCheck: () => _hasRecorded,
        check: _check,
        reset: _reset,
      );
    }
  }

  @override
  void dispose() {
    widget.handle.detach();
    super.dispose();
  }

  LessonCheckFeedback _check() {
    if (!_hasRecorded) {
      return const LessonCheckFeedback(
        correct: null,
        message: 'Record your pronunciation first',
      );
    }

    // For now, always mark as correct since we don't have speech recognition
    // In future: implement actual speech-to-text comparison
    final correct = true;

    setState(() {
      _checked = true;
      _correct = correct;
    });

    HapticService.success();
    SoundService.instance.success();
    _showSparkles();

    return const LessonCheckFeedback(
      correct: true,
      message: 'Great effort! Keep practicing your pronunciation.',
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
      _hasRecorded = false;
      _checked = false;
      _correct = null;
      _sparkles.clear();
    });
    widget.handle.notify();
  }

  Future<void> _playAudio() async {
    setState(() => _isPlayingAudio = true);
    final controller = ref.read(ttsControllerProvider);
    try {
      await controller.speak(widget.task.targetText);
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

  Future<void> _startRecording() async {
    // Simulate recording for now
    // TODO: Implement actual speech recognition in future version
    setState(() => _isRecording = true);
    HapticService.medium();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
      });
      HapticService.light();
      widget.handle.notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.md),
                    Expanded(
                      child: Text(
                        'Speaking Practice',
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
                  widget.task.prompt,
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Target text display
              SlideInFromBottom(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.task.targetText,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFamily: 'NotoSerif',
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.task.phoneticGuide != null) ...[
                        const SizedBox(height: VibrantSpacing.sm),
                        Text(
                          widget.task.phoneticGuide!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: VibrantSpacing.xl),

              // Listen button
              SlideInFromBottom(
                delay: const Duration(milliseconds: 300),
                child: AnimatedScaleButton(
                  onTap: _isPlayingAudio ? () {} : _playAudio,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: VibrantSpacing.md,
                      horizontal: VibrantSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                      boxShadow: VibrantShadow.md(colorScheme),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isPlayingAudio
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.volume_up_rounded,
                                  key: const ValueKey('icon'),
                                  color: colorScheme.onPrimaryContainer,
                                ),
                        ),
                        const SizedBox(width: VibrantSpacing.sm),
                        Text(
                          _isPlayingAudio ? 'Playing...' : 'Listen',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: VibrantSpacing.md),

              // Record button
              SlideInFromBottom(
                delay: const Duration(milliseconds: 350),
                child: AnimatedScaleButton(
                  onTap: _isRecording || _checked ? () {} : _startRecording,
                  child: Container(
                    padding: const EdgeInsets.all(VibrantSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: _hasRecorded && !_checked
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.tertiaryContainer,
                                colorScheme.tertiaryContainer.withValues(
                                  alpha: 0.7,
                                ),
                              ],
                            )
                          : (_isRecording
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.errorContainer,
                                      colorScheme.error.withValues(alpha: 0.3),
                                    ],
                                  )
                                : VibrantTheme.heroGradient),
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
                          child: _isRecording
                              ? const SizedBox(
                                  key: ValueKey('recording'),
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _hasRecorded && !_checked
                                      ? Icons.check_circle_rounded
                                      : Icons.mic_rounded,
                                  key: ValueKey(_hasRecorded ? 'done' : 'mic'),
                                  size: 64,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(height: VibrantSpacing.md),
                        Text(
                          _isRecording
                              ? 'Recording...'
                              : (_hasRecorded && !_checked
                                    ? 'Recorded!'
                                    : 'Tap to Record'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_isRecording && !_hasRecorded) ...[
                          const SizedBox(height: VibrantSpacing.xs),
                          Text(
                            'Say the text above',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Note about speech recognition
              if (!_checked && !_hasRecorded) ...[
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  'Note: Automated pronunciation checking coming soon',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Feedback
              if (_checked && _correct != null) ...[
                const SizedBox(height: VibrantSpacing.xl),
                ScaleIn(
                  child: const InlineFeedback(
                    isCorrect: true,
                    message:
                        'Great effort! Keep practicing your pronunciation.',
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
}
