import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import 'dart:math' as math;

enum PronunciationAccuracy {
  perfect,
  good,
  needsWork,
  poor,
}

class PronunciationWord {
  final String word;
  final String ipa; // International Phonetic Alphabet
  final String audioUrl;
  final String? romanization;
  final String? breakdown; // Syllable breakdown
  final List<String>? tips;

  const PronunciationWord({
    required this.word,
    required this.ipa,
    required this.audioUrl,
    this.romanization,
    this.breakdown,
    this.tips,
  });
}

class PronunciationResult {
  final PronunciationAccuracy accuracy;
  final double score; // 0.0 to 1.0
  final List<String>? feedback;
  final String? audioUrl; // URL of user's recording

  const PronunciationResult({
    required this.accuracy,
    required this.score,
    this.feedback,
    this.audioUrl,
  });
}

/// Professional pronunciation practice with audio playback and recording
class PronunciationPractice extends StatefulWidget {
  const PronunciationPractice({
    super.key,
    required this.word,
    required this.onRecordingComplete,
    this.result,
    this.languageCode = 'lat',
  });

  final PronunciationWord word;
  final Function(String audioPath) onRecordingComplete;
  final PronunciationResult? result;
  final String languageCode;

  @override
  State<PronunciationPractice> createState() => _PronunciationPracticeState();
}

class _PronunciationPracticeState extends State<PronunciationPractice> with TickerProviderStateMixin {
  bool _isPlayingNative = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playNativeAudio() async {
    if (_isPlayingNative) return;

    setState(() => _isPlayingNative = true);
    HapticService.light();
    SoundService.instance.tap();
    _waveController.repeat();

    // TODO: Actually play audio from widget.word.audioUrl
    // For now, simulate playback
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isPlayingNative = false);
    _waveController.reset();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
      });
      _pulseController.reset();
      HapticService.success();
      SoundService.instance.success();

      // TODO: Actually stop recording and save audio
      widget.onRecordingComplete('path/to/recording.wav');
    } else {
      // Start recording
      setState(() => _isRecording = true);
      _pulseController.repeat(reverse: true);
      HapticService.light();
      SoundService.instance.tap();

      // TODO: Actually start recording audio
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Word display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.8),
                colorScheme.tertiaryContainer.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(VibrantRadius.xl),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Native word
              Text(
                widget.word.word,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: VibrantSpacing.md),

              // IPA transcription
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.md,
                  vertical: VibrantSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 16),
                    const SizedBox(width: VibrantSpacing.xs),
                    Text(
                      widget.word.ipa,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'Noto Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Romanization (if available)
              if (widget.word.romanization != null) ...[
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  widget.word.romanization!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Syllable breakdown
              if (widget.word.breakdown != null) ...[
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  widget.word.breakdown!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: VibrantSpacing.xl),

        // Play native audio button
        _AudioButton(
          icon: Icons.volume_up_rounded,
          label: 'Listen to Native Speaker',
          onTap: _playNativeAudio,
          isActive: _isPlayingNative,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
        ),

        const SizedBox(height: VibrantSpacing.md),

        // Waveform visualization (when playing)
        if (_isPlayingNative)
          SizedBox(
            height: 60,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaveformPainter(
                    animation: _waveController,
                    color: Colors.blue,
                  ),
                  size: const Size(double.infinity, 60),
                );
              },
            ),
          ),

        const SizedBox(height: VibrantSpacing.xl),

        // Record button
        GestureDetector(
          onTap: _toggleRecording,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isRecording
                          ? [Colors.red.shade400, Colors.red.shade700]
                          : [colorScheme.primary, colorScheme.tertiary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : colorScheme.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: _isRecording ? 8 : 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: VibrantSpacing.md),

        Text(
          _isRecording ? 'Recording...' : _hasRecorded ? 'Tap to record again' : 'Tap to record',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Result display
        if (widget.result != null) ...[
          const SizedBox(height: VibrantSpacing.xl),
          _ResultCard(result: widget.result!),
        ],

        // Pronunciation tips
        if (widget.word.tips != null && widget.word.tips!.isNotEmpty) ...[
          const SizedBox(height: VibrantSpacing.xl),
          _PronunciationTips(tips: widget.word.tips!),
        ],
      ],
    );
  }
}

/// Audio control button
class _AudioButton extends StatelessWidget {
  const _AudioButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          decoration: BoxDecoration(
            gradient: isActive ? null : gradient,
            color: isActive ? Colors.grey.shade300 : null,
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            boxShadow: isActive
                ? null
                : [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Waveform visualization
class _WaveformPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _WaveformPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barCount = 30;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    for (var i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final phase = (i / barCount + animation.value) * 2 * math.pi;
      final height = (math.sin(phase) * 0.5 + 0.5) * size.height * 0.6;

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}

/// Pronunciation result card
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final PronunciationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getAccuracyColor(result.accuracy).withValues(alpha: 0.2),
            _getAccuracyColor(result.accuracy).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: _getAccuracyColor(result.accuracy),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Accuracy icon and label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getAccuracyIcon(result.accuracy),
                color: _getAccuracyColor(result.accuracy),
                size: 32,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                _getAccuracyLabel(result.accuracy),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: _getAccuracyColor(result.accuracy),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.md),

          // Score percentage
          Text(
            '${(result.score * 100).toInt()}%',
            style: theme.textTheme.displayMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Progress bar
          const SizedBox(height: VibrantSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(VibrantRadius.full),
            child: LinearProgressIndicator(
              value: result.score,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(_getAccuracyColor(result.accuracy)),
            ),
          ),

          // Feedback
          if (result.feedback != null && result.feedback!.isNotEmpty) ...[
            const SizedBox(height: VibrantSpacing.lg),
            ...result.feedback!.map((feedback) {
              return Padding(
                padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                    Expanded(
                      child: Text(
                        feedback,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _getAccuracyColor(PronunciationAccuracy accuracy) {
    switch (accuracy) {
      case PronunciationAccuracy.perfect:
        return Colors.green;
      case PronunciationAccuracy.good:
        return Colors.lightGreen;
      case PronunciationAccuracy.needsWork:
        return Colors.orange;
      case PronunciationAccuracy.poor:
        return Colors.red;
    }
  }

  IconData _getAccuracyIcon(PronunciationAccuracy accuracy) {
    switch (accuracy) {
      case PronunciationAccuracy.perfect:
        return Icons.stars_rounded;
      case PronunciationAccuracy.good:
        return Icons.check_circle_rounded;
      case PronunciationAccuracy.needsWork:
        return Icons.trending_up_rounded;
      case PronunciationAccuracy.poor:
        return Icons.refresh_rounded;
    }
  }

  String _getAccuracyLabel(PronunciationAccuracy accuracy) {
    switch (accuracy) {
      case PronunciationAccuracy.perfect:
        return 'Perfect!';
      case PronunciationAccuracy.good:
        return 'Good!';
      case PronunciationAccuracy.needsWork:
        return 'Needs Work';
      case PronunciationAccuracy.poor:
        return 'Try Again';
    }
  }
}

/// Pronunciation tips section
class _PronunciationTips extends StatelessWidget {
  const _PronunciationTips({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                'Pronunciation Tips',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),
          ...tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
