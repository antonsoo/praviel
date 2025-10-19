import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _realNameController = TextEditingController();
  final _discordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  String? _currentUsername;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
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
      final authService = ref.read(authServiceProvider);
      final headers = await authService.getAuthHeaders();
      final config = ref.read(appConfigProvider);

      final response = await http.get(
        Uri.parse('${config.apiBaseUrl}/api/v1/users/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentUsername = data['username'];
            _currentEmail = data['email'];
            _realNameController.text = data['real_name'] ?? '';
            _discordController.text = data['discord_username'] ?? '';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
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
      final authService = ref.read(authServiceProvider);
      final headers = await authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final config = ref.read(appConfigProvider);

      final response = await http.patch(
        Uri.parse('${config.apiBaseUrl}/api/v1/users/me'),
        headers: headers,
        body: jsonEncode({
          'real_name': _realNameController.text.trim().isEmpty
              ? null
              : _realNameController.text.trim(),
          'discord_username': _discordController.text.trim().isEmpty
              ? null
              : _discordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        HapticService.success();
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _isSaving = false;
        });

        if (mounted) {
          PremiumSnackBar.success(
            context,
            title: 'Profile Updated',
            message: 'Your profile has been updated successfully',
          );
        }

        // Navigate back after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['detail'] ?? 'Failed to update profile';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please try again.';
        _isSaving = false;
      });
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
      body: _isLoading
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
    );
  }
}
