import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class SideNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const SideNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260.w,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? AppColors.darkSurface : AppColors.surface),
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.w,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              children: [
                const _SectionHeader(label: 'MAIN'),
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
                SizedBox(height: 16.h),
                const _SectionHeader(label: 'BILLING'),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: 'Sales Bills',
                  isSelected: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                ),
                _NavItem(
                  icon: Icons.assignment_return_outlined,
                  selectedIcon: Icons.assignment_return,
                  label: 'Credit Notes',
                  isSelected: selectedIndex == 13, // New index 13
                  onTap: () => onDestinationSelected(13),
                ),
                _NavItem(
                  icon: Icons.request_quote_outlined,
                  selectedIcon: Icons.request_quote,
                  label: 'Quotations',
                  isSelected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
                _NavItem(
                  icon: Icons.receipt_outlined,
                  selectedIcon: Icons.receipt,
                  label: 'Estimates',
                  isSelected: selectedIndex == 12, // New index 12
                  onTap: () => onDestinationSelected(12),
                ),
                _NavItem(
                  icon: Icons.shopping_cart_outlined,
                  selectedIcon: Icons.shopping_cart,
                  label: 'Purchase',
                  isSelected: selectedIndex == 3,
                  onTap: () => onDestinationSelected(3),
                ),
                SizedBox(height: 16.h),
                const _SectionHeader(label: 'INVENTORY'),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2,
                  label: 'Stock',
                  isSelected: selectedIndex == 4,
                  onTap: () => onDestinationSelected(4),
                ),
                _NavItem(
                  icon: Icons.swap_horiz_outlined,
                  selectedIcon: Icons.swap_horiz,
                  label: 'Transfers',
                  isSelected: selectedIndex == 5,
                  onTap: () => onDestinationSelected(5),
                ),
                SizedBox(height: 16.h),
                const _SectionHeader(label: 'REPORTS'),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics,
                  label: 'GST Reports',
                  isSelected: selectedIndex == 6,
                  onTap: () => onDestinationSelected(6),
                ),
                SizedBox(height: 16.h),
                const _SectionHeader(label: 'SETUP'),
                _NavItem(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: 'Parties',
                  isSelected: selectedIndex == 7,
                  onTap: () => onDestinationSelected(7),
                ),
                _NavItem(
                  icon: Icons.category_outlined,
                  selectedIcon: Icons.category,
                  label: 'Items',
                  isSelected: selectedIndex == 8,
                  onTap: () => onDestinationSelected(8),
                ),
                _NavItem(
                  icon: Icons.layers_outlined,
                  selectedIcon: Icons.layers,
                  label: 'Master Data',
                  isSelected: selectedIndex == 9,
                  onTap: () => onDestinationSelected(9),
                ),
                SizedBox(height: 16.h),
                ValueListenableBuilder<String?>(
                  valueListenable:
                      getIt<AuthRepository>().currentUserRoleNotifier,
                  builder: (context, role, child) {
                    if (role == 'admin') {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(label: 'ADMIN'),
                          _NavItem(
                            icon: Icons.manage_accounts_outlined,
                            selectedIcon: Icons.manage_accounts,
                            label: 'User Management',
                            isSelected: selectedIndex == 10,
                            onTap: () => onDestinationSelected(10),
                          ),
                          SizedBox(height: 16.h),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Divider(),

                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  isSelected: selectedIndex == 11,
                  onTap: () => onDestinationSelected(11),
                ),
              ],
            ),
          ),
          _buildUserSection(context),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(24.w),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'BW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'BillyWay ERP',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text('AD', style: TextStyle(color: AppColors.primary)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin User',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Main Branch',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 20.sp, color: AppColors.error),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(left: 12.w, bottom: 8.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
