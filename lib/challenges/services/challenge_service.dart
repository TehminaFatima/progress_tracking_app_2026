import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';

class ChallengeException implements Exception {
  final String message;
  final String? code;
  ChallengeException({required this.message, this.code});
  @override
  String toString() => message;
}

class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();
  late final SupabaseClient _supabase;

  factory ChallengeService() => _instance;

  ChallengeService._internal() {
    _supabase = Supabase.instance.client;
  }

  String? get currentUserId => _supabase.auth.currentUser?.id;

  static const allowedTypes = {
    'daily', 'weekly', 'monthly', 'yearly', 'custom'
  };

  Future<List<ChallengeModel>> fetchChallengesForCategory(String categoryId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw ChallengeException(message: 'No authenticated user');
      }
      final response = await _supabase
          .from('challenges')
          .select()
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => ChallengeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ChallengeException(message: 'Failed to fetch challenges: ${e.toString()}');
    }
  }

  Future<ChallengeModel> createChallenge({
    required String categoryId,
    required String title,
    required String type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw ChallengeException(message: 'No authenticated user');
      }
      if (!allowedTypes.contains(type)) {
        throw ChallengeException(message: 'Invalid challenge type');
      }

      final response = await _supabase
          .from('challenges')
          .insert({
            'user_id': userId,
            'category_id': categoryId,
            'title': title,
            'type': type,
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
          })
          .select()
          .single();

      return ChallengeModel.fromJson(response);
    } catch (e) {
      throw ChallengeException(message: 'Failed to create challenge: ${e.toString()}');
    }
  }

  Future<ChallengeModel> updateChallenge({
    required String challengeId,
    required String title,
    required String type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw ChallengeException(message: 'No authenticated user');
      }
      if (!allowedTypes.contains(type)) {
        throw ChallengeException(message: 'Invalid challenge type');
      }

      final response = await _supabase
          .from('challenges')
          .update({
            'title': title,
            'type': type,
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
          })
          .eq('id', challengeId)
          .eq('user_id', userId)
          .select()
          .single();

      return ChallengeModel.fromJson(response);
    } catch (e) {
      throw ChallengeException(message: 'Failed to update challenge: ${e.toString()}');
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw ChallengeException(message: 'No authenticated user');
      }
      await _supabase
          .from('challenges')
          .delete()
          .eq('id', challengeId)
          .eq('user_id', userId);
    } catch (e) {
      throw ChallengeException(message: 'Failed to delete challenge: ${e.toString()}');
    }
  }

  Future<ChallengeModel> toggleCompletion(String challengeId, bool completed) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw ChallengeException(message: 'No authenticated user');
      }
      final response = await _supabase
          .from('challenges')
          .update({'completed': completed})
          .eq('id', challengeId)
          .eq('user_id', userId)
          .select()
          .single();

      return ChallengeModel.fromJson(response);
    } catch (e) {
      throw ChallengeException(message: 'Failed to toggle challenge: ${e.toString()}');
    }
  }
}