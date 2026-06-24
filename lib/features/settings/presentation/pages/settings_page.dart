import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/auth/domain/repositories/auth_repository.dart';
import 'package:billy_way/core/theme/theme_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildAppearanceCard(context),
          SizedBox(height: 16.h),
          Card(
            elevation: 0,
            color: theme.cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              subtitle: const Text('Sign out of your account'),
              onTap: () => _showLogoutConfirmation(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Perform sign out
                try {
                  await getIt<AuthRepository>().signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: getIt<ThemeController>().themeModeNotifier,
              builder: (context, currentMode, _) {
                return Row(
                  children: [
                    _buildThemeOption(
                      title: 'System',
                      icon: Icons.brightness_auto,
                      isSelected: currentMode == ThemeMode.system,
                      isDark: isDark,
                      onTap: () => getIt<ThemeController>().updateThemeMode(
                        ThemeMode.system,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _buildThemeOption(
                      title: 'Light',
                      icon: Icons.light_mode,
                      isSelected: currentMode == ThemeMode.light,
                      isDark: isDark,
                      onTap: () => getIt<ThemeController>().updateThemeMode(
                        ThemeMode.light,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _buildThemeOption(
                      title: 'Dark',
                      icon: Icons.dark_mode,
                      isSelected: currentMode == ThemeMode.dark,
                      isDark: isDark,
                      onTap: () => getIt<ThemeController>().updateThemeMode(
                        ThemeMode.dark,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                size: 24.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
