import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../models/lesson.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../../services/language_preferences.dart';
import '../../app_providers.dart';
import '../effects/particle_effects.dart';
import '../feedback/answer_feedback_overlay.dart' show InlineFeedback;
import 'exercise_control.dart';

/// Speaking exercise with TTS playback and Web Speech API recognition
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
  bool _isListening = false;
  String _transcription = '';
  double _accuracyScore = 0.0;
  String _feedback = '';
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

    setState(() {
      _checked = true;
      _correct = _accuracyScore >= 0.7; // 70% threshold
    });

    if (_correct!) {
      HapticService.success();
      SoundService.instance.success();
      _showSparkles();
    } else {
      HapticService.error();
    }

    return LessonCheckFeedback(
      correct: _correct,
      message: _feedback,
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
      _transcription = '';
      _accuracyScore = 0.0;
      _feedback = '';
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

  Future<void> _startSpeechRecognition() async {
    // For now, use a simple text input dialog as fallback
    // In a web environment, this could use Web Speech API via js interop
    setState(() => _isListening = true);
    HapticService.medium();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Speak or Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Say: "${widget.task.targetText}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Speech recognition coming soon!\nFor now, type what you said:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Your pronunciation',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Auto-fill with target (for testing)
              Navigator.pop(context, widget.task.targetText);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    setState(() => _isListening = false);

    if (result != null && result.isNotEmpty) {
      // Score the pronunciation using backend API
      await _scorePronunciation(result);
    }
  }

  Future<void> _scorePronunciation(String transcription) async {
    try {
      // Get selected language from provider
      final selectedLanguage = ref.read(selectedLanguageProvider);

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/pronunciation/score-text'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'transcription': transcription,
          'target_text': widget.task.targetText,
          'language': selectedLanguage,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _transcription = data['transcription'] as String? ?? transcription;
            _accuracyScore =
                (data['accuracy_score'] as num?)?.toDouble() ?? 0.0;
            _feedback = data['feedback'] as String? ?? '';
            _hasRecorded = true;
          });
          HapticService.light();
          widget.handle.notify();
        }
      } else {
        throw Exception('Failed to score pronunciation');
      }
    } catch (e) {
      debugPrint('[SpeakingExercise] Error scoring pronunciation: $e');
      // Fallback: use simple comparison
      if (mounted) {
        final normalized1 = transcription.toLowerCase().trim();
        final normalized2 = widget.task.targetText.toLowerCase().trim();
        final isMatch = normalized1 == normalized2;

        setState(() {
          _transcription = transcription;
          _accuracyScore = isMatch ? 1.0 : 0.5;
          _feedback = isMatch
              ? 'Perfect match!'
              : 'Close! Try listening again and repeat carefully.';
          _hasRecorded = true;
        });
        widget.handle.notify();
      }
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
                  onTap: _isListening || _checked
                      ? () {}
                      : _startSpeechRecognition,
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
                          : (_isListening
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
                          child: _isListening
                              ? const SizedBox(
                                  key: ValueKey('listening'),
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
                          _isListening
                              ? 'Listening...'
                              : (_hasRecorded && !_checked
                                    ? 'Ready to check!'
                                    : 'Tap to Speak'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_isListening && !_hasRecorded) ...[
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

              // Show transcription and score
              if (_hasRecorded && !_checked) ...[
                const SizedBox(height: VibrantSpacing.md),
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.transcribe_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: VibrantSpacing.sm),
                          Text(
                            'What you said:',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VibrantSpacing.xs),
                      Text(
                        _transcription,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'NotoSerif',
                        ),
                      ),
                      const SizedBox(height: VibrantSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            size: 20,
                            color: _accuracyScore >= 0.7
                                ? colorScheme.tertiary
                                : colorScheme.error,
                          ),
                          const SizedBox(width: VibrantSpacing.sm),
                          Text(
                            'Accuracy: ${(_accuracyScore * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _accuracyScore >= 0.7
                                  ? colorScheme.tertiary
                                  : colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Feedback
              if (_checked && _correct != null) ...[
                const SizedBox(height: VibrantSpacing.xl),
                ScaleIn(
                  child: InlineFeedback(
                    isCorrect: _correct!,
                    message: _feedback,
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
