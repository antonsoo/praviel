import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../pages/auth/login_page.dart';

/// Authentication gate that shows login page if not authenticated
/// or the child widget if authenticated
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({required this.child, this.requireAuth = false, super.key});

  final Widget child;
  final bool requireAuth;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authService = ref.read(authServiceProvider);
    await authService.initialize();

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authService = ref.watch(authServiceProvider);

    // If auth is not required, always show the child (guest mode)
    if (!widget.requireAuth) {
      return widget.child;
    }

    // If auth is required, check authentication status
    if (authService.isAuthenticated) {
      return widget.child;
    } else {
      return const LoginPage();
    }
  }
}
