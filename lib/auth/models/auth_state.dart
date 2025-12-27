import 'user_model.dart';

/// Represents different authentication states in the app
enum AppAuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Represents the complete authentication state
class AppAuthState {
  final AppAuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AppAuthState({
    this.status = AppAuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  /// Check if user is authenticated
  bool get isAuthenticated => status == AppAuthStatus.authenticated && user != null;

  /// Check if currently loading
  bool get isLoading => status == AppAuthStatus.loading;

  /// Check if there's an error
  bool get hasError => status == AppAuthStatus.error && errorMessage != null;

  /// Create a copy with modified fields
  AppAuthState copyWith({
    AppAuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'AppAuthState(status: $status, user: ${user?.email}, error: $errorMessage)';
}
