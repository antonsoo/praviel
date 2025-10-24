import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Comprehensive empty state widgets for a professional app experience
///
/// Follows Material Design guidelines for empty states:
/// - Clear icon or illustration
/// - Helpful message explaining why it's empty
/// - Action button when applicable
/// - Consistent styling and animations

/// Base empty state widget that other empty states can build upon
class EmptyStateBase extends StatelessWidget {
  const EmptyStateBase({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.illustration,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? illustration;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or illustration
            if (illustration != null)
              illustration!
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: color,
                ),
              ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),

              // Primary action button
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],

            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),

              // Secondary action
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
      ),
    );
  }
}

/// Empty state for when user has no lessons completed
class NoLessonsEmpty extends StatelessWidget {
  const NoLessonsEmpty({
    super.key,
    this.onStartLearning,
  });

  final VoidCallback? onStartLearning;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.school,
      title: 'Start Your Journey',
      message:
          'Begin learning ancient languages and unlock wisdom from the past.',
      actionLabel: 'Start First Lesson',
      onAction: onStartLearning,
      iconColor: Colors.amber,
    );
  }
}

/// Empty state for achievements
class NoAchievementsEmpty extends StatelessWidget {
  const NoAchievementsEmpty({
    super.key,
    this.onStartLearning,
  });

  final VoidCallback? onStartLearning;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.emoji_events,
      title: 'No Achievements Yet',
      message:
          'Complete lessons, build streaks, and master ancient languages to unlock achievements.',
      actionLabel: 'Start Learning',
      onAction: onStartLearning,
      iconColor: Colors.purple,
    );
  }
}

/// Empty state for daily challenges
class NoChallengesEmpty extends StatelessWidget {
  const NoChallengesEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.flag,
      title: 'No Active Challenges',
      message: 'New challenges appear daily. Check back tomorrow!',
      iconColor: Colors.orange,
    );
  }
}

/// Empty state for chat history
class NoChatHistoryEmpty extends StatelessWidget {
  const NoChatHistoryEmpty({
    super.key,
    this.onStartChat,
  });

  final VoidCallback? onStartChat;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.chat_bubble_outline,
      title: 'No Conversations Yet',
      message:
          'Start a chat with our AI tutor to practice and get instant help.',
      actionLabel: 'Start Chat',
      onAction: onStartChat,
      iconColor: Colors.blue,
    );
  }
}

/// Empty state for reading history
class NoReadingHistoryEmpty extends StatelessWidget {
  const NoReadingHistoryEmpty({
    super.key,
    this.onStartReading,
  });

  final VoidCallback? onStartReading;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.auto_stories,
      title: 'No Reading History',
      message:
          'Start reading ancient texts to build your vocabulary and comprehension.',
      actionLabel: 'Browse Texts',
      onAction: onStartReading,
      iconColor: Colors.green,
    );
  }
}

/// Empty state for search results
class NoSearchResultsEmpty extends StatelessWidget {
  const NoSearchResultsEmpty({
    super.key,
    this.searchQuery,
  });

  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: searchQuery != null
          ? 'We couldn\'t find anything matching "$searchQuery".\nTry different keywords or check your spelling.'
          : 'No results found. Try different keywords.',
      iconColor: Colors.grey,
    );
  }
}

/// Empty state for leaderboard
class NoLeaderboardDataEmpty extends StatelessWidget {
  const NoLeaderboardDataEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.leaderboard,
      title: 'Leaderboard Empty',
      message:
          'Be the first to earn XP and appear on the leaderboard!',
      iconColor: Colors.amber,
    );
  }
}

/// Empty state for quests/missions
class NoQuestsEmpty extends StatelessWidget {
  const NoQuestsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.explore,
      title: 'No Active Quests',
      message:
          'Complete lessons to unlock epic quests and earn bonus rewards.',
      iconColor: Colors.deepPurple,
    );
  }
}

/// Empty state for vocabulary/SRS cards
class NoVocabularyEmpty extends StatelessWidget {
  const NoVocabularyEmpty({
    super.key,
    this.onStartLearning,
  });

  final VoidCallback? onStartLearning;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.library_books,
      title: 'No Vocabulary Cards',
      message:
          'Learn new words from lessons to add them to your vocabulary deck.',
      actionLabel: 'Start Learning',
      onAction: onStartLearning,
      iconColor: Colors.teal,
    );
  }
}

/// Empty state for friends/social features
class NoFriendsEmpty extends StatelessWidget {
  const NoFriendsEmpty({
    super.key,
    this.onAddFriends,
  });

  final VoidCallback? onAddFriends;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.people_outline,
      title: 'No Friends Yet',
      message:
          'Connect with fellow language learners to compete and learn together.',
      actionLabel: 'Find Friends',
      onAction: onAddFriends,
      iconColor: Colors.pink,
    );
  }
}

/// Empty state for generic errors
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    this.error,
    this.onRetry,
  });

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.error_outline,
      title: 'Something Went Wrong',
      message: error ?? 'An unexpected error occurred. Please try again.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}

/// Empty state for offline/no connection
class NoConnectionEmpty extends StatelessWidget {
  const NoConnectionEmpty({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.wifi_off,
      title: 'No Internet Connection',
      message:
          'Check your connection and try again. Some features are available offline.',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconColor: Colors.grey,
    );
  }
}

/// Loading state with message
class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({
    super.key,
    this.message = 'Loading...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 400.ms)
        .then()
        .fadeOut(duration: 400.ms);
  }
}

/// Empty state for when user needs to complete onboarding
class OnboardingRequiredEmpty extends StatelessWidget {
  const OnboardingRequiredEmpty({
    super.key,
    this.onStartOnboarding,
  });

  final VoidCallback? onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.flag,
      title: 'Welcome!',
      message:
          'Let\'s get you set up with your learning preferences and goals.',
      actionLabel: 'Get Started',
      onAction: onStartOnboarding,
      iconColor: Colors.blue,
    );
  }
}

/// Empty state for when content is not yet available
class ComingSoonEmpty extends StatelessWidget {
  const ComingSoonEmpty({
    super.key,
    this.featureName = 'This feature',
  });

  final String featureName;

  @override
  Widget build(BuildContext context) {
    return EmptyStateBase(
      icon: Icons.schedule,
      title: 'Coming Soon',
      message: '$featureName is under development and will be available soon!',
      iconColor: Colors.orange,
    );
  }
}
