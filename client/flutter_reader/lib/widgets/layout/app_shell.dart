import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// Main app shell with bottom navigation bar
///
/// Provides consistent navigation across all main tabs:
/// - Home (Enhanced gamified home)
/// - Lessons (Lesson list)
/// - Chat (AI tutor)
/// - Reader (Text analysis)
/// - History (Past lessons)
/// - Profile (Stats & achievements)
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _AppBottomNavigationBar(),
    );
  }
}

class _AppBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final selectedIndex = _calculateSelectedIndex(currentLocation);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: 'Lessons',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: 'Chat',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Reader',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith(AppRouter.home)) return 0;
    if (location.startsWith(AppRouter.lessons)) return 1;
    if (location.startsWith(AppRouter.chat)) return 2;
    if (location.startsWith(AppRouter.reader)) return 3;
    if (location.startsWith(AppRouter.history)) return 4;
    if (location.startsWith(AppRouter.profile)) return 5;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.lessons);
        break;
      case 2:
        context.go(AppRouter.chat);
        break;
      case 3:
        context.go(AppRouter.reader);
        break;
      case 4:
        context.go(AppRouter.history);
        break;
      case 5:
        context.go(AppRouter.profile);
        break;
    }
  }
}
