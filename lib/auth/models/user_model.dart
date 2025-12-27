/// User model representing a Progress_Tracking_App 2026 user
class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastSignIn;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
    this.lastSignIn,
  });

  /// Convert AppUser to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in': lastSignIn?.toIso8601String(),
    };
  }

  /// Create AppUser from Supabase user data
  factory AppUser.fromSupabaseUser(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      fullName: data['user_metadata']?['full_name'] as String?,
      avatarUrl: data['user_metadata']?['avatar_url'] as String?,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
      lastSignIn: data['last_sign_in_at'] != null
          ? DateTime.parse(data['last_sign_in_at'] as String)
          : null,
    );
  }

  /// Create AppUser from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastSignIn: json['last_sign_in'] != null
          ? DateTime.parse(json['last_sign_in'] as String)
          : null,
    );
  }

  /// Create a copy of AppUser with modified fields
  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastSignIn,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }

  @override
  String toString() =>
      'AppUser(id: $id, email: $email, fullName: $fullName, createdAt: $createdAt)';
}
