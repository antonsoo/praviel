# UI Components Quick Reference

## 🎨 Quick Component Selection Guide

### Loading States

#### When content is loading
```dart
SkeletonList(itemCount: 5)
```

#### When showing progress
```dart
GradientSpinner(size: 48)
ProgressRing(progress: 0.75)
```

#### Full-screen loading
```dart
LoaderOverlay.show(context, message: 'Loading...')
```

### Cards & Containers

#### Basic elevated card
```dart
ElevatedCard(
  child: Text('Content'),
)
```

#### Glowing accent card
```dart
GlowCard(
  gradient: VibrantTheme.heroGradient,
  animated: true,
  child: Text('Featured'),
)
```

#### Glass effect overlay
```dart
GlassCard(
  blur: 15.0,
  child: Text('Glass effect'),
)
```

#### Stat display
```dart
StatCard(
  title: 'XP Total',
  value: '1,250',
  icon: Icons.star,
  trend: true,
  trendValue: '+12%',
)
```

### Buttons

#### Primary action button
```dart
GradientButton(
  gradient: VibrantTheme.heroGradient,
  enableGlow: true,
  onPressed: () {},
  child: Text('Continue'),
)
```

#### Icon with badge
```dart
IconButtonWithBadge(
  icon: Icons.notifications,
  badgeCount: 5,
  onPressed: () {},
)
```

#### Floating action
```dart
ExtendedFAB(
  icon: Icons.add,
  label: 'New Lesson',
  onPressed: () {},
)
```

#### Tab group
```dart
SegmentedButton(
  options: ['Daily', 'Weekly', 'Monthly'],
  selectedIndex: 0,
  onChanged: (index) {},
)
```

### Forms & Inputs

#### Text input
```dart
FloatingLabelTextField(
  label: 'Email',
  hint: 'your@email.com',
  prefixIcon: Icon(Icons.email),
  onChanged: (value) {},
)
```

#### Search field
```dart
AnimatedSearchField(
  hint: 'Search lessons...',
  onChanged: (query) {},
)
```

#### Tag input
```dart
ChipInputField(
  label: 'Topics',
  chips: ['grammar', 'vocab'],
  onChipsChanged: (chips) {},
)
```

#### OTP verification
```dart
OTPInputField(
  length: 6,
  onCompleted: (code) {},
)
```

### Navigation & Transitions

#### Page navigation
```dart
Navigator.push(
  context,
  SlideRightRoute(page: DetailPage()),
)

// Or use custom transition
Navigator.push(
  context,
  CustomPageRoute(
    page: DetailPage(),
    transitionType: PageTransitionType.scale,
  ),
)
```

#### Content switcher
```dart
PageSwitcher(
  transitionType: PageTransitionType.fade,
  child: currentPage,
)
```

### Tooltips & Help

#### Simple tooltip
```dart
EnhancedTooltip(
  message: 'Helpful information',
  child: Icon(Icons.help),
)
```

#### Info button
```dart
InfoButton(
  message: 'Complete lessons daily to build streaks',
)
```

#### Expandable help
```dart
HelpText(
  text: 'Daily Goals',
  helpMessage: 'Set learning targets for each day...',
)
```

### Refresh & Pull-to-Refresh

```dart
CustomRefreshIndicator(
  gradient: VibrantTheme.heroGradient,
  onRefresh: () async {
    await loadData();
  },
  child: ListView(...),
)
```

### Modals & Overlays

#### Bottom sheet
```dart
GlassBottomSheet.show(
  context: context,
  child: SettingsPanel(),
)
```

#### Modal dialog
```dart
GlassModal.show(
  context: context,
  child: ConfirmationDialog(),
)
```

## 🎯 Use Case Matrix

