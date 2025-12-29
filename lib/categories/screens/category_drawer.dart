import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../../challenges/screens/challenge_list_screen.dart';
import '../../auth/controllers/auth_controller.dart';

/// Drawer widget that displays categories and allows navigation to challenges
class CategoryDrawer extends StatelessWidget {
  const CategoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final CategoryController categoryController = Get.put(CategoryController());
    final AuthController authController = Get.find<AuthController>();
    
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Obx(() {
            final user = authController.currentUser;
            return UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              accountName: Text(
                user?.fullName ?? 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }),
          
          // Categories Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => categoryController.fetchCategories(),
                  tooltip: 'Refresh Categories',
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Categories List
          Expanded(
            child: Obx(() {
              if (categoryController.isLoading && !categoryController.hasCategories) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!categoryController.hasCategories) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Categories Yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a category to get started',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categoryController.categories.length,
                itemBuilder: (context, index) {
                  final category = categoryController.categories[index];
                  
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.folder,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Store category details before closing drawer
                      final catId = category.id;
                      final catName = category.name;
                      
                      // Close drawer first
                      Navigator.of(context).pop();
                      
                      // Navigate to challenges for this category
                      Get.to(
                        () => ChallengeListScreen(
                          categoryId: catId,
                          categoryName: catName,
                        ),
                        preventDuplicates: false,
                      );
                    },
                  );
                },
              );
            }),
          ),
          
          const Divider(height: 1),
          
          // Bottom Actions
          ListTile(
            leading: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
            title: const Text('Manage Categories'),
            onTap: () {
              Navigator.of(context).pop();
              Get.toNamed('/categories');
            },
          ),
          
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.of(context).pop();
              _showLogoutDialog(context, authController);
            },
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              authController.signOut().then((_) {
                Get.offAllNamed('/login');
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
