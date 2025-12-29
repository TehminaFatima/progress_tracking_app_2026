import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

/// GetX Controller for category management
class CategoryController extends GetxController {
  final CategoryService _categoryService = CategoryService();

  // Observable categories list
  final RxList<CategoryModel> _categories = <CategoryModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get hasCategories => _categories.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    // Reset loading state on initialization
    _isLoading.value = false;
    print('📋 CategoryController: Initialized, isLoading: ${_isLoading.value}');
  }
  
  /// Initialize and fetch categories (call this after login)
  Future<void> initialize() async {
    print('📋 CategoryController: Manual initialize called');
    await fetchCategories();
  }

  /// Fetch all categories from Supabase
  Future<void> fetchCategories() async {
    print('📋 CategoryController: fetchCategories called, current isLoading: $_isLoading');
    
    if (_isLoading.value) {
      print('⚠️ CategoryController: Already loading, skipping duplicate fetch');
      return;
    }
    
    try {
      print('📋 CategoryController: Starting to fetch categories...');
      _isLoading.value = true;
      _errorMessage.value = '';

      final fetchedCategories = await _categoryService.fetchCategories();
      print('📋 CategoryController: Fetched ${fetchedCategories.length} categories');
      _categories.assignAll(fetchedCategories);
      print('📋 CategoryController: Categories assigned to observable list');
    } on CategoryException catch (e) {
      print('❌ CategoryController: CategoryException - ${e.message}');
      _errorMessage.value = e.message;
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ CategoryController: Error - $e');
      _errorMessage.value = 'Failed to load categories: $e';
      Get.snackbar(
        'Error',
        'Failed to load categories: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
      print('📋 CategoryController: Fetch complete. Loading: false, Categories count: ${_categories.length}');
    }
  }

  /// Create a new category
  Future<bool> createCategory({
    required String name,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Check if name already exists
      final exists = await _categoryService.categoryNameExists(name);
      if (exists) {
        Get.snackbar(
          'Duplicate Name',
          'A category with this name already exists',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final newCategory = await _categoryService.createCategory(
        name: name,
      );

      _categories.add(newCategory);

      Get.snackbar(
        'Success',
        'Category "$name" created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } on CategoryException catch (e) {
      _errorMessage.value = e.message;
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to create category';
      Get.snackbar(
        'Error',
        'Failed to create category',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update an existing category
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Check if name already exists (excluding current category)
      final exists = await _categoryService.categoryNameExists(
        name,
        excludeId: categoryId,
      );
      if (exists) {
        Get.snackbar(
          'Duplicate Name',
          'A category with this name already exists',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final updatedCategory = await _categoryService.updateCategory(
        categoryId: categoryId,
        name: name,
      );

      // Update in local list
      final index = _categories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }

      Get.snackbar(
        'Success',
        'Category updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } on CategoryException catch (e) {
      _errorMessage.value = e.message;
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to update category';
      Get.snackbar(
        'Error',
        'Failed to update category',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _categoryService.deleteCategory(categoryId);

      // Remove from local list
      _categories.removeWhere((cat) => cat.id == categoryId);

      Get.snackbar(
        'Success',
        'Category deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } on CategoryException catch (e) {
      _errorMessage.value = e.message;
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to delete category';
      Get.snackbar(
        'Error',
        'Failed to delete category',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh categories
  @override
  Future<void> refresh() async {
    await fetchCategories();
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }
}
