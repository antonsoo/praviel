import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_providers.dart';
import '../../pages/onboarding/auth_choice_screen.dart';
import '../../pages/premium_onboarding_2025.dart';
import '../../services/auth_service.dart';

enum _AccountAction { signIn, signOut, switchAccount, restartOnboarding }

class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAuthenticated = auth.isAuthenticated;
    final displayNameOverride = ref
        .watch(displayNameProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final displayName = displayNameOverride ?? _resolveDisplayName(auth);
    final avatarLabel = _initials(displayName);

    return PopupMenuButton<_AccountAction>(
      tooltip: isAuthenticated ? 'Account menu' : 'Sign in or create account',
      offset: const Offset(0, 12),
      itemBuilder: (context) => _buildMenuItems(isAuthenticated),
      onSelected: (action) =>
          _handleAction(context, ref, action, isAuthenticated),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
        child: isAuthenticated
            ? Text(
                avatarLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : Icon(Icons.person_outline, size: 18, color: colorScheme.primary),
      ),
    );
  }

  List<PopupMenuEntry<_AccountAction>> _buildMenuItems(bool isAuthenticated) {
    if (isAuthenticated) {
      return const [
        PopupMenuItem(
          value: _AccountAction.switchAccount,
          child: ListTile(
            leading: Icon(Icons.switch_account_outlined),
            title: Text('Switch account'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: _AccountAction.restartOnboarding,
          child: ListTile(
            leading: Icon(Icons.replay_circle_filled_outlined),
            title: Text('Restart onboarding'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: _AccountAction.signOut,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign out'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ];
    }
    return const [
      PopupMenuItem(
        value: _AccountAction.signIn,
        child: ListTile(
          leading: Icon(Icons.login),
          title: Text('Sign in or sign up'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
      PopupMenuItem(
        value: _AccountAction.restartOnboarding,
        child: ListTile(
          leading: Icon(Icons.flag_outlined),
          title: Text('Preview onboarding'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    ];
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _AccountAction action,
    bool isAuthenticated,
  ) async {
    switch (action) {
      case _AccountAction.signIn:
        await _launchAuthFlow(context, ref);
        break;
      case _AccountAction.switchAccount:
        if (isAuthenticated) {
          await _signOut(context, ref, silent: true);
          if (!context.mounted) {
            return;
          }
        }
        await _launchAuthFlow(context, ref);
        break;
      case _AccountAction.signOut:
        await _signOut(context, ref);
        break;
      case _AccountAction.restartOnboarding:
        await _restartOnboarding(context, ref);
        break;
    }
  }

  Future<void> _launchAuthFlow(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AuthChoiceScreenWithOnboarding(),
        fullscreenDialog: true,
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => const PremiumOnboarding2025(),
          fullscreenDialog: true,
        ),
      );
    }

    ref.invalidate(progressServiceProvider);
    ref.invalidate(dailyGoalServiceProvider);
    ref.invalidate(displayNameProvider);
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref, {
    bool silent = false,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final auth = ref.read(authServiceProvider);
    await auth.logout();
    ref.invalidate(progressServiceProvider);
    ref.invalidate(dailyGoalServiceProvider);
    ref.invalidate(displayNameProvider);
    if (!silent) {
      messenger?.showSnackBar(const SnackBar(content: Text('Signed out')));
    }
  }

  Future<void> _restartOnboarding(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
    await prefs.remove('has_seen_welcome');

    if (!context.mounted) return;

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const PremiumOnboarding2025(),
        fullscreenDialog: true,
      ),
    );

    ref.invalidate(progressServiceProvider);
    ref.invalidate(dailyGoalServiceProvider);
    ref.invalidate(displayNameProvider);
  }

  String _resolveDisplayName(AuthService auth) {
    final profile = auth.currentUser;
    if (profile == null) {
      return 'Guest';
    }
    final displayName = profile.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final username = profile.username?.trim() ?? '';
    return username.isEmpty ? 'Learner' : username;
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}
