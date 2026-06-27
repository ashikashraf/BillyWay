import 'package:flutter/material.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/masters/domain/controllers/master_data_controller.dart';
import 'package:billy_way/features/transfers/domain/controllers/transfer_controller.dart';
import 'package:billy_way/features/masters/presentation/pages/master_management_page.dart';
import 'package:billy_way/features/masters/presentation/widgets/smart_master_dropdown.dart';
import 'package:billy_way/features/stock/domain/controllers/stock_controller.dart';

class NewTransferPage extends StatefulWidget {
  const NewTransferPage({super.key});

  @override
  State<NewTransferPage> createState() => _NewTransferPageState();
}

class _TransferRow {
  final TextEditingController productCtr = TextEditingController();
  final TextEditingController qtyCtr = TextEditingController(text: '1');
  double? availableStock;
  
  void dispose() {
    productCtr.dispose();
    qtyCtr.dispose();
  }
}

class _NewTransferPageState extends State<NewTransferPage> {
  final _formKey = GlobalKey<FormState>();

  final _transferNumberController = TextEditingController(text: 'TRF/2026-27/0001');
  final _dateController = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _notesController = TextEditingController();
  
  String? _sourceWarehouseId;
  String? _destinationWarehouseId;

  final List<_TransferRow> _rows = [_TransferRow()];
  List<Map<String, dynamic>> _products = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    final data = getIt<MasterDataController>().masterDataNotifier.value;
    setState(() {
      _products = data['products'] ?? [];
    });
  }

  @override
  void dispose() {
    _transferNumberController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    for (var r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _onProductSelected(_TransferRow row, Map<String, dynamic> product) async {
    final productName = product['name'] ?? '';
    setState(() {
      row.productCtr.text = productName;
      row.availableStock = null;
    });

    final stock = await getIt<StockController>().getAvailableStock(productName);
    if (mounted) {
      setState(() {
        row.availableStock = stock;
      });
    }
  }

  Future<void> _saveTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_sourceWarehouseId == null || _destinationWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Source and Destination Warehouses'), backgroundColor: AppColors.error));
      return;
    }
    
    if (_sourceWarehouseId == _destinationWarehouseId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source and Destination Warehouses cannot be the same'), backgroundColor: AppColors.error));
      return;
    }

    if (_rows.isEmpty || _rows.every((r) => r.productCtr.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final items = _rows.where((r) => r.productCtr.text.isNotEmpty).map((r) {
        return {
          'product_name': r.productCtr.text,
          'qty': double.tryParse(r.qtyCtr.text) ?? 1.0,
        };
      }).toList();

      await getIt<TransferController>().createTransfer(
        transferNumber: _transferNumberController.text,
        date: DateTime.now(), // Simplified
        sourceWarehouseId: _sourceWarehouseId!,
        destinationWarehouseId: _destinationWarehouseId!,
        status: 'COMPLETED', // Directly completing to trigger ledger sync
        notes: _notesController.text,
        items: items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock Transfer completed successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
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
                        _buildTransferDetailsCard(isMobile),
                        SizedBox(height: 16.h),
                        _buildItemsTableCard(isMobile),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),
              ),
              _buildStickyFooter(isMobile),
            ],
          ),
          if (_isSaving)
            Container(color: Colors.black26, child: const Center(child: AppLoadingAnimation())),
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
          'Inter-Warehouse Transfer',
          style: TextStyle(
            fontSize: isMobile ? 20.sp : 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTransferDetailsCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text('Transfer Details', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              _buildTextField('Transfer Number', controller: _transferNumberController),
              SizedBox(height: 16.h),
              _buildTextField('Date', controller: _dateController, suffixIcon: Icons.calendar_today),
              SizedBox(height: 16.h),
              SmartMasterDropdown(
                module: MasterModule.warehouse,
                label: 'Source Warehouse',
                isMandatory: true,
                displayItem: (item) => item['warehouse_name'] ?? 'Unknown',
                onChanged: (v) => _sourceWarehouseId = v,
              ),
              SizedBox(height: 16.h),
              SmartMasterDropdown(
                module: MasterModule.warehouse,
                label: 'Destination Warehouse',
                isMandatory: true,
                displayItem: (item) => item['warehouse_name'] ?? 'Unknown',
                onChanged: (v) => _destinationWarehouseId = v,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildTextField('Transfer Number', controller: _transferNumberController)),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Date', controller: _dateController, suffixIcon: Icons.calendar_today)),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: SmartMasterDropdown(
                      module: MasterModule.warehouse,
                      label: 'Source Warehouse',
                      isMandatory: true,
                      displayItem: (item) => item['warehouse_name'] ?? 'Unknown',
                      onChanged: (v) => _sourceWarehouseId = v,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SmartMasterDropdown(
                      module: MasterModule.warehouse,
                      label: 'Destination Warehouse',
                      isMandatory: true,
                      displayItem: (item) => item['warehouse_name'] ?? 'Unknown',
                      onChanged: (v) => _destinationWarehouseId = v,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16.h),
            _buildTextField('Notes', controller: _notesController, hint: 'Optional transfer notes...'),
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
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text('Items to Transfer', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _rows.add(_TransferRow());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
              color: AppColors.divider.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Product Description', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Quantity', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold))),
                  SizedBox(width: 40.w),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rows.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildItemRow(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    var row = _rows[index];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (option) => option['name'] ?? '',
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return _products;
                    return _products.where((p) {
                      final name = (p['name'] ?? '').toLowerCase();
                      return name.contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (prod) => _onProductSelected(row, prod),
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    if (row.productCtr.text != controller.text && !focusNode.hasFocus) {
                      controller.text = row.productCtr.text;
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      style: TextStyle(fontSize: 14.sp),
                      decoration: const InputDecoration(
                        hintText: 'Search Item...',
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    );
                  },
                ),
                if (row.availableStock != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 4.w),
                    child: Text(
                      'Global Stock: ${row.availableStock}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: row.availableStock! <= 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: row.qtyCtr,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14.sp),
              decoration: const InputDecoration(
                hintText: 'Qty',
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20.sp),
            onPressed: () {
              setState(() => _rows.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {String? hint, String? initialValue, TextEditingController? controller, IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18.sp) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
          ElevatedButton.icon(
            onPressed: _saveTransfer,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Execute Transfer'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
            ),
          ),
        ],
      ),
    );
  }
}
