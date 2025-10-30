import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../avatar/character_avatar.dart';
import '../effects/confetti_overlay.dart';

/// Welcome screen shown on first app launch
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentStep = 0;
  bool _showConfetti = false;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      emotion: AvatarEmotion.happy,
      title: 'Welcome to\nAncient Greek!',
      description:
          'Learn one of history\'s most beautiful languages through interactive lessons',
      buttonText: 'Let\'s Begin',
    ),
    OnboardingStep(
      emotion: AvatarEmotion.excited,
      title: 'Earn XP & Level Up!',
      description:
          'Complete lessons to earn XP, unlock badges, and level up your skills',
      buttonText: 'Sounds Fun!',
    ),
    OnboardingStep(
      emotion: AvatarEmotion.celebrating,
      title: 'Build Your Streak!',
      description:
          'Learn every day to build a streak and watch your flame grow stronger',
      buttonText: 'I\'m Ready!',
    ),
  ];

  void _nextStep() {
    HapticService.light();
    SoundService.instance.tap();

    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Final step - celebrate and complete
      setState(() {
        _showConfetti = true;
      });

      HapticService.celebrate();
      SoundService.instance.achievement();

      Future.delayed(const Duration(milliseconds: 2000), () {
        widget.onComplete();
      });
    }
  }

  void _skipToEnd() {
    HapticService.light();
    setState(() {
      _currentStep = _steps.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          // Confetti overlay
          if (_showConfetti)
            const ConfettiOverlay(duration: Duration(seconds: 3)),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              child: Column(
                children: [
                  // Skip button
                  if (_currentStep < _steps.length - 1)
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: _skipToEnd,
                        child: const Text('Skip'),
                      ),
                    )
                  else
                    const SizedBox(height: 48),

                  const Spacer(),

                  // Avatar
                  BounceIn(
                    key: ValueKey(_currentStep),
                    child: CharacterAvatar(emotion: step.emotion, size: 140),
                  ),

                  const SizedBox(height: VibrantSpacing.xxl),

                  // Title
                  SlideInFromBottom(
                    key: ValueKey('title_$_currentStep'),
                    child: Text(
                      step.title,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: VibrantSpacing.lg),

                  // Description
                  SlideInFromBottom(
                    key: ValueKey('desc_$_currentStep'),
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      step.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const Spacer(),

                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.xs,
                        ),
                        width: index == _currentStep ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: index == _currentStep
                              ? VibrantTheme.heroGradient
                              : null,
                          color: index == _currentStep
                              ? null
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: VibrantSpacing.xl),

                  // Continue button
                  SlideInFromBottom(
                    key: ValueKey('button_$_currentStep'),
                    delay: const Duration(milliseconds: 200),
                    child: FilledButton(
                      onPressed: _nextStep,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.xxl,
                          vertical: VibrantSpacing.lg,
                        ),
                        minimumSize: const Size(double.infinity, 64),
                      ),
                      child: Text(step.buttonText),
                    ),
                  ),

                  const SizedBox(height: VibrantSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  const OnboardingStep({
    required this.emotion,
    required this.title,
    required this.description,
    required this.buttonText,
  });

  final AvatarEmotion emotion;
  final String title;
  final String description;
  final String buttonText;
}

/// Tutorial tooltip widget
class TutorialTooltip extends StatelessWidget {
  const TutorialTooltip({
    super.key,
    required this.message,
    required this.child,
    this.position = TooltipPosition.bottom,
  });

  final String message;
  final Widget child;
  final TooltipPosition position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: position == TooltipPosition.top ? null : 0,
          bottom: position == TooltipPosition.bottom ? null : 0,
          left: 0,
          right: 0,
          child: BounceIn(
            child: Container(
              margin: EdgeInsets.only(
                top: position == TooltipPosition.bottom ? 80 : 0,
                bottom: position == TooltipPosition.top ? 80 : 0,
              ),
              padding: const EdgeInsets.all(VibrantSpacing.md),
              decoration: BoxDecoration(
                gradient: VibrantTheme.heroGradient,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                boxShadow: VibrantShadow.lg(colorScheme),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Arrow
        Positioned(
          top: position == TooltipPosition.top ? null : 72,
          bottom: position == TooltipPosition.bottom ? null : 72,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(16, 8),
              painter: _ArrowPainter(
                color: const Color(0xFF7C3AED),
                pointsUp: position == TooltipPosition.bottom,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum TooltipPosition { top, bottom }

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color, required this.pointsUp});

  final Color color;
  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointsUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => false;
}
