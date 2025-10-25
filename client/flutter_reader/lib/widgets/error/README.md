# Error Boundary Widgets

This directory contains error boundary widgets designed to prevent cascading provider failures and infinite loading states in the Flutter app.

## Available Widgets

### 1. AsyncErrorBoundary

The main widget for handling Riverpod `AsyncValue` states with proper error boundaries.

**Usage:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/error/async_error_boundary.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(myDataProvider);

    return AsyncErrorBoundary<MyData>(
      asyncValue: asyncData,
      builder: (data) => Text(data.title),
      onRetry: () => ref.invalidate(myDataProvider),
    );
  }
}
```

**With extension method:**
```dart
final asyncData = ref.watch(myDataProvider);

return asyncData.toBoundary(
  builder: (data) => MyDataWidget(data),
  onRetry: () => ref.invalidate(myDataProvider),
);
```

### 2. AsyncErrorHandler (Simplified API)

Helper class for common patterns:

```dart
// Simple async value handling
AsyncErrorHandler.handle<User>(
  asyncValue: ref.watch(userProvider),
  builder: (user) => UserProfile(user),
  onRetry: () => ref.invalidate(userProvider),
  loadingMessage: 'Loading user profile...',
)

// List handling with empty state
AsyncErrorHandler.handleList<Item>(
  asyncValue: ref.watch(itemsProvider),
  builder: (items) => ListView(children: items.map(...).toList()),
  emptyState: EmptyStateWidget(
    icon: Icons.inbox,
    title: 'No Items',
    message: 'You don\'t have any items yet.',
  ),
  onRetry: () => ref.invalidate(itemsProvider),
)
```

### 3. RetryButton

A button with loading state for retry operations:

```dart
RetryButton(
  onRetry: () async {
    ref.invalidate(myProvider);
    await ref.read(myProvider.future);
  },
  label: 'Reload Data',
)
```

### 4. EmptyStateWidget

Display empty states when data loads successfully but is empty:

```dart
EmptyStateWidget(
  icon: Icons.inbox_outlined,
  title: 'No Messages',
  message: 'You don\'t have any messages yet.',
  action: FilledButton(
    onPressed: () => Navigator.push(...),
    child: Text('Start Conversation'),
  ),
)
```

### 5. RefreshLoadingOverlay

Show a loading overlay during refresh operations:

```dart
RefreshLoadingOverlay(
  isLoading: ref.watch(isRefreshingProvider),
  child: MyContent(),
)
```

### 6. ShimmerListLoader

Placeholder loading state for lists:

```dart
if (asyncData.isLoading) {
  return ShimmerListLoader(
    itemCount: 5,
    itemHeight: 80,
  );
}
```

### 7. ProviderRefreshIndicator

Pull-to-refresh with provider invalidation:

```dart
ProviderRefreshIndicator(
  onRefresh: () async {
    ref.invalidate(myProvider);
    await ref.read(myProvider.future);
  },
  child: ListView(...),
)
```

### 8. DismissibleErrorBanner

Show a dismissible error banner:

```dart
if (asyncData.hasError) {
  return DismissibleErrorBanner(
    error: asyncData.error!,
    onRetry: () => ref.invalidate(myProvider),
  );
}
```

## Best Practices

### 1. Always Wrap Provider Data

Wrap all provider consumption with error boundaries to prevent UI crashes:

```dart
// ✅ Good
final userData = ref.watch(userProvider);
return AsyncErrorBoundary(
  asyncValue: userData,
  builder: (user) => UserWidget(user),
);

// ❌ Bad (can cause infinite loading or crashes)
final user = ref.watch(userProvider).value!; // Can be null!
return UserWidget(user);
```

### 2. Provide Retry Callbacks

Always provide a retry callback for recoverable errors:

```dart
AsyncErrorBoundary(
  asyncValue: ref.watch(dataProvider),
  builder: (data) => MyWidget(data),
  onRetry: () => ref.invalidate(dataProvider), // Allow retry
);
```

### 3. Handle Multiple Providers

When watching multiple providers, handle each one individually:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(userProvider);
  final settings = ref.watch(settingsProvider);

  // Check for errors first
  if (user.hasError) {
    return AsyncErrorBoundary(asyncValue: user, builder: (_) => SizedBox());
  }
  if (settings.hasError) {
    return AsyncErrorBoundary(asyncValue: settings, builder: (_) => SizedBox());
  }

  // Check for loading
  if (user.isLoading || settings.isLoading) {
    return const CircularProgressIndicator();
  }

  // All loaded successfully
  return MyWidget(user.value!, settings.value!);
}
```

### 4. Use Custom Error Messages

Provide context-specific error messages:

```dart
AsyncErrorBoundary(
  asyncValue: asyncData,
  builder: (data) => MyWidget(data),
  errorBuilder: (error, stackTrace) {
    return Center(
      child: Column(
        children: [
          Text('Failed to load lessons'),
          TextButton(
            onPressed: () => ref.invalidate(lessonsProvider),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  },
);
```

## Preventing Cascading Failures

The error boundaries prevent cascading failures by:

1. **Catching errors at the widget level** - Errors don't propagate up the widget tree
2. **Providing fallback UI** - Users see a helpful error message instead of a crash
3. **Enabling retry** - Users can attempt to recover from transient errors
4. **Preventing infinite loading** - Loading states timeout and show error UI

## Testing Error Boundaries

Test error boundaries by simulating failures:

```dart
// In tests
final testProvider = FutureProvider<String>((ref) async {
  throw Exception('Test error');
});

testWidgets('shows error boundary on failure', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            final data = ref.watch(testProvider);
            return AsyncErrorBoundary(
              asyncValue: data,
              builder: (value) => Text(value),
            );
          },
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Verify error UI is shown
  expect(find.text('Something Went Wrong'), findsOneWidget);
  expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
});
```

## Error Logging

All errors are automatically logged via `ErrorHandler.fromException()`. In production, configure error tracking:

```dart
// In main.dart
ErrorHandler.logError = (error) {
  // Send to Sentry, Firebase Crashlytics, etc.
  Sentry.captureException(error.message, stackTrace: error.stackTrace);
};
```
