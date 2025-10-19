import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_cards.dart';
import '../widgets/premium_snackbars.dart';
import '../services/haptic_service.dart';
import 'auth/login_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';

/// User profile page showing account info and settings
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final authService = ref.watch(authServiceProvider);

    if (!authService.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 96,
                  color: theme.colorScheme.outline,
                ),
                SizedBox(height: spacing.xl),
                Text(
                  'Not Logged In',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing.md),
                Text(
                  'Sign in to access your profile, track progress, and sync across devices.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacing.xl * 2),
                PremiumButton(
                  onPressed: () {
                    HapticService.medium();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = authService.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
              HapticService.light();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          children: [
            // Profile header
            GlowCard(
              animated: true,
              padding: EdgeInsets.all(spacing.xl),
              child: Column(
                children: [
                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    Text(
                      user.username,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (user.realName != null) ...[
                      SizedBox(height: spacing.sm),
                      Text(
                        user.realName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    SizedBox(height: spacing.md),
                    Chip(
                      avatar: Icon(
                        user.isActive ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: user.isActive ? Colors.green : Colors.red,
                      ),
                      label: Text(user.isActive ? 'Active' : 'Inactive'),
                    ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Account info
            ElevatedCard(
              elevation: 1.5,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Username'),
                    subtitle: Text(user.username),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: spacing.lg,
                      vertical: spacing.sm,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: spacing.lg,
                      vertical: spacing.sm,
                    ),
                  ),
                  if (user.discordUsername != null) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: const Text('Discord'),
                      subtitle: Text(user.discordUsername!),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: spacing.lg,
                        vertical: spacing.sm,
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Member Since'),
                    subtitle: Text(
                      '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.day.toString().padLeft(2, '0')}',
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: spacing.lg,
                      vertical: spacing.sm,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Action buttons
            ElevatedCard(
              elevation: 1.5,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      HapticService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: spacing.lg,
                      vertical: spacing.sm,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: theme.colorScheme.error),
                    title: Text(
                      'Log Out',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      HapticService.light();
                      _handleLogout(context);
                    },
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: spacing.lg,
                      vertical: spacing.sm,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.xl * 2),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.light();
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              HapticService.medium();
              Navigator.of(dialogContext).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Capture context before async gap
    final currentContext = context;

    final authService = ref.read(authServiceProvider);
    await authService.logout();

    if (mounted) {
      HapticService.success();
      PremiumSnackBar.success(
        currentContext,
        title: 'Logged Out',
        message: 'You have been logged out successfully',
      );
      setState(() {}); // Trigger rebuild to show login prompt
    }
  }
}
