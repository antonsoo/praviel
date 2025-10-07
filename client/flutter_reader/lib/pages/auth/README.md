# Authentication UI Pages

This directory contains the production-grade authentication UI for the Ancient Languages app.

## Files

- **login_page.dart** - Beautiful login screen with animations
- **signup_page.dart** - Sign up with password strength indicator
- **forgot_password_page.dart** - Password reset flow with step-by-step guidance

## Features

### Login Page
- Animated entry (fade + slide)
- Username or email input
- Password with show/hide toggle
- Form validation
- Error display
- "Forgot password" link
- "Sign up" navigation
- "Continue as guest" option

### Signup Page
- All login features plus:
- Real-time password strength indicator
- Color-coded strength feedback (weak → strong)
- Password confirmation
- Terms & privacy policy checkbox
- Username validation (alphanumeric + _ -)
- Email validation

### Forgot Password Page
- Email input with validation
- Success state with next steps
- Animated feedback
- Resend option
- Back to login navigation

## Usage

### Navigate to Login
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const LoginPage()),
);
```

### Navigate to Signup (from Login)
The login page has a "Sign Up" button that navigates to signup.

### Navigate to Password Reset (from Login)
The login page has a "Forgot password?" link that navigates to reset.

## Styling

All pages use:
- Material Design 3
- Gradient backgrounds
- Smooth animations
- Responsive layouts (max width 440px for forms)
- Theme-aware colors
- Professional shadows and elevations

## Integration

These pages integrate with [AuthService](../../services/auth_service.dart):

```dart
final authService = ref.read(authServiceProvider);

// From login page
await authService.login(
  usernameOrEmail: username,
  password: password,
);

// From signup page
await authService.register(
  username: username,
  email: email,
  password: password,
);
```

## Backend API

These pages call:
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/password-reset/request`

See [docs/AUTHENTICATION.md](../../../../../docs/AUTHENTICATION.md) for complete API documentation.

## Customization

To customize:

1. **Colors:** Edit gradient colors in each page
2. **Validation:** Modify validators in form fields
3. **Animations:** Adjust duration/curves in initState
4. **Requirements:** Change password rules in signup validation

## Future Enhancements

- Social login buttons (Google, Apple, Facebook)
- Biometric authentication option
- "Remember me" checkbox
- Auto-fill support
- Email verification step
- 2FA code input
