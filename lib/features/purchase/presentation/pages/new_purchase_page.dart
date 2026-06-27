import 'package:billy_way/features/masters/presentation/pages/master_management_page.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:billy_way/features/masters/presentation/widgets/smart_master_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/tax_engine.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/purchase/data/models/purchase_invoice.dart';
import 'package:billy_way/features/purchase/domain/controllers/purchase_controller.dart';
import 'package:billy_way/features/masters/domain/controllers/master_data_controller.dart';
import 'package:billy_way/features/settings/domain/controllers/settings_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewPurchasePage extends StatefulWidget {
  const NewPurchasePage({super.key});

  @override
  State<NewPurchasePage> createState() => _NewPurchasePageState();
}

class _PurchaseRow {
  final TextEditingController productCtr = TextEditingController();
  final TextEditingController hsnCtr = TextEditingController();
  final TextEditingController qtyCtr = TextEditingController(text: '1');
  final TextEditingController unitCtr = TextEditingController(text: 'PCS');
  final TextEditingController rateCtr = TextEditingController(text: '0');

  double gstRate = 18.0;
  double taxableValue = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double cessAmount = 0;

  void dispose() {
    productCtr.dispose();
    hsnCtr.dispose();
    qtyCtr.dispose();
    unitCtr.dispose();
    rateCtr.dispose();
  }
}

class _NewPurchasePageState extends State<NewPurchasePage> {
  final _formKey = GlobalKey<FormState>();

  // Master Data
  late final MasterDataController _masterController;
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _products = [];

  late final String _branchStateCode; // Default Branch State (Kerala)

  // Controllers
  final _internalRefController = TextEditingController(
    text: '(Auto-generated on save)',
  );
  final _vendorBillController = TextEditingController();
  final _dateController = TextEditingController();
  final _dueDateController = TextEditingController();

  final _vendorCtrl = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();

  final _supplyTypeController = TextEditingController(text: 'INTRA_STATE');
  final _statusController = TextEditingController(text: 'Unpaid');
  final _paymentMethodController = TextEditingController(text: 'Bank Transfer');

  final List<_PurchaseRow> _rows = [_PurchaseRow()];

  // Summary state
  double _subtotal = 0;
  double _totalTax = 0;
  double _totalAmount = 0;
  double _cgst = 0;
  double _sgst = 0;
  double _igst = 0;
  double _cess = 0;

  bool _isSaving = false;
  String? _warehouseId;

  @override
  void initState() {
    super.initState();
    final settings = getIt<SettingsController>();
    _branchStateCode = settings.branchStateCode;
    
    if (!settings.enableMultiWarehouse) {
      _warehouseId = settings.defaultWarehouseId;
    }
    _dateController.text = DateFormat('dd MMM yyyy').format(DateTime.now());
    _dueDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(DateTime.now().add(const Duration(days: 30)));

    _masterController = getIt<MasterDataController>();
    _masterController.masterDataNotifier.addListener(_onMasterDataChanged);

    if (!_masterController.isInitialized) {
      _masterController.initRealtimeSync();
    } else {
      _onMasterDataChanged();
    }

    _calculateTotals();
  }

