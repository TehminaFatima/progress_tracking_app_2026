import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

/// Custom exception for category operations
class CategoryException implements Exception {
  final String message;
  final String? code;

  CategoryException({required this.message, this.code});

  @override
  String toString() => message;
}

/// Service for handling all category CRUD operations
class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  late final SupabaseClient _supabase;

  factory CategoryService() {
    return _instance;
  }

  CategoryService._internal() {
    _supabase = Supabase.instance.client;
  }

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch all categories for current user
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw CategoryException(
          message: 'No authenticated user found',
          code: 'no_user',
        );
      }

      final response = await _supabase
          .from('categories')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw CategoryException(
        message: 'Failed to fetch categories: ${e.toString()}',
        code: 'fetch_error',
      );
    }
  }

  /// Create a new category
  Future<CategoryModel> createCategory({
    required String name,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw CategoryException(
          message: 'No authenticated user found',
          code: 'no_user',
        );
      }

      final response = await _supabase.from('categories').insert({
        'user_id': userId,
        'name': name,
      }).select().single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      throw CategoryException(
        message: 'Failed to create category: ${e.toString()}',
        code: 'create_error',
      );
    }
  }

  /// Update an existing category
  Future<CategoryModel> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw CategoryException(
          message: 'No authenticated user found',
          code: 'no_user',
        );
      }

      final response = await _supabase
          .from('categories')
          .update({
            'name': name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoryId)
          .eq('user_id', userId) // Ensure user owns this category
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      throw CategoryException(
        message: 'Failed to update category: ${e.toString()}',
        code: 'update_error',
      );
    }
  }

  /// Delete a category
  /// Note: Cascade delete should be configured in Supabase database
  Future<void> deleteCategory(String categoryId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw CategoryException(
          message: 'No authenticated user found',
          code: 'no_user',
        );
      }

      await _supabase
          .from('categories')
          .delete()
          .eq('id', categoryId)
          .eq('user_id', userId); // Ensure user owns this category
    } catch (e) {
      throw CategoryException(
        message: 'Failed to delete category: ${e.toString()}',
        code: 'delete_error',
      );
    }
  }

  /// Get a single category by ID
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw CategoryException(
          message: 'No authenticated user found',
          code: 'no_user',
        );
      }

      final response = await _supabase
          .from('categories')
          .select()
          .eq('id', categoryId)
          .eq('user_id', userId)
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Check if category name already exists for user
  Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      var query = _supabase
          .from('categories')
          .select('id')
          .eq('user_id', userId)
          .ilike('name', name);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get challenge completion stats for a category
  /// Returns {total: int, completed: int}
  Future<Map<String, int>> getChallengeStats(String categoryId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return {'total': 0, 'completed': 0};

      final response = await _supabase
          .from('challenges')
          .select('id, completed')
          .eq('user_id', userId)
          .eq('category_id', categoryId);

      final challenges = response as List;
      final total = challenges.length;
      final completed = challenges.where((c) => c['completed'] == true).length;

      return {'total': total, 'completed': completed};
    } catch (e) {
      return {'total': 0, 'completed': 0};
    }
  }
}
