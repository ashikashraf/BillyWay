import 'package:flutter/material.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/master_management_page.dart';
import '../../domain/repositories/master_repository.dart';
import '../../data/repositories/supabase_master_repository.dart';

class MasterFormModal extends StatefulWidget {
  final MasterModule module;

  const MasterFormModal({super.key, required this.module});

  static Future<Map<String, dynamic>?> show(BuildContext context, MasterModule module) {
    return showGeneralDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: MasterFormModal(module: module),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  State<MasterFormModal> createState() => _MasterFormModalState();
}

class _MasterFormModalState extends State<MasterFormModal> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _dropdownValues = {};
  final Map<String, bool> _switchValues = {};
  bool _isLoading = false;

  late final MasterRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseMasterRepository(Supabase.instance.client);
    _initializeFormState();
  }

  void _initializeFormState() {
    // We just register controllers/values on the fly when building fields.
    // So we don't strictly need to prepopulate them here unless we were editing.
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();
    }
    return _controllers[key]!;
  }

  String _getTableName() {
    switch (widget.module) {
      case MasterModule.ledgerGroup: return 'ledger_groups';
      case MasterModule.hsnCode: return 'hsn_codes';
      case MasterModule.itemCategory: return 'item_categories';
      case MasterModule.taxClass: return 'tax_classes';
      case MasterModule.transactionType: return 'transaction_types';
      case MasterModule.sundryType: return 'sundry_types';
      case MasterModule.uom: return 'units';
      case MasterModule.brand: return 'brands';
      case MasterModule.warehouse: return 'warehouses';
    }
  }

  Map<String, dynamic> _gatherData() {
    final data = <String, dynamic>{};
    
    switch (widget.module) {
      case MasterModule.ledgerGroup:
        data['group_name'] = _controllers['group_name']?.text;
        data['nature'] = _dropdownValues['nature']?.toLowerCase() ?? 'debit';
        data['gst_applicable'] = _switchValues['gst_applicable'] ?? true;
        // ignoring description as it's not in schema
        break;
      case MasterModule.hsnCode:
        data['hsn_code'] = _controllers['hsn_code']?.text;
        data['description'] = _controllers['description']?.text;
        data['gst_rate'] = double.tryParse(_dropdownValues['gst_rate']?.replaceAll('%', '') ?? '0') ?? 0;
        data['type'] = _dropdownValues['type']?.toLowerCase() ?? 'goods';
        break;
      case MasterModule.itemCategory:
        data['category_name'] = _controllers['category_name']?.text;
        data['code'] = _controllers['code']?.text;
        data['description'] = _controllers['description']?.text;
        break;
      case MasterModule.taxClass:
        data['tax_class_name'] = _controllers['tax_class_name']?.text;
        data['gst_percentage'] = double.tryParse(_controllers['gst_percentage']?.text ?? '0') ?? 0;
        data['cgst'] = double.tryParse(_controllers['cgst']?.text ?? '0') ?? 0;
        data['sgst'] = double.tryParse(_controllers['sgst']?.text ?? '0') ?? 0;
        data['igst'] = double.tryParse(_controllers['igst']?.text ?? '0') ?? 0;
        data['inclusive_type'] = _dropdownValues['inclusive_type'] == 'Inclusive';
        break;
      case MasterModule.transactionType:
        data['name'] = _controllers['name']?.text;
        data['mode'] = _dropdownValues['mode']?.toLowerCase() ?? 'both';
        data['auto_prefix'] = _controllers['auto_prefix']?.text;
        break;
      case MasterModule.sundryType:
        data['sundry_type_name'] = _controllers['sundry_type_name']?.text;
        data['type'] = _dropdownValues['type']?.toLowerCase() ?? 'general';
        data['tax_applicable'] = _switchValues['tax_applicable'] ?? true;
        break;
      case MasterModule.uom:
        data['unit_name'] = _controllers['unit_name']?.text;
        data['symbol'] = _controllers['symbol']?.text;
        data['allow_decimal'] = _switchValues['allow_decimal'] ?? false;
        break;
      case MasterModule.brand:
        data['brand_name'] = _controllers['brand_name']?.text;
        data['code'] = _controllers['code']?.text;
        break;
      case MasterModule.warehouse:
        data['warehouse_name'] = _controllers['warehouse_name']?.text;
        data['code'] = _controllers['code']?.text;
        data['location'] = _controllers['location']?.text;
        data['contact_person'] = _controllers['contact_person']?.text;
        break;
    }
    
    // Remove nulls or empty strings if necessary, but we'll let Supabase handle constraints
    data.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    return data;
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final data = _gatherData();
        final insertedRecord = await _repository.insertMasterRecord(_getTableName(), data);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.module.label} created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, insertedRecord);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: isMobile ? MediaQuery.of(context).size.width : 500.w,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Form(
                  key: _formKey,
                  child: _buildFormFields(),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(widget.module.icon, color: AppColors.primary),
              SizedBox(width: 12.w),
              Text(
                'New ${widget.module.label}',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    switch (widget.module) {
      case MasterModule.ledgerGroup:
        return Column(
          children: [
            _buildTextField('Ledger Group Name', 'group_name', hint: 'e.g. Indirect Expenses'),
            _buildDropdownField('Group Nature', 'nature', ['Debit', 'Credit', 'Both'], 'Debit'),
            _buildSwitchField('Default GST Applicability', 'gst_applicable', true),
          ],
        );
      case MasterModule.hsnCode:
        return Column(
          children: [
            _buildTextField('HSN/SAC Code', 'hsn_code', hint: '8-digit code'),
            _buildTextField('Description', 'description', hint: 'Brief description'),
            _buildDropdownField('GST Rate', 'gst_rate', ['0%', '5%', '12%', '18%', '28%'], '18%'),
            _buildDropdownField('Tax Type', 'type', ['Goods', 'Services'], 'Goods'),
          ],
        );
      case MasterModule.itemCategory:
        return Column(
          children: [
            _buildTextField('Category Name', 'category_name'),
            _buildTextField('Category Code', 'code'),
            _buildTextField('Description', 'description', maxLines: 2),
          ],
        );
      case MasterModule.taxClass:
        return Column(
          children: [
            _buildTextField('Tax Class Name', 'tax_class_name'),
            _buildTextField('Applicable GST %', 'gst_percentage', isNumeric: true),
            _buildTextField('CGST %', 'cgst', isNumeric: true),
            _buildTextField('SGST %', 'sgst', isNumeric: true),
            _buildTextField('IGST %', 'igst', isNumeric: true),
            _buildDropdownField('Tax Type', 'inclusive_type', ['Exclusive', 'Inclusive'], 'Exclusive'),
          ],
        );
      case MasterModule.transactionType:
        return Column(
          children: [
            _buildTextField('Transaction Type Name', 'name'),
            _buildDropdownField('Mode', 'mode', ['Credit', 'Debit', 'Both'], 'Both'),
            _buildTextField('Auto-Numbering Prefix', 'auto_prefix'),
          ],
        );
      case MasterModule.sundryType:
        return Column(
          children: [
            _buildTextField('Sundry Type Name', 'sundry_type_name'),
            _buildDropdownField('Type', 'type', ['Debtor', 'Creditor', 'General'], 'Debtor'),
            _buildSwitchField('Tax Applicability', 'tax_applicable', true),
          ],
        );
      case MasterModule.uom:
        return Column(
          children: [
            _buildTextField('Unit Name', 'unit_name', hint: 'e.g. Kilogram'),
            _buildTextField('Symbol', 'symbol', hint: 'e.g. KG'),
            _buildSwitchField('Decimal Support', 'allow_decimal', false),
          ],
        );
      case MasterModule.brand:
        return Column(
          children: [
            _buildTextField('Brand Name', 'brand_name'),
            _buildTextField('Brand Code', 'code'),
          ],
        );
      case MasterModule.warehouse:
        return Column(
          children: [
            _buildTextField('Warehouse Name', 'warehouse_name'),
            _buildTextField('Warehouse Code', 'code'),
            _buildTextField('Location', 'location'),
            _buildTextField('Contact Person', 'contact_person'),
          ],
        );
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              child: _isLoading 
                ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Master'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String key, {String? hint, int maxLines = 1, bool isNumeric = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _getController(key),
            maxLines: maxLines,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String key, List<String> items, String defaultValue) {
    if (!_dropdownValues.containsKey(key)) {
      _dropdownValues[key] = defaultValue;
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            initialValue: _dropdownValues[key],
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _dropdownValues[key] = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField(String label, String key, bool defaultValue) {
    if (!_switchValues.containsKey(key)) {
      _switchValues[key] = defaultValue;
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
          Switch.adaptive(
            value: _switchValues[key]!,
            onChanged: (v) => setState(() => _switchValues[key] = v),
          ),
        ],
      ),
    );
  }
}