  void _onMasterDataChanged() {
    final data = _masterController.masterDataNotifier.value;
    if (mounted) {
      setState(() {
        _vendors = data['ledgers'] ?? [];
        _products = data['products'] ?? [];
        
        final settings = getIt<SettingsController>();
        if (!settings.enableMultiWarehouse && _warehouseId == null) {
          final warehouses = data['warehouses'] as List?;
          if (warehouses != null && warehouses.isNotEmpty) {
            _warehouseId = settings.defaultWarehouseId ?? warehouses.first['id'];
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _masterController.masterDataNotifier.removeListener(_onMasterDataChanged);
    _internalRefController.dispose();
    _vendorBillController.dispose();
    _dateController.dispose();
    _dueDateController.dispose();
    _vendorCtrl.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _supplyTypeController.dispose();
    for (var r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _onVendorSelected(Map<String, dynamic> vendor) {
    setState(() {
      _vendorCtrl.text = vendor['name'] ?? '';
      _gstinController.text = vendor['gstin'] ?? '';
      _addressController.text = vendor['address'] ?? '';

      String vendorStateCode = vendor['state_code'] ?? '';
      if (vendorStateCode.isEmpty && _gstinController.text.length >= 2) {
        vendorStateCode = _gstinController.text.substring(0, 2);
      }

      if (vendorStateCode.isEmpty || vendorStateCode == _branchStateCode) {
        _supplyTypeController.text = 'INTRA_STATE';
      } else {
        _supplyTypeController.text = 'INTER_STATE';
      }

      _calculateTotals();
    });
  }

  void _calculateTotals() {
    List<Map<String, dynamic>> itemsList = _rows.map((row) {
      return {
        'quantity': row.qtyCtr.text,
        'rate': row.rateCtr.text,
        'gst_rate': row.gstRate,
        'cess_rate': 0.0,
      };
    }).toList();

    String vendorStateCode = '';
    if (_gstinController.text.length >= 2) {
      vendorStateCode = _gstinController.text.substring(0, 2);
    }

    final result = TaxEngine.computeInvoiceTax(
      items: itemsList,
      branchStateCode: _branchStateCode,
      partyStateCode: vendorStateCode,
    );

    for (int i = 0; i < _rows.length; i++) {
      _rows[i].taxableValue = itemsList[i]['taxable_value'] ?? 0.0;
      _rows[i].cgstAmount = itemsList[i]['cgst_amount'] ?? 0.0;
      _rows[i].sgstAmount = itemsList[i]['sgst_amount'] ?? 0.0;
      _rows[i].igstAmount = itemsList[i]['igst_amount'] ?? 0.0;
      _rows[i].cessAmount = itemsList[i]['cess_amount'] ?? 0.0;
    }

    setState(() {
      _supplyTypeController.text = result['supply_type'];
      _subtotal = result['taxableValue'];
      _cgst = result['cgstTotal'];
      _sgst = result['sgstTotal'];
      _igst = result['igstTotal'];
      _cess = result['cessTotal'];
      _totalTax = _cgst + _sgst + _igst + _cess;
      _totalAmount = result['grandTotal'];
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rows.isEmpty || _rows.every((r) => r.productCtr.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final settings = getIt<SettingsController>();
    if (!settings.enableMultiWarehouse && _warehouseId == null) {
       final warehouses = _masterController.masterDataNotifier.value['warehouses'] as List?;
       if (warehouses != null && warehouses.isNotEmpty) {
         _warehouseId = settings.defaultWarehouseId ?? warehouses.first['id'];
       }
    }

    if (settings.enableMultiWarehouse && _warehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Warehouse'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final items = _rows.where((r) => r.productCtr.text.isNotEmpty).map((r) {
        return PurchaseInvoiceItem(
          productName: r.productCtr.text,
          hsnSacCode: r.hsnCtr.text,
          qty: double.tryParse(r.qtyCtr.text) ?? 1,
          rate: double.tryParse(r.rateCtr.text) ?? 0,
          gstRate: r.gstRate,
          taxableValue: r.taxableValue,
          cgstAmount: r.cgstAmount,
          sgstAmount: r.sgstAmount,
          igstAmount: r.igstAmount,
          cessAmount: r.cessAmount,
        );
      }).toList();

      final finYear = '2026-27';
      final sequence = await Supabase.instance.client.rpc(
        'get_next_document_number',
        params: {
          'p_doc_type': 'PURCHASE_INVOICE',
          'p_fin_year': finYear,
          'p_prefix': 'PUR/',
        },
      );

      _internalRefController.text = sequence as String;

      final invoice = PurchaseInvoice(
        internalRefNo: _internalRefController.text,
        vendorBillNo: _vendorBillController.text.isEmpty
            ? null
            : _vendorBillController.text,
        date: DateFormat('dd MMM yyyy').parse(_dateController.text),
        dueDate: DateFormat('dd MMM yyyy').parse(_dueDateController.text),
        vendorName: _vendorCtrl.text.isEmpty
            ? 'Unknown Vendor'
            : _vendorCtrl.text,
        gstin: _gstinController.text,
        supplyType: _supplyTypeController.text,
        items: items,
        subtotal: _subtotal,
        cgst: _cgst,
        sgst: _sgst,
        igst: _igst,
        cess: _cess,
        totalTax: _totalTax,
        totalAmount: _totalAmount,
        status: _statusController.text,
        warehouseId: _warehouseId,
      );

      await getIt<PurchaseController>().savePurchaseInvoice(invoice);

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Purchase Bill Saved! ITC Ledger updated automatically.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving purchase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 1100;
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
            Container(
              color: Colors.black26,
              child: const Center(child: AppLoadingAnimation()),
            ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record New Purchase Bill',
                style: TextStyle(
                  fontSize: isMobile ? 20.sp : 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Automatically updates ITC Ledger',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Vendor Bill No',
                    controller: _vendorBillController,
                    hint: 'As per vendor invoice',
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTextField(
                    'Internal Ref #',
                    controller: _internalRefController,
                    readOnly: true,
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
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _supplyTypeController.text,
                    decoration: InputDecoration(
                      labelText: 'Supply Type',
                      labelStyle: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'INTRA_STATE',
                        child: Text('Intra-State (CGST+SGST)'),
                      ),
                      DropdownMenuItem(
                        value: 'INTER_STATE',
                        child: Text('Inter-State (IGST)'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _supplyTypeController.text = v!;
                        _calculateTotals();
                      });
                    },
                  ),
                ),
                if (getIt<SettingsController>().enableMultiWarehouse) ...[
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SmartMasterDropdown(
                      module: MasterModule.warehouse,
                      label: 'Warehouse',
                      isMandatory: true,
                      displayItem: (item) => item['warehouse_name'] ?? 'Unknown',
                      onChanged: (v) {
                        setState(() => _warehouseId = v);
                      },
                    ),
                  ),
                ],
              ],
            ),
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
            Row(
              children: [
                Expanded(flex: 2, child: _buildVendorAutocomplete()),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTextField(
                    'Vendor GSTIN',
                    controller: _gstinController,
                    hint: '27AAAAA0000A1Z5',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              'Vendor Address',
              controller: _addressController,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendor Name',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.sp),
        Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (option) =>
              option['ledger_name'] ??
              option['party_name'] ??
              option['customer_name'] ??
              option['name'] ??
              '',
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return _vendors;
            return _vendors.where((c) {
              final name =
                  ((c['ledger_name'] ??
                          c['party_name'] ??
                          c['customer_name'] ??
                          c['name'] ??
                          ''))
                      .toLowerCase();
              final gstin = (c['gstin'] ?? '').toLowerCase();
              final query = textEditingValue.text.toLowerCase();
              return name.contains(query) || gstin.contains(query);
            });
          },
          onSelected: _onVendorSelected,
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 250, maxWidth: 300.w),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final partyName =
                          option['ledger_name'] ??
                          option['party_name'] ??
                          option['customer_name'] ??
                          option['name'] ??
                          '';
                      return ListTile(
                        title: Text(
                          partyName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                          ),
                        ),
                        subtitle:
                            option['gstin'] != null &&
                                option['gstin'].isNotEmpty
                            ? Text(
                                option['gstin'],
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                              )
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                if (_vendorCtrl.text != controller.text &&
                    !focusNode.hasFocus) {
                  controller.text = _vendorCtrl.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    hintText: 'Search Vendor...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  onChanged: (val) {
                    _vendorCtrl.text = val;
                  },
                );
              },
        ),
      ],
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
                      _rows.add(_PurchaseRow());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildTableHead(),
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

  Widget _buildTableHead() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      color: AppColors.divider.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildTableColText('Item Description')),
          Expanded(flex: 2, child: _buildTableColText('HSN')),
          Expanded(child: _buildTableColText('Qty')),
          Expanded(child: _buildTableColText('Unit')),
          Expanded(flex: 2, child: _buildTableColText('Rate')),
          Expanded(flex: 2, child: _buildTableColText('GST %')),
          Expanded(flex: 2, child: _buildTableColText('Taxable Val')),
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
    var row = _rows[index];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (opt) => opt['name'] ?? '',
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return _products;
                return _products.where(
                  (p) => (p['name'] ?? '').toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (product) {
                setState(() {
                  row.productCtr.text = product['name'] ?? '';
                  row.hsnCtr.text =
                      product['hsn_sac_code'] ?? product['hsn'] ?? '';
                  row.rateCtr.text =
                      (product['purchase_price'] ?? product['price'] ?? 0)
                          .toString();
                  row.gstRate =
                      double.tryParse(
                        product['gst_rate']?.toString() ?? '18',
                      ) ??
                      18.0;
                  row.unitCtr.text = product['unit'] ?? 'PCS';
                  _calculateTotals();
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                    if (row.productCtr.text != controller.text &&
                        !focusNode.hasFocus) {
                      controller.text = row.productCtr.text;
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: const InputDecoration(
                        hintText: 'Search Product...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(),
                      ),
                      onChanged: (val) {
                        row.productCtr.text = val;
                      },
                    );
                  },
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.hsnCtr,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'HSN',
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextFormField(
              controller: row.qtyCtr,
              onChanged: (v) => _calculateTotals(),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextFormField(
              controller: row.unitCtr,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.rateCtr,
              onChanged: (v) => _calculateTotals(),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: row.gstRate,
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
                  setState(() => row.gstRate = v!);
                  _calculateTotals();
                },
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              '₹ ${row.taxableValue.toStringAsFixed(2)}',
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
              setState(() => _rows.removeAt(index));
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
                _buildSummaryRow('Input Tax Credit (ITC)', _totalTax),
                const Divider(height: 32),
                if (_supplyTypeController.text == 'INTRA_STATE') ...[
                  _buildSummaryRow('CGST (ITC)', _cgst, isSmall: true),
                  _buildSummaryRow('SGST (ITC)', _sgst, isSmall: true),
                ] else ...[
                  _buildSummaryRow('IGST (ITC)', _igst, isSmall: true),
                ],
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
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 16.w,
        runSpacing: 8.h,
        children: [
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.attach_file_outlined),
            label: const Text('Attach Bill'),
          ),
          ElevatedButton.icon(
            onPressed: _savePurchase,
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
    bool readOnly = false,
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
          readOnly: isDropdown || readOnly,
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
