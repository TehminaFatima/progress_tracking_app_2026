import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/auth_state.dart';

/// Custom exception for authentication errors
class CustomAuthException implements Exception {
  final String message;
  final String? code;

  CustomAuthException({required this.message, this.code});

  @override
  String toString() => message;
}

/// Authentication service for Progress_Tracking_App 2026
/// Handles all Supabase authentication operations
class AuthService {
  static final AuthService _instance = AuthService._internal();
  late final SupabaseClient _supabase;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _supabase = Supabase.instance.client;
  }

  /// Get current authenticated user
  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      return AppUser.fromSupabaseUser(user.toJson());
    }
    return null;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Get authentication session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Stream of authentication state changes
  /// Emits whenever user logs in, logs out, or session changes
  Stream<AppAuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user != null) {
        return AppAuthState(
          status: AppAuthStatus.authenticated,
          user: AppUser.fromSupabaseUser(user.toJson()),
        );
      }
      return const AppAuthState(status: AppAuthStatus.unauthenticated);
    });
  }

  /// Sign up with email and password
  /// Minimum password length: 6 characters
  /// Returns the created AppUser
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      if (password.length < 6) {
        throw CustomAuthException(
          message: 'Password must be at least 6 characters long',
          code: 'weak_password',
        );
      }

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName?.trim() ?? '',
        },
      );

      if (response.user == null) {
        throw CustomAuthException(
          message: 'Sign up failed. Please try again.',
          code: 'signup_failed',
        );
      }

      return AppUser.fromSupabaseUser(response.user!.toJson());
    } on CustomAuthException {
      rethrow;
    } catch (e) {
      throw CustomAuthException(
        message: _parseSupabaseError(e.toString()),
        code: 'signup_error',
      );
    }
  }

  /// Sign in with email and password
  /// Remembers session automatically via Supabase
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw CustomAuthException(
          message: 'Invalid email or password',
          code: 'invalid_credentials',
        );
      }

      return AppUser.fromSupabaseUser(response.user!.toJson());
    } on CustomAuthException {
      rethrow;
    } catch (e) {
      throw CustomAuthException(
        message: _parseSupabaseError(e.toString()),
        code: 'signin_error',
      );
    }
  }

  /// Send password reset email with magic link
  /// User receives email with reset link
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );
    } catch (e) {
      throw CustomAuthException(
        message: 'Failed to send reset email. Please try again.',
        code: 'reset_email_error',
      );
    }
  }

  /// Update password using recovery token
  /// Called after user confirms magic link
  Future<void> updatePassword(String newPassword) async {
    try {
      if (newPassword.length < 6) {
        throw CustomAuthException(
          message: 'Password must be at least 6 characters long',
          code: 'weak_password',
        );
      }

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw CustomAuthException(
        message: 'Failed to update password. Please try again.',
        code: 'update_password_error',
      );
    }
  }

  /// Sign out current user
  /// Clears session and invalidates tokens
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw CustomAuthException(
        message: 'Sign out failed. Please try again.',
        code: 'signout_error',
      );
    }
  }

  /// Update user profile information
  /// Updates user metadata in Supabase
  Future<AppUser> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw CustomAuthException(message: 'No authenticated user found.');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName.trim();
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );

      // Fetch updated user
      final updatedUser = _supabase.auth.currentUser;
      if (updatedUser == null) {
        throw CustomAuthException(message: 'Failed to fetch updated user.');
      }

      return AppUser.fromSupabaseUser(updatedUser.toJson());
    } catch (e) {
      throw CustomAuthException(
        message: 'Failed to update profile. Please try again.',
        code: 'update_profile_error',
      );
    }
  }

  /// Verify OTP (One-Time Password)
  /// Used for OTP-based authentication
  Future<AppUser> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email.trim(),
        token: otp,
        type: OtpType.recovery,
      );

      if (response.user == null) {
        throw CustomAuthException(
          message: 'OTP verification failed.',
          code: 'otp_verification_failed',
        );
      }

      return AppUser.fromSupabaseUser(response.user!.toJson());
    } catch (e) {
      throw CustomAuthException(
        message: 'Failed to verify OTP. Please try again.',
        code: 'otp_error',
      );
    }
  }

  /// Get user by ID from Supabase
  /// Used for fetching specific user data
  Future<AppUser?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Parse Supabase error messages to user-friendly text
  String _parseSupabaseError(String error) {
    if (error.contains('User already registered')) {
      return 'This email is already registered. Please sign in instead.';
    } else if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    } else if (error.contains('Email not confirmed')) {
      return 'Please verify your email before signing in.';
    } else if (error.contains('over_email_send_rate_limit')) {
      return 'Too many email requests. Please try again later.';
    }
    return error;
  }
}
