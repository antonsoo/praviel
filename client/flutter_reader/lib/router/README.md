# GoRouter Navigation System

This directory contains the professional navigation system using GoRouter 14.7.3.

## Status

✅ **Router infrastructure complete** - All routing files are implemented and passing analyzer checks.

⏳ **Integration pending** - Waiting for migration from legacy navigation system.

## Files Created

### 1. `app_router.dart`
Complete router configuration with:
- Declarative routing
- Deep linking support for reader passages
- Type-safe navigation extension methods
- Bottom navigation shell route
- Modal routes for settings, search, achievements, skill tree
- Error page with "Go Home" button

### 2. `../widgets/layout/app_shell.dart`
Main app shell widget with:
- Bottom navigation bar (6 tabs: Home, Lessons, Chat, Reader, History, Profile)
- Automatic selected index based on current route
- Clean separation from route configuration

## Routes Defined

### Main Shell Routes (with bottom nav):
- `/` - Enhanced Home Page (gamified)
- `/lessons` - Lessons Page
- `/chat` - AI Chat/Tutor
- `/reader` - Classic Reader (text analysis)
- `/history` - Lesson History
- `/profile` - Enhanced Profile (stats, achievements, analytics)
- `/social` - Social Leaderboard

### Fullscreen Routes (no bottom nav):
- `/reader/enhanced/:languageCode/:passageId` - Enhanced Reader with passage details
  - Query params: `title`, `reference`, `text`, `translation`

### Modal Routes:
- `/settings` - Settings page
- `/search` - Search library
- `/achievements` - Achievements page
- `/skill-tree` - Skill tree progression

## Type-Safe Navigation

Extension methods on `BuildContext` for type-safe navigation:

```dart
// Navigate to main tabs
context.goHome();
context.goLessons();
context.goChat();
context.goReader();
context.goHistory();
context.goProfile();
context.goSocial();

// Navigate to enhanced reader with passage details
context.goEnhancedReader(
  languageCode: 'grc-cls',
  passageId: 'iliad-1-1',
  title: 'Iliad Book 1',
  reference: '1.1-10',
  text: 'Μῆνιν ἄειδε...',
  translation: 'Sing, goddess, the anger...',
);

// Navigate to modals
context.goSettings();
context.goSearch();
context.goAchievements();
context.goSkillTree();
```

## Migration Path

To migrate from legacy navigation to GoRouter:

### Step 1: Update `main.dart`

```dart
// Change from:
return MaterialApp(
  home: const ReaderHomePage(),
);

// To:
return MaterialApp.router(
  routerConfig: AppRouter.router,
);
```

### Step 2: Remove Legacy Navigation

Remove from `main.dart`:
- `ReaderHomePage` widget
- Manual tab index management
- `IndexedStack` with manual tab switching
- Navigator.push calls

### Step 3: Update Navigation Calls

Replace all `Navigator.push` / `Navigator.pop` with:
- `context.go('/path')` for navigation
- `context.goBack()` for back navigation
- Type-safe extension methods (see above)

### Step 4: Test Deep Linking

Test deep link handling:
```
myapp://reader/enhanced/grc-cls/iliad-1-1?title=Iliad&reference=1.1-10&text=...
```

## Benefits of GoRouter

✅ **Declarative routing** - Routes defined in one place
✅ **Deep linking** - URL-based navigation works automatically
✅ **Type safety** - Extension methods prevent typos
✅ **Shell routes** - Bottom nav persists across routes
✅ **Web support** - Browser URL updates on navigation
✅ **Testability** - Routes can be tested independently

## Current Blocker

The legacy `ReaderHomePage` widget in `main.dart` has complex state management:
- BYOK onboarding flows
- Manual tab index management
- Provider subscriptions for settings
- Integration test mode handling

These need to be refactored before GoRouter can be integrated.

## Next Steps

1. Extract BYOK onboarding logic to separate provider
2. Move tab state management to router
3. Update integration tests to use route paths
4. Migrate `main.dart` to use `MaterialApp.router`
5. Remove legacy `ReaderHomePage` widget
6. Test all navigation flows

## Testing

Router files pass Flutter analyzer:
```bash
cd client/flutter_reader
flutter analyze --no-fatal-infos lib/router/ lib/widgets/layout/app_shell.dart
# Result: No issues found!
```
