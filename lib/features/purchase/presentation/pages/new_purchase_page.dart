import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/gst_calculator.dart';

class NewPurchasePage extends StatefulWidget {
  const NewPurchasePage({super.key});

  @override
  State<NewPurchasePage> createState() => _NewPurchasePageState();
}

class _NewPurchasePageState extends State<NewPurchasePage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController(
    text: DateFormat('dd MMM yyyy').format(DateTime.now()),
  );
  final _dueDateController = TextEditingController(
    text: DateFormat(
      'dd MMM yyyy',
    ).format(DateTime.now().add(const Duration(days: 30))),
  );

  // Items List
  final List<PurchaseItem> _items = [
    PurchaseItem(name: '', hsn: '', qty: 1, rate: 0, gstRate: 18),
  ];

  // Summary state
  double _subtotal = 0;
  double _totalTax = 0;
  double _totalAmount = 0;
  double _cgst = 0;
  double _sgst = 0;
  double _igst = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  void _calculateTotals() {
    double subtotal = 0;
    double cgst = 0;
    double sgst = 0;
    double igst = 0;

    for (var item in _items) {
      double lineTaxable = item.qty * item.rate;
      subtotal += lineTaxable;

      bool isInterState = false;
      var gstBreakdown = GstCalculator.calculate(
        taxableAmount: lineTaxable,
        gstRate: item.gstRate,
        isInterState: isInterState,
      );

      cgst += gstBreakdown['cgst'] ?? 0;
      sgst += gstBreakdown['sgst'] ?? 0;
      igst += gstBreakdown['igst'] ?? 0;
    }

    setState(() {
      _subtotal = subtotal;
      _cgst = cgst;
      _sgst = sgst;
      _igst = igst;
      _totalTax = cgst + sgst + igst;
      _totalAmount = _subtotal + _totalTax;
    });
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
                      _buildPurchaseDetailsCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildVendorDetailsCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildItemsTableCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildSummarySidebar(isMobile),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildPurchaseDetailsCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildVendorDetailsCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildItemsTableCard(isMobile),
                              ],
                            ),
                          ),
                          SizedBox(width: 24.w),
                          Expanded(
                            flex: 1,
                            child: _buildSummarySidebar(isMobile),
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
        Expanded(
          child: Text(
            isMobile ? 'New Purchase' : 'Record New Purchase Bill',
            style: TextStyle(
              fontSize: isMobile ? 20.sp : 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (!isMobile) _buildStatusChip('Draft'),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildPurchaseDetailsCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.description_outlined, 'Bill Details'),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              _buildTextField('Vendor Bill No', hint: 'As per vendor invoice'),
              SizedBox(height: 16.h),
              _buildTextField('Internal Ref #', initialValue: 'PUR-2425-0102'),
              SizedBox(height: 16.h),
              _buildTextField('Bill Date', controller: _dateController, suffixIcon: Icons.calendar_today),
              SizedBox(height: 16.h),
              _buildTextField('Due Date', controller: _dueDateController, suffixIcon: Icons.calendar_today),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Vendor Bill No',
                      hint: 'As per vendor invoice',
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTextField(
                      'Internal Ref #',
                      initialValue: 'PUR-2425-0102',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Bill Date',
                      controller: _dateController,
                      suffixIcon: Icons.calendar_today,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTextField(
                      'Due Date',
                      controller: _dueDateController,
                      suffixIcon: Icons.calendar_today,
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

  Widget _buildVendorDetailsCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.business_outlined, 'Vendor Details'),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              _buildTextField('Vendor Name', hint: 'Search or enter vendor', prefixIcon: Icons.search),
              SizedBox(height: 16.h),
              _buildTextField('Vendor GSTIN', hint: '27AAAAA0000A1Z5'),
            ] else
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      'Vendor Name',
                      hint: 'Search or enter vendor',
                      prefixIcon: Icons.search,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTextField(
                      'Vendor GSTIN',
                      hint: '27AAAAA0000A1Z5',
                    ),
                  ),
                ],
              ),
            SizedBox(height: 16.h),
            _buildTextField('Vendor Address', maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTableCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(
                  Icons.inventory_2_outlined,
                  'Purchased Items',
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _items.add(
                        PurchaseItem(
                          name: '',
                          hsn: '',
                          qty: 1,
                          rate: 0,
                          gstRate: 18,
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (isMobile)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildMobileItemCard(index),
              )
            else ...[
              _buildTableHead(),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => _buildItemRow(index),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileItemCard(int index) {
    var item = _items[index];
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTableField(hint: 'Item name', onChanged: (v) => item.name = v)),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20.sp),
                onPressed: () {
                  setState(() => _items.removeAt(index));
                  _calculateTotals();
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTableField(hint: 'HSN', onChanged: (v) => item.hsn = v)),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildTableField(initialValue: '1', onChanged: (v) {
                  item.qty = double.tryParse(v) ?? 0;
                  _calculateTotals();
                }),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildTableField(initialValue: '0.00', onChanged: (v) {
                  item.rate = double.tryParse(v) ?? 0;
                  _calculateTotals();
                }),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<double>(
                value: item.gstRate,
                items: [0.0, 5.0, 12.0, 18.0, 28.0].map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%'))).toList(),
                onChanged: (v) {
                  setState(() => item.gstRate = v!);
                  _calculateTotals();
                },
              ),
              Text('Total: ₹ ${(item.qty * item.rate).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHead() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      color: AppColors.divider.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(flex: 4, child: _buildTableColText('Item Description')),
          Expanded(flex: 2, child: _buildTableColText('HSN')),
          Expanded(child: _buildTableColText('Qty')),
          Expanded(child: _buildTableColText('Unit')),
          Expanded(flex: 2, child: _buildTableColText('Rate')),
          Expanded(flex: 2, child: _buildTableColText('GST %')),
          Expanded(flex: 2, child: _buildTableColText('Total')),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }

  Widget _buildTableColText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildItemRow(int index) {
    var item = _items[index];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildTableField(
              hint: 'Search item...',
              onChanged: (v) => item.name = v,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _buildTableField(
              hint: 'HSN',
              onChanged: (v) => item.hsn = v,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildTableField(
              initialValue: '1',
              onChanged: (v) {
                item.qty = double.tryParse(v) ?? 0;
                _calculateTotals();
              },
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildTableField(
              initialValue: 'PCS',
              onChanged: (v) => item.unit = v,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _buildTableField(
              initialValue: '0.00',
              onChanged: (v) {
                item.rate = double.tryParse(v) ?? 0;
                _calculateTotals();
              },
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: item.gstRate,
                isDense: true,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
                items: [0.0, 5.0, 12.0, 18.0, 28.0]
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text('${r.toInt()}%'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => item.gstRate = v!);
                  _calculateTotals();
                },
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              '₹ ${(item.qty * item.rate).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 40.w),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20.sp,
            ),
            onPressed: () {
              setState(() => _items.removeAt(index));
              _calculateTotals();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySidebar(bool isMobile) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(Icons.summarize_outlined, 'Summary'),
                SizedBox(height: 24.h),
                _buildSummaryRow('Taxable Subtotal', _subtotal),
                _buildSummaryRow('Input Tax Credit', _totalTax),
                const Divider(height: 32),
                _buildSummaryRow('CGST (ITC)', _cgst, isSmall: true),
                _buildSummaryRow('SGST (ITC)', _sgst, isSmall: true),
                _buildSummaryRow('IGST (ITC)', _igst, isSmall: true),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Payable',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹ ${_totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildTextField(
                  'Payment Method',
                  initialValue: 'Bank Transfer',
                  isDropdown: true,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  'Status',
                  initialValue: 'Pending',
                  isDropdown: true,
                ),
              ],
            ),
          ),
        ),
      ],
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
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.attach_file_outlined),
            label: const Text('Attach Bill'),
          ),
          SizedBox(width: 16.w),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save),
            label: const Text('Save Purchase Bill'),
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
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label, {
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? prefixText,
    int maxLines = 1,
    bool isDropdown = false,
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
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          maxLines: maxLines,
          readOnly: isDropdown,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20.sp)
                : null,
            prefixText: prefixText,
            suffixIcon: isDropdown
                ? const Icon(Icons.keyboard_arrow_down)
                : (suffixIcon != null ? Icon(suffixIcon, size: 18.sp) : null),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableField({
    String? hint,
    String? initialValue,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isSmall = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12.sp : 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '₹ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isSmall ? 12.sp : 14.sp,
              fontWeight: isSmall ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PurchaseItem {
  String name;
  String hsn;
  double qty;
  String unit;
  double rate;
  double gstRate;

  PurchaseItem({
    required this.name,
    required this.hsn,
    required this.qty,
    this.unit = 'PCS',
    required this.rate,
    required this.gstRate,
  });
}
