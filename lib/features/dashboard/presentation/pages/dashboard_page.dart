import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 900;
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              SizedBox(height: isMobile ? 24.h : 32.h),
              _buildStatsGrid(isMobile),
              SizedBox(height: isMobile ? 24.h : 32.h),
              if (isSmallScreen) ...[
                _buildSalesChart(),
                SizedBox(height: 24.h),
                _buildRecentActivity(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildSalesChart()),
                    SizedBox(width: 24.w),
                    Expanded(child: _buildRecentActivity()),
                  ],
                ),
              SizedBox(height: 32.h),
              _buildBuildProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  'AK',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8.h,
            children: [
              _buildBranchChip(),
              Text(
                'Apr 2025',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            _buildBranchChip(),
            SizedBox(width: 24.w),
            Text(
              'Apr 2025',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(width: 24.w),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export'),
            ),
            SizedBox(width: 24.w),
            CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                'AK',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBranchChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Branch A – Thrissur',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primary,
            size: 18.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                'TODAY SALES',
                '₹ 48.2K',
                '+12%',
                AppColors.primary,
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                'THIS MONTH',
                '₹ 6.2L',
                '+8%',
                AppColors.secondary,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildStatCard('PENDING', '14', '3 overdue', AppColors.error),
              SizedBox(width: 12.w),
              _buildStatCard('LOW STOCK', '7', 'Alert', AppColors.warning),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildStatCard(
          'TODAY SALES',
          '₹ 48,200',
          '+12% vs yesterday',
          AppColors.primary,
        ),
        SizedBox(width: 16.w),
        _buildStatCard(
          'THIS MONTH',
          '₹ 6.2L',
          '+8% vs last',
          AppColors.secondary,
        ),
        SizedBox(width: 16.w),
        _buildStatCard('PENDING BILLS', '14', '3 overdue', AppColors.error),
        SizedBox(width: 16.w),
        _buildStatCard(
          'LOW STOCK',
          '7',
          'items below reorder',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: EdgeInsets.all(24.w),
      height: 350.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales – Last 7 days',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(0.6, 'M'),
                _buildBar(0.8, 'T'),
                _buildBar(0.4, 'W'),
                _buildBar(0.9, 'T'),
                _buildBar(0.7, 'F'),
                _buildBar(1.0, 'S'),
                _buildBar(0.5, 'S'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String day) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40.w,
          height: 200.h * heightFactor,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          day,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(24.w),
      height: 350.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent activity',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildActivityItem(
                    'Sale #BR1-2425-0041',
                    '₹ 8,450 • Ravi Traders • 2 min ago',
                    AppColors.success,
                  ),
                  _buildActivityItem(
                    'Transfer received from B',
                    '50 units Rice Bran Oil • 1hr ago',
                    AppColors.info,
                  ),
                  _buildActivityItem(
                    'Purchase #PUR-0018',
                    '₹ 32,000 • Pending approval',
                    AppColors.warning,
                  ),
                  _buildActivityItem(
                    'Stock alert: Mustard Oil',
                    'Only 8 units remaining',
                    AppColors.error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4.h),
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildProgress() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build progress (Phase 1–6)',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),
          _buildProgressBar('1. Foundation', 1.0, AppColors.success),
          _buildProgressBar('2. Billing', 0.7, AppColors.primary),
          _buildProgressBar('3. Stock', 0.3, AppColors.warning),
          _buildProgressBar('4. Transfers', 0.0, AppColors.textTertiary),
          _buildProgressBar('5. Reports', 0.0, AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.divider,
              color: color,
              minHeight: 8.h,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
