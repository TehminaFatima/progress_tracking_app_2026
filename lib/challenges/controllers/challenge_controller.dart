import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';

class ChallengeController extends GetxController {
  final ChallengeService _service = ChallengeService();

  // Use separate RxList for current category challenges
  final RxList<ChallengeModel> _challenges = <ChallengeModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  String? _currentCategoryId;

  // Cache for fetched challenges per category
  final Map<String, List<ChallengeModel>> _cache = {};

  String? get currentCategoryId => _currentCategoryId;
  List<ChallengeModel> get challenges => _challenges;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get hasChallenges => _challenges.isNotEmpty;

  Future<void> fetchForCategory(String categoryId) async {
    try {
      print('🎯 ChallengeController: Fetching challenges for category $categoryId');
      print('🎯 ChallengeController: Previous category was: $_currentCategoryId');
      
      // Defer all state changes until after the current frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading.value = true;
      });
      
      // Set current category FIRST
      _currentCategoryId = categoryId;
      
      // Clear the challenges list after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🎯 ChallengeController: Clearing ${_challenges.length} existing challenges from display');
        _challenges.clear();
        _errorMessage.value = '';
      });
      
      // Check cache first
      if (_cache.containsKey(categoryId)) {
        print('🎯 ChallengeController: Using cached challenges (${_cache[categoryId]!.length} items)');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _challenges.assignAll(_cache[categoryId]!);
          print('🎯 ChallengeController: Now displaying ${_challenges.length} challenges for category $_currentCategoryId');
          _isLoading.value = false;
        });
      } else {
        print('🎯 ChallengeController: No cache found, fetching from API...');
        final list = await _service.fetchChallengesForCategory(categoryId);
        print('🎯 ChallengeController: Fetched ${list.length} challenges from API');
        _cache[categoryId] = list;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _challenges.assignAll(list);
          print('🎯 ChallengeController: Now displaying ${_challenges.length} challenges for category $_currentCategoryId');
          _isLoading.value = false;
        });
      }
    } on ChallengeException catch (e) {
      print('❌ ChallengeController: Exception - ${e.message}');
      _errorMessage.value = e.message;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
        }
      });
    } catch (e) {
      print('❌ ChallengeController: Error - $e');
      _errorMessage.value = 'Failed to load challenges: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          Get.snackbar('Error', 'Failed to load challenges: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
        }
      });
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> create({
    required String categoryId,
    required String title,
    required String type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('🎯 ChallengeController: Creating challenge for category: $categoryId, current category: $_currentCategoryId');
      _isLoading.value = true;
      _errorMessage.value = '';
      final created = await _service.createChallenge(
        categoryId: categoryId,
        title: title,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Only add to current list if we're viewing the same category
      if (_currentCategoryId == categoryId) {
        _challenges.insert(0, created);
      }
      
      // Always update cache for the correct category
      if (_cache.containsKey(categoryId)) {
        _cache[categoryId]!.insert(0, created);
      } else {
        _cache[categoryId] = [created];
      }
      
      print('🎯 ChallengeController: Challenge added to cache for category $categoryId');
      Get.snackbar(
        '✓ Challenge Created',
        '"$title" has been added successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return true;
    } on ChallengeException catch (e) {
      _errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      _errorMessage.value = 'Failed to create challenge';
      Get.snackbar('Error', 'Failed to create challenge', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateChallenge({
    required String challengeId,
    required String title,
    required String type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      final updated = await _service.updateChallenge(
        challengeId: challengeId,
        title: title,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      // Update in current list
      final idx = _challenges.indexWhere((c) => c.id == challengeId);
      if (idx != -1) {
        _challenges[idx] = updated;
      }
      // Update in cache
      if (_currentCategoryId != null && _cache.containsKey(_currentCategoryId)) {
        final cacheIdx = _cache[_currentCategoryId]!.indexWhere((c) => c.id == challengeId);
        if (cacheIdx != -1) {
          _cache[_currentCategoryId]![cacheIdx] = updated;
        }
      }
      Get.snackbar(
        '✓ Challenge Updated',
        '"$title" has been saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return true;
    } on ChallengeException catch (e) {
      _errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      _errorMessage.value = 'Failed to update challenge';
      Get.snackbar('Error', 'Failed to update challenge', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deleteChallenge(String challengeId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      await _service.deleteChallenge(challengeId);
      // Remove from current list
      _challenges.removeWhere((c) => c.id == challengeId);
      // Remove from cache
      if (_currentCategoryId != null && _cache.containsKey(_currentCategoryId)) {
        _cache[_currentCategoryId]!.removeWhere((c) => c.id == challengeId);
      }
      Get.snackbar(
        '✓ Challenge Deleted',
        'Challenge has been removed successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return true;
    } on ChallengeException catch (e) {
      _errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      _errorMessage.value = 'Failed to delete challenge';
      Get.snackbar('Error', 'Failed to delete challenge', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    if (_currentCategoryId != null) {
      // Clear cache and refetch
      _cache.remove(_currentCategoryId);
      await fetchForCategory(_currentCategoryId!);
    }
  }

  Future<bool> toggleCompletion(String challengeId, bool completed) async {
    try {
      _isLoading.value = true;
      final updated = await _service.toggleCompletion(challengeId, !completed);
      // Update in current list
      final idx = _challenges.indexWhere((c) => c.id == challengeId);
      if (idx != -1) {
        _challenges[idx] = updated;
      }
      // Update in cache
      if (_currentCategoryId != null && _cache.containsKey(_currentCategoryId)) {
        final cacheIdx = _cache[_currentCategoryId]!.indexWhere((c) => c.id == challengeId);
        if (cacheIdx != -1) {
          _cache[_currentCategoryId]![cacheIdx] = updated;
        }
      }
      return true;
    } on ChallengeException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (_) {
      Get.snackbar('Error', 'Failed to update challenge', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}