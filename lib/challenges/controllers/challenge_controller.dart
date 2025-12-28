import 'package:get/get.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';

class ChallengeController extends GetxController {
  final ChallengeService _service = ChallengeService();

  final RxList<ChallengeModel> _challenges = <ChallengeModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  String? _categoryId;

  List<ChallengeModel> get challenges => _challenges;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get hasChallenges => _challenges.isNotEmpty;

  Future<void> fetchForCategory(String categoryId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      _categoryId = categoryId;
      final list = await _service.fetchChallengesForCategory(categoryId);
      _challenges.assignAll(list);
    } on ChallengeException catch (e) {
      _errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      _errorMessage.value = 'Failed to load challenges';
      Get.snackbar('Error', 'Failed to load challenges', snackPosition: SnackPosition.BOTTOM);
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
      _isLoading.value = true;
      _errorMessage.value = '';
      final created = await _service.createChallenge(
        categoryId: categoryId,
        title: title,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      _challenges.insert(0, created);
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
      final idx = _challenges.indexWhere((c) => c.id == challengeId);
      if (idx != -1) _challenges[idx] = updated;
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

  Future<bool> delete(String challengeId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      await _service.deleteChallenge(challengeId);
      _challenges.removeWhere((c) => c.id == challengeId);
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
    if (_categoryId != null) {
      await fetchForCategory(_categoryId!);
    }
  }

  Future<bool> toggleCompletion(String challengeId, bool completed) async {
    try {
      _isLoading.value = true;
      final updated = await _service.toggleCompletion(challengeId, !completed);
      final idx = _challenges.indexWhere((c) => c.id == challengeId);
      if (idx != -1) _challenges[idx] = updated;
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