# Architecture & Data Flow - Progress_Tracking_App 2026

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  UI Layer (Screens)                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │ │
│  │  │   Splash     │  │    Login     │  │  Register    │    │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │ │
│  │  ┌──────────────┐  ┌──────────────┐                       │ │
│  │  │ForgotPassword│  │  Dashboard   │                       │ │
│  │  └──────────────┘  └──────────────┘                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  State Management Layer                                    │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │         AuthProvider (ChangeNotifier)               │ │ │
│  │  │  - isAuthenticated: bool                            │ │ │
│  │  │  - currentUser: AppUser?                            │ │ │
│  │  │  - state: AuthState                                 │ │ │
│  │  │  - signUp(), signIn(), signOut()                    │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Services Layer                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │           AuthService (Singleton)                   │ │ │
│  │  │  - signUpWithEmail()                                │ │ │
│  │  │  - signInWithEmail()                                │ │ │
│  │  │  - sendPasswordResetEmail()                         │ │ │
│  │  │  - updatePassword()                                 │ │ │
│  │  │  - signOut()                                        │ │ │
│  │  │  - updateProfile()                                 │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Models Layer                                              │ │
│  │  ┌──────────────┐      ┌────────────────────────────────┐ │ │
│  │  │ AppUser      │      │ AuthState + AuthStatus enum    │ │ │
│  │  │ - id         │      │ - status                       │ │ │
│  │  │ - email      │      │ - user                         │ │ │
│  │  │ - fullName   │      │ - errorMessage                 │ │ │
│  │  └──────────────┘      └────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   SUPABASE BACKEND                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Authentication Module                                     │ │
│  │  - User Registration                                       │ │
│  │  - Email/Password Validation                              │ │
│  │  - Session Management                                      │ │
│  │  - Magic Link Generation                                  │ │
│  │  - JWT Token Management                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  PostgreSQL Database                                       │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │ auth.users (Managed by Supabase)                    │ │ │
│  │  │  - id (UUID)                                        │ │ │
│  │  │  - email                                            │ │ │
│  │  │  - encrypted_password                              │ │ │
│  │  │  - created_at                                       │ │ │
│  │  │  - user_metadata (JSON)                            │ │ │
│  │  │    - full_name                                      │ │ │
│  │  │    - avatar_url                                     │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### 1. Sign Up Flow
```
User Input (RegisterScreen)
    ↓
form validation
    ↓
AuthProvider.signUp()
    ↓
AuthService.signUpWithEmail()
    ↓
Supabase.auth.signUpWithPassword()
    ↓
Supabase API
    ↓
Success? ──Yes──→ User created in auth.users
    ↓ No         ↓
Error caught      Session created
    ↓             ↓
Show message   AuthProvider updates state
               ↓
            UI rebuilds (Consumer)
               ↓
            Navigate to Dashboard
```

### 2. Sign In Flow
```
User Input (LoginScreen)
    ↓
form validation
    ↓
AuthProvider.signIn()
    ↓
AuthService.signInWithEmail()
    ↓
Supabase.auth.signInWithPassword()
    ↓
Supabase API (verify credentials)
    ↓
Success? ──Yes──→ JWT token created
    ↓ No         ↓
Error caught      Session persisted
    ↓             ↓
Show message   AuthProvider updates state
               ↓
            UI rebuilds (Consumer)
               ↓
            Navigate to Dashboard
```

### 3. Logout Flow
```
User clicks Logout (Dashboard)
    ↓
Confirmation dialog
    ↓
AuthProvider.signOut()
    ↓
AuthService.signOut()
    ↓
Supabase.auth.signOut()
    ↓
Supabase API (invalidate session)
    ↓
Session cleared locally
    ↓
AuthProvider updates state (unauthenticated)
    ↓
UI rebuilds (Consumer)
    ↓
Navigate to LoginScreen
```

### 4. Password Reset Flow
```
User Input (ForgotPasswordScreen)
    ↓
form validation
    ↓
AuthProvider.sendPasswordReset()
    ↓
AuthService.sendPasswordResetEmail()
    ↓
Supabase.auth.resetPasswordForEmail()
    ↓
Supabase generates magic link
    ↓
Email sent to user
    ↓
User clicks link in email
    ↓
Deep link redirects to app
    ↓
User enters new password
    ↓
AuthService.updatePassword()
    ↓
Supabase updates password
    ↓
Success message
    ↓
Navigate to LoginScreen
    ↓
User signs in with new password
```

### 5. Auto-Login Flow (Session Persistence)
```
App Startup
    ↓
main() initializes Supabase
    ↓
MyApp -> SplashScreen
    ↓
AuthProvider checks session
    ↓
Supabase.auth.currentUser != null?
    ↓
Yes ──→ Load AppUser data
    ↓     ↓
No    AuthProvider.state = authenticated
    ↓     ↓
    │  watchAuthChanges() starts stream
    │     ↓
    └──→ UI routes to appropriate screen
         (Dashboard if logged in, Login if not)
```

---

## State Management Flow

### AuthProvider State Transitions

