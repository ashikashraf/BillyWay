import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/master_data_table.dart';
import '../widgets/master_form_modal.dart';

enum MasterModule {
  ledgerGroup('Ledger Group', Icons.account_tree_outlined),
  hsnCode('HSN/SAC Code', Icons.pin_outlined),
  itemCategory('Item Category', Icons.category_outlined),
  taxClass('Tax Class', Icons.percent_outlined),
  transactionType('Transaction Type', Icons.swap_vert_outlined),
  sundryType('Sundry Type', Icons.people_outline),
  uom('Unit of Measure', Icons.straighten_outlined),
  brand('Brand', Icons.branding_watermark_outlined),
  warehouse('Warehouse', Icons.warehouse_outlined);

  final String label;
  final IconData icon;
  const MasterModule(this.label, this.icon);
}

class MasterManagementPage extends StatefulWidget {
  const MasterManagementPage({super.key});

  @override
  State<MasterManagementPage> createState() => _MasterManagementPageState();
}

class _MasterManagementPageState extends State<MasterManagementPage> {
  MasterModule _selectedModule = MasterModule.ledgerGroup;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(isMobile),
          Expanded(
            child: isMobile
                ? Column(
                    children: [
                      _buildModuleSelectorMobile(),
                      Expanded(child: _buildMainContent()),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModuleSidebar(),
                      Expanded(child: _buildMainContent()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Master Data Management',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Configure core options for your billing system',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddMasterModal(),
            icon: const Icon(Icons.add),
            label: const Text('Add New'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSidebar() {
    return Container(
      width: 240.w,
      margin: EdgeInsets.only(left: 24.w, bottom: 24.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(8.w),
        itemCount: MasterModule.values.length,
        itemBuilder: (context, index) {
          final module = MasterModule.values[index];
          final isSelected = _selectedModule == module;
          return Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: InkWell(
              onTap: () => setState(() => _selectedModule = module),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      module.icon,
                      size: 20.sp,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        module.label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModuleSelectorMobile() {
    return SizedBox(
      height: 50.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: MasterModule.values.length,
        itemBuilder: (context, index) {
          final module = MasterModule.values[index];
          final isSelected = _selectedModule == module;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(module.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedModule = module),
              selectedColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: EdgeInsets.all(
        MediaQuery.of(context).size.width < 900 ? 16.w : 24.w,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSearchAndFilters(),
          const Divider(height: 1),
          Expanded(child: _buildDataTable()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ${_selectedModule.label}...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          IconButton.outlined(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
          SizedBox(width: 8.w),
          IconButton.outlined(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export',
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return MasterDataTable(module: _selectedModule);
  }

  Widget _buildPagination() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing 0 of 0 records',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          Row(
            children: [
              IconButton(onPressed: null, icon: const Icon(Icons.chevron_left)),
              Text('Page 1 of 1', style: TextStyle(fontSize: 12.sp)),
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMasterModal() {
    MasterFormModal.show(context, _selectedModule);
  }
}