| Need | Component | File |
|------|-----------|------|
| Show loading list | `SkeletonList` | skeleton_loader.dart |
| Show loading card | `SkeletonCard` | skeleton_loader.dart |
| Spinning loader | `GradientSpinner` | loading_indicators.dart |
| Progress bar | `GradientProgressBar` | loading_indicators.dart |
| Progress circle | `ProgressRing` | loading_indicators.dart |
| Primary button | `GradientButton` | enhanced_buttons.dart |
| Soft UI button | `NeumorphicButton` | enhanced_buttons.dart |
| Attention button | `PulseButton` | enhanced_buttons.dart |
| Tabs/Segments | `SegmentedButton` | enhanced_buttons.dart |
| Basic card | `ElevatedCard` | premium_cards.dart |
| Featured card | `GlowCard` | premium_cards.dart |
| Hero banner | `HeroCard` | premium_cards.dart |
| Metric display | `StatCard` | premium_cards.dart |
| Swipe action | `SwipeableCard` | premium_cards.dart |
| Glass overlay | `GlassCard` | glass_morphism.dart |
| Glass modal | `GlassModal` | glass_morphism.dart |
| Glass app bar | `GlassAppBar` | glass_morphism.dart |
| Text input | `FloatingLabelTextField` | enhanced_inputs.dart |
| Search input | `AnimatedSearchField` | enhanced_inputs.dart |
| Tag input | `ChipInputField` | enhanced_inputs.dart |
| OTP input | `OTPInputField` | enhanced_inputs.dart |
| Help icon | `InfoButton` | tooltips.dart |
| Tooltip | `EnhancedTooltip` | tooltips.dart |
| Tutorial tip | `TutorialTooltip` | tooltips.dart |
| Page transition | `SlideRightRoute` | page_transitions.dart |
| Custom transition | `CustomPageRoute` | page_transitions.dart |
| Pull refresh | `CustomRefreshIndicator` | custom_refresh_indicator.dart |

## 🎨 Common Gradients

```dart
VibrantTheme.heroGradient      // Purple → Pink (primary actions)
VibrantTheme.xpGradient        // Amber → Yellow (XP/rewards)
VibrantTheme.successGradient   // Green (success states)
VibrantTheme.streakGradient    // Orange (streaks/fire)
VibrantTheme.subtleGradient    // Light purple (subtle accents)
```

## 📐 Spacing Quick Ref

```dart
VibrantSpacing.xs   // 8px   - tight spacing
VibrantSpacing.sm   // 12px  - compact spacing
VibrantSpacing.md   // 16px  - default spacing
VibrantSpacing.lg   // 24px  - generous spacing
VibrantSpacing.xl   // 32px  - section spacing
VibrantSpacing.xxl  // 48px  - page padding
```

## 🔄 Animation Timing

```dart
VibrantDuration.quick       // 150ms  - micro-interactions
VibrantDuration.fast        // 200ms  - button presses
VibrantDuration.normal      // 300ms  - transitions
VibrantDuration.moderate    // 400ms  - page changes
VibrantDuration.celebration // 1000ms - success animations
```

## 💡 Pro Tips

### Performance
- Use `const` constructors wherever possible
- Skeleton loaders prevent layout shift
- Animations use `vsync` for smooth 60fps

### Accessibility
- All touch targets are 48x48 minimum
- Tooltips provide context for icons
- Color combinations meet contrast requirements

### Consistency
- Always use `VibrantSpacing` constants
- Use `VibrantRadius` for border radius
- Apply `VibrantShadow` helpers for elevation

### Customization
- Most components accept custom gradients
- Colors can be overridden via parameters
- Durations and curves are configurable

## 📱 Responsive Design

Components automatically adapt to screen size:
- Cards use relative sizing
- Buttons have minimum touch targets
- Modals adjust padding based on screen width
- Text scales appropriately

## 🐛 Common Pitfalls

❌ **Don't:**
```dart
// Hard-coded spacing
Padding(padding: EdgeInsets.all(16))

// Hard-coded colors
Color(0xFF7C3AED)

// Magic numbers for timing
Duration(milliseconds: 300)
```

✅ **Do:**
```dart
// Use spacing system
Padding(padding: EdgeInsets.all(VibrantSpacing.md))

// Use theme colors
colorScheme.primary

// Use duration constants
VibrantDuration.normal
```

## 🔍 Finding Components

Search by purpose:
- **Loading?** → `skeleton_loader.dart`, `loading_indicators.dart`
- **Input?** → `enhanced_inputs.dart`
- **Button?** → `enhanced_buttons.dart`
- **Card?** → `premium_cards.dart`, `glass_morphism.dart`
- **Navigation?** → `page_transitions.dart`
- **Help/Guide?** → `tooltips.dart`
- **Refresh?** → `custom_refresh_indicator.dart`
