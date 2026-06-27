import 'package:billy_way/core/theme/theme_controller.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/auth/domain/repositories/auth_repository.dart';
import 'package:billy_way/features/settings/domain/controllers/settings_controller.dart';
import 'package:billy_way/features/masters/domain/controllers/master_data_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _stateCodeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _enableMultiWarehouse = false;
  String? _defaultWarehouseId;

  late SettingsController _settingsController;
  late MasterDataController _masterController;
  List<Map<String, dynamic>> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _settingsController = getIt<SettingsController>();
    _masterController = getIt<MasterDataController>();

    _settingsController.addListener(_onSettingsUpdated);
    _masterController.masterDataNotifier.addListener(_onMasterDataChanged);

    if (!_masterController.isInitialized) {
      _masterController.initRealtimeSync();
    } else {
      _onMasterDataChanged();
    }

    _populateForm();
  }

  void _onMasterDataChanged() {
    if (mounted) {
      setState(() {
        _warehouses =
            _masterController.masterDataNotifier.value['warehouses'] ?? [];
      });
    }
  }

  void _onSettingsUpdated() {
    if (mounted) {
      _populateForm();
      setState(() {});
    }
  }

  void _populateForm() {
    final data = _settingsController.companySettings;
    if (data != null) {
      _companyNameCtrl.text = data['company_name'] ?? '';
      _gstinCtrl.text = data['gstin'] ?? '';
      _stateCodeCtrl.text = data['state_code'] ?? '';
      _addressCtrl.text = data['address'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _enableMultiWarehouse = data['enable_multi_warehouse'] ?? false;
      _defaultWarehouseId = data['default_warehouse_id'];
    }
  }

  void dispose() {
    _settingsController.removeListener(_onSettingsUpdated);
    _masterController.masterDataNotifier.removeListener(_onMasterDataChanged);
    _companyNameCtrl.dispose();
    _gstinCtrl.dispose();
    _stateCodeCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCompanySettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _settingsController.updateSettings({
        'company_name': _companyNameCtrl.text,
        'gstin': _gstinCtrl.text,
        'state_code': _stateCodeCtrl.text,
        'address': _addressCtrl.text,
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'enable_multi_warehouse': _enableMultiWarehouse,
        'default_warehouse_id': _defaultWarehouseId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company Settings saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _buildCompanySettingsCard(context, isDark),
              SizedBox(height: 16.h),
              _buildInventorySettingsCard(context, isDark),
              SizedBox(height: 16.h),
              _buildAppearanceCard(context, isDark),
              SizedBox(height: 16.h),
              _buildLogoutCard(context, isDark),
              SizedBox(height: 100.h),
            ],
          ),
          if (_settingsController.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: AppLoadingAnimation()),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanySettingsCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Text(
                    'Company Profile',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                'Company Name *',
                controller: _companyNameCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      'GSTIN',
                      controller: _gstinCtrl,
                      onChanged: (val) {
                        if (val.length >= 2) {
                          _stateCodeCtrl.text = val.substring(0, 2);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField(
                      'State Code *',
                      controller: _stateCodeCtrl,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'State code dictates CGST/SGST vs IGST calculation.',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Phone', controller: _phoneCtrl),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField('Email', controller: _emailCtrl),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                'Registered Address',
                controller: _addressCtrl,
                maxLines: 2,
              ),
              SizedBox(height: 16.h),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _saveCompanySettings,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventorySettingsCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
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
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  'Inventory & Warehouse',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Multi-Warehouse Management',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'If disabled, the warehouse field will be hidden on bills and the default warehouse will be used automatically.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _enableMultiWarehouse,
                  onChanged: (v) => setState(() => _enableMultiWarehouse = v),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Default Warehouse *',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              value: _defaultWarehouseId,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                hintText: 'Select default warehouse',
              ),
              items: _warehouses.map((w) {
                return DropdownMenuItem<String>(
                  value: w['id'],
                  child: Text(w['warehouse_name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _defaultWarehouseId = v),
              validator: (v) => v == null
                  ? 'Required to ensure proper stock deduction'
                  : null,
            ),
            SizedBox(height: 16.h),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saveCompanySettings,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Settings'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    TextEditingController? controller,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
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

  Widget _buildLogoutCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Card(
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
}
