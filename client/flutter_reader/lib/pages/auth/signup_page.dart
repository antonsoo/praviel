import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../../app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_snackbars.dart';

/// Production-grade signup page with password strength indicator and validation
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;
  double _passwordStrength = 0.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();

    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    double strength = 0.0;

    if (password.isEmpty) {
      strength = 0.0;
    } else {
      // Length check
      if (password.length >= 8) strength += 0.2;
      if (password.length >= 12) strength += 0.1;

      // Uppercase
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;

      // Lowercase
      if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;

      // Digits
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;

      // Special characters
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        strength += 0.15;
      }
    }

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
    });
  }

  Color _getPasswordStrengthColor(ThemeData theme) {
    if (_passwordStrength < 0.3) {
      return theme.colorScheme.error;
    } else if (_passwordStrength < 0.6) {
      return Colors.orange;
    } else if (_passwordStrength < 0.8) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }

  String _getPasswordStrengthLabel() {
    if (_passwordStrength == 0.0) return '';
    if (_passwordStrength < 0.3) return 'Weak';
    if (_passwordStrength < 0.6) return 'Fair';
    if (_passwordStrength < 0.8) return 'Good';
    return 'Strong';
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage =
            'Please agree to the Terms of Service and Privacy Policy';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Show success message with premium UI
        HapticService.success();
        PremiumSnackBar.success(
          context,
          title: 'Welcome!',
          message: 'Account created successfully',
        );

        // Navigate to home after brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        });
      }
    } on AuthException catch (e) {
      HapticService.error();
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      HapticService.error();
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.xl),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Text(
                          'Join Us',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: spacing.sm),
                        Text(
                          'Start your journey with ancient languages',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: spacing.xl * 2),

                        // Signup form
                        Card(
                          elevation: 8,
                          shadowColor: theme.colorScheme.shadow.withValues(
                            alpha: 0.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(spacing.xl),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Error message
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: EdgeInsets.all(spacing.md),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: theme.colorScheme.error,
                                            size: 20,
                                          ),
                                          SizedBox(width: spacing.sm),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        theme.colorScheme.error,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: spacing.lg),
                                  ],

                                  // Username field
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      hintText: 'Choose a unique username',
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                    ),
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9_-]'),
                                      ),
                                    ],
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter a username';
                                      }
                                      if (value.length < 3) {
                                        return 'Username must be at least 3 characters';
                                      }
                                      if (value.length > 50) {
                                        return 'Username must be less than 50 characters';
                                      }
                                      if (!RegExp(
                                        r'^[a-zA-Z0-9_-]+$',
                                      ).hasMatch(value)) {
                                        return 'Only letters, numbers, _ and - allowed';
                                      }
                                      return null;
                                    },
                                    enabled: !_isLoading,
                                  ),
                                  SizedBox(height: spacing.lg),

                                  // Email field
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'Enter your email address',
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                      ).hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    enabled: !_isLoading,
                                  ),
                                  SizedBox(height: spacing.lg),

                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Create a strong password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                    ),
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      if (!value.contains(RegExp(r'[A-Z]'))) {
                                        return 'Password must contain an uppercase letter';
                                      }
                                      if (!value.contains(RegExp(r'[a-z]'))) {
                                        return 'Password must contain a lowercase letter';
                                      }
                                      if (!value.contains(RegExp(r'[0-9]'))) {
                                        return 'Password must contain a digit';
                                      }
                                      if (!value.contains(
                                        RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                                      )) {
                                        return 'Password must contain a special character (!@#\$ etc.)';
                                      }
                                      final username = _usernameController.text
                                          .trim()
                                          .toLowerCase();
                                      if (username.isNotEmpty &&
                                          value.toLowerCase().contains(
                                            username,
                                          )) {
                                        return 'Password must not contain your username';
                                      }
                                      return null;
                                    },
                                    enabled: !_isLoading,
                                  ),

                                  // Password strength indicator
                                  if (_passwordController.text.isNotEmpty) ...[
                                    SizedBox(height: spacing.sm),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: _passwordStrength,
                                                  minHeight: 6,
                                                  backgroundColor: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        _getPasswordStrengthColor(
                                                          theme,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: spacing.sm),
                                            Text(
                                              _getPasswordStrengthLabel(),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        _getPasswordStrengthColor(
                                                          theme,
                                                        ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                  SizedBox(height: spacing.lg),

                                  // Confirm password field
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      hintText: 'Re-enter your password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                    ),
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleSignup(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    enabled: !_isLoading,
                                  ),
                                  SizedBox(height: spacing.lg),

                                  // Terms and conditions checkbox
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agreedToTerms,
                                        onChanged: _isLoading
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _agreedToTerms =
                                                      value ?? false;
                                                  _errorMessage = null;
                                                });
                                              },
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _agreedToTerms =
                                                        !_agreedToTerms;
                                                    _errorMessage = null;
                                                  });
                                                },
                                          child: RichText(
                                            text: TextSpan(
                                              style: theme.textTheme.bodySmall,
                                              children: [
                                                const TextSpan(
                                                  text: 'I agree to the ',
                                                ),
                                                TextSpan(
                                                  text: 'Terms of Service',
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing.lg),

                                  // Signup button
                                  FilledButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleSignup,
                                    style: FilledButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: spacing.lg,
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    theme.colorScheme.onPrimary,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Create Account',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.xl),

                        // Login prompt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text(
                                'Log In',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