```
┌─────────────┐
│   INITIAL   │  (App just started)
└──────┬──────┘
       │ check session
       ↓
   ┌────────────────┐
   │  LOADING       │
   └────┬───────┬───┘
        │       │
    Yes │       │ No
        ↓       ↓
    ┌──────────┐  ┌──────────────────┐
    │AUTHENTICATED│  UNAUTHENTICATED  │
    └──────────┘  └──────────────────┘
        │                 │
        │ auth operation  │ auth operation
        ↓                 ↓
    ┌────────────────────────────────┐
    │         LOADING                │
    │  (sign up/in/reset in progress)│
    └────┬──────────────────────┬────┘
         │                      │
     Success                 Failure
         ↓                      ↓
   Updated state           ┌──────────┐
         │                 │  ERROR   │
         │                 └──────────┘
         │                      │
         └──────────────────────┘
              user action
                  ↓
            clear error
                  ↓
              back to prev state
```

---

## Data Structure

### AppUser
```
AppUser {
  id: "uuid-12345"              // From Supabase auth
  email: "user@example.com"      // User's email
  fullName: "John Doe"           // From metadata
  avatarUrl: "https://..."       // Profile picture URL
  createdAt: DateTime(2024...)   // Registration date
  lastSignIn: DateTime(2024...)  // Last login
}
```

### AuthState
```
AuthState {
  status: AuthStatus.authenticated
  user: AppUser { ... }
  errorMessage: null
}
```

### Session (Supabase)
```
{
  access_token: "eyJhbGc..."
  refresh_token: "eyJhbGc..."
  expires_in: 3600
  token_type: "bearer"
  user: {
    id: "uuid-12345"
    email: "user@example.com"
    user_metadata: {
      full_name: "John Doe"
      avatar_url: "https://..."
    }
    created_at: "2024-01-01T00:00:00Z"
    last_sign_in_at: "2024-01-10T12:30:00Z"
  }
}
```

---

## Security Architecture

```
┌─────────────────────────────────────────┐
│   FLUTTER APP (Client)                  │
│   - Passwords never stored locally       │
│   - No sensitive data in shared prefs   │
│   - No hardcoded secrets in code        │
└──────────────┬──────────────────────────┘
               │ HTTPS encrypted
               ↓
┌─────────────────────────────────────────┐
│   SUPABASE (Backend)                    │
│   - Password hashing (bcrypt)           │
│   - JWT token signing                   │
│   - TLS/SSL encryption                  │
│   - Session management                  │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│   DATABASE (PostgreSQL)                 │
│   - Row Level Security (RLS)            │
│   - User isolation                      │
│   - Encrypted at rest                   │
│   - Encrypted password hashes           │
└─────────────────────────────────────────┘
```

---

## Component Responsibilities

### SplashScreen
- Check if user is authenticated
- Show branding/animation
- Auto-route based on auth status

### LoginScreen
- Capture email & password
- Validate input
- Call AuthProvider.signIn()
- Show errors
- Navigate on success

### RegisterScreen
- Capture user details (name, email, password)
- Validate all fields
- Call AuthProvider.signUp()
- Show success message
- Navigate to Dashboard

### ForgotPasswordScreen
- Capture email address
- Call AuthProvider.sendPasswordReset()
- Show confirmation
- Navigate back to Login

### AuthService (Singleton)
- Encapsulates Supabase auth logic
- Provides all auth methods
- Handles error parsing
- Manages auth state stream

### AuthProvider (ChangeNotifier)
- Manages UI state
- Notifies widgets of changes
- Provides auth methods to UI
- Handles loading & error states

### AppUser
- Represents authenticated user
- Converts to/from JSON
- Handles user data mutations

### AuthState
- Immutable state representation
- Tracks current status
- Stores user & error message

---

## Key Interactions

```
┌──────────────────────────────────────┐
│ User interacts with UI (Screen)      │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│ Screen calls AuthProvider method     │
│ context.read<AuthProvider>           │
│   .signIn(email, password)           │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│ AuthProvider updates state to        │
│ LOADING and notifies listeners       │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│ AuthService calls Supabase API       │
│ signInWithPassword()                 │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│ Supabase authenticates user          │
│ Returns user + session               │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│ AuthProvider updates state to        │
│ AUTHENTICATED with AppUser           │
│ Notifies all listeners               │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│ Consumer<AuthProvider> widgets       │
│ rebuild with new state               │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│ Screen navigates to Dashboard        │
└──────────────────────────────────────┘
```

---

## Error Handling Flow

```
User Action
    ↓
Validation ──Fail──→ Show error in UI
    ↓ Pass          (no API call)
    │
API Call to Supabase
    ↓
Success? ──No──→ Catch exception
    ↓ Yes      ↓
    │      Parse error
    │      (convert to user-friendly message)
    │      ↓
    │      Set AuthProvider.errorMessage
    │      ↓
    │      Notify UI listeners
    │      ↓
    │      Consumer rebuilds with error
    │      ↓
    │      Show SnackBar/AlertDialog
    │
    └──→ Update AuthProvider state
         Notify listeners
         UI rebuilds
         Navigate on success
```

---

This architecture ensures:
- ✅ Separation of concerns (UI, State, Services, Models)
- ✅ Testability (services are independent)
- ✅ Maintainability (clear data flow)
- ✅ Security (no secrets in code)
- ✅ Scalability (easy to add features)
