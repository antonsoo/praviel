import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../app_providers.dart';
import '../services/haptic_service.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_snackbars.dart';

/// Edit user profile page
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _realNameController = TextEditingController();
  final _discordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  String? _currentUsername;
  String? _currentEmail;
  String _profileVisibility = 'friends';

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
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _realNameController.dispose();
    _discordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final socialApi = ref.read(socialApiProvider);
      final profile = await socialApi.getUserProfile();

      if (mounted) {
        setState(() {
          _currentUsername = profile.username;
          _currentEmail = profile.email;
          _realNameController.text = profile.realName ?? '';
          _discordController.text = profile.discordUsername ?? '';
          _profileVisibility = profile.profileVisibility.toLowerCase();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final socialApi = ref.read(socialApiProvider);
      await socialApi.updateUserProfile(
        realName: _realNameController.text.trim().isEmpty
            ? null
            : _realNameController.text.trim(),
        discordUsername: _discordController.text.trim().isEmpty
            ? null
            : _discordController.text.trim(),
        profileVisibility: _profileVisibility,
      );

      HapticService.success();

      if (mounted) {
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _isSaving = false;
        });

        PremiumSnackBar.success(
          context,
          title: 'Profile Updated',
          message: 'Your profile has been updated successfully',
        );

        // Navigate back after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update profile: ${e.toString()}';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(spacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile picture placeholder
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                radius: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, size: 20),
                                  color: theme.colorScheme.onPrimary,
                                  onPressed: () {
                                    HapticService.light();
                                    PremiumSnackBar.info(
                                      context,
                                      title: 'Coming Soon',
                                      message: 'Photo upload feature is in development',
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: spacing.lg),

                      DropdownButtonFormField<String>(
                        initialValue: _profileVisibility,
                        decoration: InputDecoration(
                          labelText: 'Profile Visibility',
                          prefixIcon: const Icon(Icons.shield_moon_outlined),
                          helperText:
                              'Choose who can view your progress, streaks, and achievements.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'public',
                            child: Text('Public — Anyone can view'),
                          ),
                          DropdownMenuItem(
                            value: 'friends',
                            child: Text('Friends Only — Approved friends'),
                          ),
                          DropdownMenuItem(
                            value: 'private',
                            child: Text('Private — Only you'),
                          ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _profileVisibility = value);
                              },
                      ),

                      SizedBox(height: spacing.xl * 2),

                      // Current username (read-only)
                      if (_currentUsername != null) ...[
                        TextFormField(
                          initialValue: _currentUsername,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            helperText: 'Username cannot be changed',
                          ),
                          enabled: false,
                        ),
                        SizedBox(height: spacing.lg),
                      ],

                      // Current email (read-only)
                      if (_currentEmail != null) ...[
                        TextFormField(
                          initialValue: _currentEmail,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            helperText: 'Email cannot be changed',
                          ),
                          enabled: false,
                        ),
                        SizedBox(height: spacing.lg),
                      ],

                      // Success message
                      if (_successMessage != null) ...[
                        Container(
                          padding: EdgeInsets.all(spacing.md),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              SizedBox(width: spacing.sm),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing.lg),
                      ],

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
                              ),
                              SizedBox(width: spacing.sm),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing.lg),
                      ],

                      // Real name field
                      TextFormField(
                        controller: _realNameController,
                        decoration: InputDecoration(
                          labelText: 'Real Name (optional)',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        enabled: !_isSaving,
                      ),
                      SizedBox(height: spacing.lg),

                      // Discord username field
                      TextFormField(
                        controller: _discordController,
                        decoration: InputDecoration(
                          labelText: 'Discord Username (optional)',
                          prefixIcon: const Icon(Icons.chat_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        enabled: !_isSaving,
                      ),
                      SizedBox(height: spacing.xl * 2),

                      // Save button
                      PremiumButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                HapticService.medium();
                                _handleSave();
                              },
                        height: 56,
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
