import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../masters/presentation/pages/master_management_page.dart';
import '../../../masters/presentation/widgets/smart_master_dropdown.dart';

class ProductEntryPage extends StatefulWidget {
  const ProductEntryPage({super.key});

  @override
  State<ProductEntryPage> createState() => _ProductEntryPageState();
}

class _ProductEntryPageState extends State<ProductEntryPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for margin calculation
  final _purchaseController = TextEditingController(text: '0.00');
  final _sellingController = TextEditingController(text: '0.00');
  double _marginPercent = 0.0;

  bool _isInclusive = true;

  @override
  void initState() {
    super.initState();
    _purchaseController.addListener(_calculateMargin);
    _sellingController.addListener(_calculateMargin);
  }

  void _calculateMargin() {
    double p = double.tryParse(_purchaseController.text) ?? 0;
    double s = double.tryParse(_sellingController.text) ?? 0;
    if (p > 0) {
      setState(() {
        _marginPercent = ((s - p) / p) * 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 1100;
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: 24.h),
                    if (isSmallScreen) ...[
                      _buildBasicInfoCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildPricingTaxCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildInventoryCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildAdditionalDetailsCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildProductPreviewCard(),
                      SizedBox(height: 16.h),
                      _buildImageUploadCard(isMobile),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildBasicInfoCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildPricingTaxCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildInventoryCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildAdditionalDetailsCard(isMobile),
                              ],
                            ),
                          ),
                          SizedBox(width: 24.w),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _buildProductPreviewCard(),
                                SizedBox(height: 24.h),
                                _buildImageUploadCard(isMobile),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildStickyFooter(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 8.w),
        Text(
          isMobile ? 'New Product' : 'Add New Product Master',
          style: TextStyle(
            fontSize: isMobile ? 20.sp : 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (!isMobile) _buildStatusSwitch(),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            'ACTIVE',
            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
          SizedBox(width: 8.w),
          Switch.adaptive(
            value: true,
            onChanged: (v) {},
            activeThumbColor: AppColors.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.info_outline, 'Basic Information'),
            SizedBox(height: 24.h),
            _buildTextField('Product Name', hint: 'e.g. Saffola Gold Edible Oil'),
            SizedBox(height: 16.h),
            if (isMobile) ...[
              _buildTextField('SKU / Product Code', hint: 'PROD-001'),
              SizedBox(height: 16.h),
              _buildTextField('Barcode', hint: 'Scan or Enter Barcode', suffixIcon: Icons.qr_code_scanner),
              SizedBox(height: 16.h),
              SmartMasterDropdown(
                module: MasterModule.itemCategory,
                label: 'Category',
                displayItem: (item) => item['category_name'] ?? 'Unknown',
                onChanged: (v) {},
              ),
              SizedBox(height: 16.h),
              SmartMasterDropdown(
                module: MasterModule.brand,
                label: 'Brand',
                displayItem: (item) => item['brand_name'] ?? 'Unknown',
                onChanged: (v) {},
              ),
              SizedBox(height: 16.h),
              SmartMasterDropdown(
                module: MasterModule.hsnCode,
                label: 'HSN Code',
                displayItem: (item) => '${item['hsn_code']} - ${item['description'] ?? ''}',
                onChanged: (v) {},
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildTextField('SKU / Product Code', hint: 'PROD-001')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Barcode', hint: 'Scan or Enter Barcode', suffixIcon: Icons.qr_code_scanner)),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: SmartMasterDropdown(
                      module: MasterModule.itemCategory,
                      label: 'Category',
                      displayItem: (item) => item['category_name'] ?? 'Unknown',
                      onChanged: (v) {},
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SmartMasterDropdown(
                      module: MasterModule.brand,
                      label: 'Brand',
                      displayItem: (item) => item['brand_name'] ?? 'Unknown',
                      onChanged: (v) {},
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SmartMasterDropdown(
                      module: MasterModule.hsnCode,
                      label: 'HSN Code',
                      displayItem: (item) => '${item['hsn_code']} - ${item['description'] ?? ''}',
                      onChanged: (v) {},
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingTaxCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.payments_outlined, 'Pricing & Taxation'),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              _buildTextField('Purchase Price', controller: _purchaseController, prefixText: '₹ '),
              SizedBox(height: 16.h),
              _buildTextField('Selling Price', controller: _sellingController, prefixText: '₹ '),
              SizedBox(height: 16.h),
              _buildTextField('MRP', prefixText: '₹ '),
            ] else
              Row(
                children: [
                  Expanded(child: _buildTextField('Purchase Price', controller: _purchaseController, prefixText: '₹ ')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Selling Price', controller: _sellingController, prefixText: '₹ ')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('MRP', prefixText: '₹ ')),
                ],
              ),
            SizedBox(height: 16.h),
            if (isMobile) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('Margin:', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
                    SizedBox(width: 8.w),
                    Text('${_marginPercent.toStringAsFixed(1)}%', 
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              SmartMasterDropdown(
                module: MasterModule.taxClass,
                label: 'Tax Class',
                displayItem: (item) => '${item['tax_class_name']} (${item['gst_percentage']}%)',
                onChanged: (v) {},
              ),
              SizedBox(height: 16.h),
              _buildTaxTypeSelection(),
            ] else
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text('Margin:', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
                          SizedBox(width: 8.w),
                          Text('${_marginPercent.toStringAsFixed(1)}%', 
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SmartMasterDropdown(
                      module: MasterModule.taxClass,
                      label: 'Tax Class',
                      displayItem: (item) => '${item['tax_class_name']} (${item['gst_percentage']}%)',
                      onChanged: (v) {},
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTaxTypeSelection()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tax Type', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Inclusive'),
              selected: _isInclusive,
              onSelected: (v) => setState(() => _isInclusive = true),
            ),
            SizedBox(width: 8.w),
            ChoiceChip(
              label: const Text('Exclusive'),
              selected: !_isInclusive,
              onSelected: (v) => setState(() => _isInclusive = false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.inventory_2_outlined, 'Inventory Management'),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              _buildTextField('Opening Stock', initialValue: '0'),
              SizedBox(height: 16.h),
              SmartMasterDropdown(
                module: MasterModule.uom,
                label: 'Unit',
                displayItem: (item) => '${item['unit_name']} (${item['symbol']})',
                onChanged: (v) {},
              ),
              SizedBox(height: 16.h),
              _buildTextField('Reorder Level', initialValue: '10'),
              SizedBox(height: 16.h),
              _buildTextField('Warehouse Location', hint: 'A-102'),
              SizedBox(height: 16.h),
              _buildTextField('MOQ', initialValue: '1'),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildTextField('Opening Stock', initialValue: '0')),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SmartMasterDropdown(
                      module: MasterModule.uom,
                      label: 'Unit',
                      displayItem: (item) => '${item['unit_name']} (${item['symbol']})',
                      onChanged: (v) {},
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Reorder Level', initialValue: '10')),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: _buildTextField('Warehouse Location', hint: 'A-102')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('MOQ', initialValue: '1')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalDetailsCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.more_horiz, 'Additional Details'),
            SizedBox(height: 24.h),
            _buildTextField('Description', maxLines: 3, hint: 'Enter detailed product description...'),
            SizedBox(height: 16.h),
            _buildTextField('Variants', hint: 'e.g. Size: Large, Color: Red'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPreviewCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Icon(Icons.image_outlined, size: 48.sp, color: AppColors.textTertiary),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PREVIEW', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                SizedBox(height: 8.h),
                Text('Product Name Preview', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 4.h),
                Text('Category Name', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹ 0.00', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Stock: 0', style: TextStyle(color: AppColors.warning, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.cloud_upload_outlined, 'Product Images'),
            SizedBox(height: 16.h),
            Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.none), // Simplified for design
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary.withValues(alpha: 0.02),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 32.sp),
                  SizedBox(height: 8.h),
                  Text('Drag & Drop or Click', style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  Text('Max size 2MB (JPG/PNG)', style: TextStyle(fontSize: 10.sp, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {},
            child: const Text('Clear All'),
          ),
          SizedBox(width: 16.w),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save Product Master'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility Widgets ---

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 8.w),
        Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildTextField(String label, {String? hint, String? initialValue, TextEditingController? controller, IconData? prefixIcon, IconData? suffixIcon, String? prefixText, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20.sp) : null,
            prefixText: prefixText,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18.sp) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

}
