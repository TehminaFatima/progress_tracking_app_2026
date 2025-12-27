# 🚀 Quick Reference - Authentication System

## File Structure
```
lib/auth/
├── models/
│   ├── user_model.dart        # AppUser(id, email, fullName, avatarUrl)
│   └── auth_state.dart        # AuthStatus enum & AuthState class
├── services/
│   ├── auth_service.dart      # signUpWithEmail(), signInWithEmail(), etc.
│   └── auth_provider.dart     # Provider for state management
└── screens/
    ├── splash_screen.dart     # Auto-check session on startup
    ├── login_screen.dart      # Email/password login
    ├── register_screen.dart   # Create account
    └── forgot_password_screen.dart  # Reset password via email
```

---

## Routes Available
```dart
'/splash'            → SplashScreen (startup)
'/login'             → LoginScreen
'/register'          → RegisterScreen
'/forgot-password'   → ForgotPasswordScreen
'/home'              → DashboardScreen (protected)
```

---

## Key Classes

### AuthProvider (State Management)
```dart
// Check if user is logged in
if (authProvider.isAuthenticated) { ... }

// Get current user
final user = authProvider.currentUser;
print(user?.email);

// Sign up
await authProvider.signUp(
  email: 'user@example.com',
  password: 'Pass123',
  fullName: 'John Doe',
);

// Sign in
await authProvider.signIn(
  email: 'user@example.com',
  password: 'Pass123',
);

// Sign out
await authProvider.signOut();

// Reset password
await authProvider.sendPasswordReset('user@example.com');
```

### AppUser (User Model)
```dart
AppUser {
  String id                    // Unique user ID
  String email                 // User email
  String? fullName            // Full name (optional)
  String? avatarUrl           // Avatar URL (optional)
  DateTime createdAt          // Account creation date
  DateTime? lastSignIn        // Last login time
}
```

### AuthState (State Management)
```dart
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  AuthStatus status
  AppUser? user
  String? errorMessage
}
```

---

## Common Usage Patterns

### 1. Check Authentication
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (authProvider.isAuthenticated) {
      return DashboardScreen();
    } else {
      return LoginScreen();
    }
  },
)
```

### 2. Show Loading State
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return ElevatedButton(
      onPressed: authProvider.isLoading ? null : () { ... },
      child: authProvider.isLoading
          ? CircularProgressIndicator()
          : Text('Sign In'),
    );
  },
)
```

### 3. Display Errors
```dart
if (authProvider.errorMessage != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(authProvider.errorMessage!)),
  );
  authProvider.clearError();
}
```

### 4. Auto-Redirect After Auth
```dart
final success = await authProvider.signIn(...);
if (success) {
  Navigator.pushReplacementNamed(context, '/home');
}
```

---

## Password Requirements
- Minimum 6 characters
- No other complexity requirements

---

## Email Validation
- Must contain @ symbol
- Must contain domain (.)
- Standard email format

---

## Validation Functions in Services
```dart
// In AuthService
String _parseSupabaseError(String error)
  → Converts technical errors to user-friendly messages
```

---

## Error Handling
```dart
try {
  await authService.signInWithEmail(...);
} on AuthException catch (e) {
  print('Message: ${e.message}');
  print('Code: ${e.code}');
}
```

---

## Async Operations
All auth methods are Future-based:
- `signUpWithEmail(...)` → Future<AppUser>
- `signInWithEmail(...)` → Future<AppUser>
- `signOut()` → Future<void>
- `sendPasswordResetEmail(...)` → Future<void>
- `updatePassword(...)` → Future<void>

---

## State Listeners
```dart
// Watch auth changes in AuthProvider
authProvider.watchAuthChanges();
// Automatically notifies listeners on auth changes
```

---

## Session Management
- Automatically handled by Supabase SDK
- Persisted on device
- Auto-login on app restart
- Clear on logout

---

## Magic Links
- Used for password reset
- Sent to user's email
- Expires after 24 hours
- Deep link: `io.supabase.flutter://reset-callback/`

---

## Supabase Configuration
Already set up in `lib/main.dart`:
- URL: `https://dewuefrqoczzerectejl.supabase.co`
- Anon Key: `sb_publishable_tmOEMxEpUN-b3Q3OSJUSnQ_If8l3bLL`

---

## Dependencies
```yaml
supabase_flutter: ^2.12.0    # Backend
provider: ^6.0.0              # State management
```

---

## Tips & Tricks

1. **Always use `Consumer` or `Provider.of` to access AuthProvider in UI**
   ```dart
   final authProvider = context.read<AuthProvider>();
   ```

2. **Clear errors after displaying**
   ```dart
   authProvider.clearError();
   ```

3. **Use `pushReplacementNamed` after auth to prevent back navigation**
   ```dart
   Navigator.pushReplacementNamed(context, '/home');
   ```

4. **Check loading state before enabling buttons**
   ```dart
   onPressed: authProvider.isLoading ? null : () { ... }
   ```

5. **Display validation errors immediately**
   ```dart
   validator: (value) => value?.isEmpty ?? true ? 'Required' : null
   ```

---

## Next: Implement Dashboard
Replace the placeholder `DashboardScreen` with your actual:
- Category management
- Progress tracking
- Analytics
- Settings

All protected by authentication! 🎉
