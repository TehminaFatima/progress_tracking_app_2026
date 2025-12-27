import 'package:get/get.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// GetX Controller for authentication state management
class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  
  // Observable auth state
  final Rx<AppAuthState> _authState = const AppAuthState().obs;
  
  // Getters
  AppAuthState get authState => _authState.value;
  AppUser? get currentUser => _authState.value.user;
  bool get isAuthenticated => _authState.value.isAuthenticated;
  bool get isLoading => _authState.value.isLoading;
  String? get errorMessage => _authState.value.errorMessage;

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
    checkAuthStatus();
  }

  /// Listen to authentication state changes from Supabase
  void _listenToAuthChanges() {
    _authService.authStateChanges().listen((state) {
      _authState.value = state;
    });
  }

  /// Check current authentication status
  Future<void> checkAuthStatus() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _authState.value = AppAuthState(
          status: AppAuthStatus.authenticated,
          user: user,
        );
      } else {
        _authState.value = const AppAuthState(
          status: AppAuthStatus.unauthenticated,
        );
      }
    } catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _authState.value = const AppAuthState(status: AppAuthStatus.loading);
      
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      _authState.value = AppAuthState(
        status: AppAuthStatus.authenticated,
        user: user,
      );
    } on CustomAuthException catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _authState.value = const AppAuthState(status: AppAuthStatus.loading);
      
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      _authState.value = AppAuthState(
        status: AppAuthStatus.authenticated,
        user: user,
      );
    } on CustomAuthException catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      _authState.value = const AppAuthState(status: AppAuthStatus.loading);
      
      await _authService.sendPasswordResetEmail(email);
      
      _authState.value = const AppAuthState(
        status: AppAuthStatus.unauthenticated,
      );
    } on CustomAuthException catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: 'Failed to send password reset email',
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _authState.value = const AppAuthState(status: AppAuthStatus.loading);
      
      await _authService.signOut();
      
      _authState.value = const AppAuthState(
        status: AppAuthStatus.unauthenticated,
      );
    } on CustomAuthException catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _authState.value = AppAuthState(
        status: AppAuthStatus.error,
        errorMessage: 'Failed to sign out',
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      _authState.value = _authState.value.copyWith(
        status: AppAuthStatus.loading,
      );
      
      final updatedUser = await _authService.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
      );
      
      _authState.value = AppAuthState(
        status: AppAuthStatus.authenticated,
        user: updatedUser,
      );
    } on CustomAuthException catch (e) {
      _authState.value = _authState.value.copyWith(
        status: AppAuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _authState.value = _authState.value.copyWith(
        status: AppAuthStatus.error,
        errorMessage: 'Failed to update profile',
      );
    }
  }

  /// Clear error message
  void clearError() {
    if (_authState.value.status == AppAuthStatus.error) {
      _authState.value = _authState.value.copyWith(
        status: AppAuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }
}
