import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../theme/advanced_micro_interactions.dart';
import '../widgets/common/premium_cards.dart';
import '../widgets/notifications/toast_notifications.dart';
import '../app_providers.dart';
import '../services/auth_service.dart';

/// Premium login page with 2025 modern design
/// Glassmorphic, animated, beautiful
class PremiumLoginPage extends ConsumerStatefulWidget {
  const PremiumLoginPage({super.key});

  @override
  ConsumerState<PremiumLoginPage> createState() => _PremiumLoginPageState();
}

class _PremiumLoginPageState extends ConsumerState<PremiumLoginPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _backgroundController;
  late Animation<double> _rotationAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      _backgroundController,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await AdvancedHaptics.medium();

    try {
      final authService = ref.read(authServiceProvider);

      // Actually login with real backend
      await authService.login(
        usernameOrEmail: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }

      await AdvancedHaptics.success();

      // Check mounted before using context
      if (!mounted) return;

      ToastNotification.show(
        context: context,
        message: 'Welcome back, ${authService.currentUser?.username ?? ""}!',
        title: 'Login Successful',
        type: ToastType.success,
        duration: const Duration(seconds: 2),
      );

      // Navigate to home page (replace current route to prevent back navigation to login)
      Navigator.of(context).pushReplacementNamed('/home');
    } on AuthException catch (e) {
      // Update loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }

      await AdvancedHaptics.error();

      // Check mounted before using context
      if (!mounted) return;

      ToastNotification.show(
        context: context,
        message: e.message,
        title: 'Login Failed',
        type: ToastType.error,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // Update loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }

      await AdvancedHaptics.error();

      // Check mounted before using context
      if (!mounted) return;

      ToastNotification.show(
        context: context,
        message: 'Network error. Please check your connection and try again.',
        title: 'Connection Error',
        type: ToastType.error,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        colorScheme.primary,
                        colorScheme.secondary,
                        _rotationAnimation.value,
                      )!,
                      Color.lerp(
                        colorScheme.secondary,
                        colorScheme.tertiary,
                        _rotationAnimation.value,
                      )!,
                      Color.lerp(
                        colorScheme.tertiary,
                        colorScheme.primary,
                        _rotationAnimation.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),
          // Floating particles
          const Positioned.fill(
            child: FloatingParticles(particleCount: 20),
          ),
          // Login form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(VibrantSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Title with animation
                      SlideInFromBottom(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          children: [
                            FloatingWidget(
                              offset: 12,
                              child: Container(
                                padding: const EdgeInsets.all(VibrantSpacing.xl),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.3),
                                      Colors.white.withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.xl),
                            Text(
                              'PRAVIEL',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.sm),
                            Text(
                              'Master Ancient Languages',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: VibrantSpacing.xxxl),
                      // Login form card
                      SlideInFromBottom(
                        delay: const Duration(milliseconds: 200),
                        child: GlassCard(
                          blur: 30,
                          opacity: 0.15,
                          borderRadius: VibrantRadius.xxl,
                          padding: const EdgeInsets.all(VibrantSpacing.xxl),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: VibrantSpacing.xl),
                                // Email field
                                _PremiumTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'your@email.com',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: VibrantSpacing.lg),
                                // Password field
                                _PremiumTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: VibrantSpacing.md),
                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      ToastNotification.show(
                                        context: context,
                                        message: 'Password reset coming soon',
                                        type: ToastType.info,
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: VibrantSpacing.xl),
                                // Login button
                                PremiumButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  backgroundColor: Colors.white,
                                  foregroundColor: colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: VibrantSpacing.lg,
                                  ),
                                  borderRadius: VibrantRadius.full,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: VibrantSpacing.sm),
                                            Icon(Icons.arrow_forward_rounded, size: 22),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: VibrantSpacing.xl),
                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: VibrantSpacing.md,
                                      ),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: VibrantSpacing.xl),
                                // Social login buttons
                                _SocialLoginButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  label: 'Continue with Google',
                                  onTap: () {
                                    ToastNotification.show(
                                      context: context,
                                      message: 'Google login coming soon',
                                      type: ToastType.info,
                                    );
                                  },
                                ),
                                const SizedBox(height: VibrantSpacing.md),
                                _SocialLoginButton(
                                  icon: Icons.apple_rounded,
                                  label: 'Continue with Apple',
                                  onTap: () {
                                    ToastNotification.show(
                                      context: context,
                                      message: 'Apple login coming soon',
                                      type: ToastType.info,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: VibrantSpacing.xl),
                      // Sign up link
                      SlideInFromBottom(
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ToastNotification.show(
                                  context: context,
                                  message: 'Sign up coming soon',
                                  type: ToastType.info,
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VibrantSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              borderSide: const BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              borderSide: BorderSide(
                color: Colors.red.shade300,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              borderSide: BorderSide(
                color: Colors.red.shade300,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.lg,
              vertical: VibrantSpacing.lg,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumButton(
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: VibrantSpacing.lg,
      ),
      borderRadius: VibrantRadius.full,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: VibrantSpacing.md),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Floating particles widget for background
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key, this.particleCount = 15});

  final int particleCount;

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize particles
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle.random());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });

  factory _Particle.random() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return _Particle(
      x: (random % 100) / 100.0,
      y: (random % 100) / 100.0,
      size: 2 + (random % 4),
      speed: 0.1 + (random % 5) / 10.0,
      color: Colors.white.withValues(alpha: 0.3 + (random % 40) / 100.0),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width;
      final y = ((particle.y + progress * particle.speed) % 1.0) * size.height;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => true;
}
