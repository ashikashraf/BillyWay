import 'package:billy_way/features/masters/presentation/pages/master_management_page.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:billy_way/features/masters/presentation/widgets/smart_master_dropdown.dart';
import 'package:billy_way/features/sales/data/models/sales_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/sales/domain/controllers/sales_controller.dart';
import 'package:billy_way/features/masters/domain/controllers/master_data_controller.dart';
import 'package:billy_way/features/settings/domain/controllers/settings_controller.dart';
import 'package:billy_way/features/stock/domain/controllers/stock_controller.dart';
import 'package:billy_way/features/sales/presentation/widgets/invoice_preview_widget.dart';
import 'package:billy_way/core/utils/tax_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewInvoicePage extends StatefulWidget {
  const NewInvoicePage({super.key});

  @override
  State<NewInvoicePage> createState() => _NewInvoicePageState();
}

class _InvoiceRow {
  final TextEditingController productCtr = TextEditingController();
  final TextEditingController hsnCtr = TextEditingController();
  final TextEditingController qtyCtr = TextEditingController(text: '1');
  final TextEditingController unitCtr = TextEditingController(text: 'PCS');
  final TextEditingController rateCtr = TextEditingController(text: '0');

  double gstRate = 18.0;
  double? availableStock;

  // Tax breakdown
  double taxableValue = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double cessAmount = 0;

  final FocusNode focusNode = FocusNode();

  void dispose() {
    productCtr.dispose();
    hsnCtr.dispose();
    qtyCtr.dispose();
    unitCtr.dispose();
    rateCtr.dispose();
    focusNode.dispose();
  }
}

class _NewInvoicePageState extends State<NewInvoicePage> {
  final _formKey = GlobalKey<FormState>();

  // Master Data
  late final MasterDataController _masterController;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];

  // Branch State Code (Dynamically fetched from Settings)
  late final String _branchStateCode;

  // Invoice Meta
  final _invoiceNumberController = TextEditingController(
    text: '(Auto-generated on save)',
  );
  final _poNumberController = TextEditingController();
  final _dateController = TextEditingController();
  final _dueDateController = TextEditingController();

  // Customer Info
  final _customerCtrl = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstinController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _shippingAddressController = TextEditingController();

  // Payment & Status
  final _paymentMethodController = TextEditingController(text: 'Bank Transfer');
  final _statusController = TextEditingController(text: 'Unpaid');
  final _invoiceTypeController = TextEditingController(text: 'B2B');
  final _supplyTypeController = TextEditingController(text: 'INTRA_STATE');
  bool _reverseCharge = false;

  final List<_InvoiceRow> _rows = [_InvoiceRow()];

  // Summary
  double _subtotal = 0;
  double _totalTax = 0;
  double _totalAmount = 0;
  double _cgst = 0;
  double _sgst = 0;
  double _igst = 0;

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
    ).format(DateTime.now().add(const Duration(days: 15)));

    _masterController = getIt<MasterDataController>();
    _masterController.masterDataNotifier.addListener(_onMasterDataChanged);

    // Ensure master data is synced
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
        _customers = data['ledgers'] ?? [];
        _products = data['products'] ?? [];

        final settings = getIt<SettingsController>();
        if (!settings.enableMultiWarehouse && _warehouseId == null) {
          final warehouses = data['warehouses'] as List?;
          if (warehouses != null && warehouses.isNotEmpty) {
            _warehouseId =
                settings.defaultWarehouseId ?? warehouses.first['id'];
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _masterController.masterDataNotifier.removeListener(_onMasterDataChanged);
    _invoiceNumberController.dispose();
    _poNumberController.dispose();
    _dateController.dispose();
    _dueDateController.dispose();
    _customerCtrl.dispose();
    _mobileController.dispose();
    _gstinController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _paymentMethodController.dispose();
    _statusController.dispose();
    _invoiceTypeController.dispose();
    _supplyTypeController.dispose();
    for (var r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _onCustomerSelected(Map<String, dynamic> customer) {
    setState(() {
      _customerCtrl.text = customer['name'] ?? '';
      _mobileController.text = customer['phone'] ?? customer['mobile'] ?? '';
      _gstinController.text = customer['gstin'] ?? '';
      _billingAddressController.text = customer['address'] ?? '';

      // Auto-detect supply type based on GSTIN
      String custStateCode = customer['state_code'] ?? '';
      if (custStateCode.isEmpty && _gstinController.text.length >= 2) {
        custStateCode = _gstinController.text.substring(0, 2);
      }

      if (custStateCode.isEmpty || custStateCode == _branchStateCode) {
        _supplyTypeController.text = 'INTRA_STATE';
      } else {
        _supplyTypeController.text = 'INTER_STATE';
      }

      // Auto-detect B2B vs B2C
      if (_gstinController.text.length == 15) {
        _invoiceTypeController.text = 'B2B';
      } else {
        _invoiceTypeController.text = 'B2C';
      }

      _calculateTotals();
    });
  }

  void _onProductSelected(_InvoiceRow row, Map<String, dynamic> product) async {
    final productName = product['name'] ?? '';
    setState(() {
      row.productCtr.text = productName;
      row.hsnCtr.text = product['hsn_sac_code'] ?? product['hsn'] ?? '';
      row.rateCtr.text = (product['sales_price'] ?? product['price'] ?? 0)
          .toString();
      row.gstRate =
          double.tryParse(product['gst_rate']?.toString() ?? '18') ?? 18.0;
      row.unitCtr.text = product['unit'] ?? 'PCS';
      row.availableStock = null; // Reset while loading
      _calculateTotals();
    });

    final stock = await getIt<StockController>().getAvailableStock(
      productName,
      warehouseId: _warehouseId,
    );
    if (mounted) {
      setState(() {
        row.availableStock = stock;
      });
    }
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

    String custStateCode = '';
    if (_gstinController.text.length >= 2) {
      custStateCode = _gstinController.text.substring(0, 2);
    }

    final result = TaxEngine.computeInvoiceTax(
      items: itemsList,
      branchStateCode: _branchStateCode,
      partyStateCode: custStateCode,
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
      _totalTax = _cgst + _sgst + _igst + result['cessTotal'];
      _totalAmount = result['grandTotal'];
    });
  }

  Future<void> _saveInvoice({bool showPreview = true}) async {
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
      final warehouses =
          _masterController.masterDataNotifier.value['warehouses'] as List?;
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
        return InvoiceItem(
          name: r.productCtr.text,
          hsn: r.hsnCtr.text,
          qty: double.tryParse(r.qtyCtr.text) ?? 1,
          unit: r.unitCtr.text,
          rate: double.tryParse(r.rateCtr.text) ?? 0,
          gstRate: r.gstRate,
          taxableValue: r.taxableValue,
          cgstAmount: r.cgstAmount,
          sgstAmount: r.sgstAmount,
          igstAmount: r.igstAmount,
          cessAmount: r.cessAmount,
        );
      }).toList();

      // Automatically generate strict sequential invoice number
      final finYear =
          '2026-27'; // Should be dynamically calculated based on current date
      final invoiceSequence = await Supabase.instance.client.rpc(
        'get_next_document_number',
        params: {
          'p_doc_type': 'SALES_INVOICE',
          'p_fin_year': finYear,
          'p_prefix': 'INV/',
        },
      );

      _invoiceNumberController.text = invoiceSequence as String;

      final invoice = SalesInvoice(
        invoiceNumber: _invoiceNumberController.text,
        poNumber: _poNumberController.text.isEmpty
            ? null
            : _poNumberController.text,
        date: DateFormat('dd MMM yyyy').parse(_dateController.text),
        dueDate: DateFormat('dd MMM yyyy').parse(_dueDateController.text),
        customerName: _customerCtrl.text.isEmpty
            ? 'Walk-in Customer'
            : _customerCtrl.text,
        mobileNumber: _mobileController.text,
        gstin: _gstinController.text,
        billingAddress: _billingAddressController.text,
        shippingAddress: _shippingAddressController.text,
        items: items,
        subtotal: _subtotal,
        totalTax: _totalTax,
        cgst: _cgst,
        sgst: _sgst,
        igst: _igst,
        totalAmount: _totalAmount,
        paymentMethod: _paymentMethodController.text,
        status: _statusController.text,
        invoiceType: _invoiceTypeController.text,
        supplyType: _supplyTypeController.text,
        reverseCharge: _reverseCharge,
        warehouseId: _warehouseId,
      );

      final savedInvoice = await getIt<SalesController>().saveInvoice(invoice);

      setState(() => _isSaving = false);

      if (mounted && savedInvoice != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax Invoice saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (showPreview) {
          showDialog(
            context: context,
            builder: (context) => InvoicePreviewWidget(invoice: savedInvoice),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e'),
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
                          _buildInvoiceDetailsCard(isMobile),
                          SizedBox(height: 16.h),
                          _buildCustomerDetailsCard(isMobile),
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
                                    _buildInvoiceDetailsCard(isMobile),
                                    SizedBox(height: 24.h),
                                    _buildCustomerDetailsCard(isMobile),
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
                'Create Tax Invoice',
                style: TextStyle(
                  fontSize: isMobile ? 20.sp : 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'GST Compliant Billing',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) _buildStatusChip(_statusController.text),
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

  Widget _buildInvoiceDetailsCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.description_outlined, 'Invoice Details'),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Invoice Number',
                    controller: _invoiceNumberController,
                    readOnly: true,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTextField(
                    'PO Number',
                    controller: _poNumberController,
                    hint: 'Optional PO #',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Invoice Date',
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
                    value: _invoiceTypeController.text,
                    decoration: InputDecoration(
                      labelText: 'Invoice Type',
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
                        value: 'B2B',
                        child: Text('B2B (Registered)'),
                      ),
                      DropdownMenuItem(
                        value: 'B2C',
                        child: Text('B2C (Unregistered)'),
                      ),
                      DropdownMenuItem(
                        value: 'EXPORT',
                        child: Text('Export/Zero Rated'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _invoiceTypeController.text = v!),
                  ),
                ),
                SizedBox(width: 16.w),
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
                        _calculateTotals(); // Re-calculate taxes on supply type change
                      });
                    },
                  ),
                ),
              ],
            ),
            if (getIt<SettingsController>().enableMultiWarehouse) ...[
              SizedBox(height: 16.h),
              SmartMasterDropdown(
                module: MasterModule.warehouse,
                label: 'Warehouse',
                isMandatory: true,
                displayItem: (item) => item['warehouse_name'] ?? 'Unknown',
                onChanged: (v) {
                  setState(() => _warehouseId = v);
                  // Refresh stock for all currently selected items
                  for (var r in _rows) {
                    if (r.productCtr.text.isNotEmpty) {
                      _onProductSelected(r, {'name': r.productCtr.text});
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.person_outline, 'Bill To (Customer)'),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(flex: 2, child: _buildCustomerAutocomplete()),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTextField(
                    'Mobile Number',
                    controller: _mobileController,
                    prefixText: '+91 ',
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTextField(
                    'GSTIN',
                    controller: _gstinController,
                    hint: '15-digit GSTIN',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Billing Address',
                    controller: _billingAddressController,
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTextField(
                    'Shipping Address',
                    controller: _shippingAddressController,
                    maxLines: 2,
                    hint: 'Same as billing',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Name',
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
            if (textEditingValue.text.isEmpty) return _customers;
            return _customers.where((c) {
              final name =
                  (c['ledger_name'] ??
                          c['party_name'] ??
                          c['customer_name'] ??
                          c['name'] ??
                          '')
                      .toLowerCase();
              final gstin = (c['gstin'] ?? '').toLowerCase();
              final query = textEditingValue.text.toLowerCase();
              return name.contains(query) || gstin.contains(query);
            });
          },
          onSelected: _onCustomerSelected,
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
                // Keep controller in sync if modified elsewhere
                if (_customerCtrl.text != controller.text &&
                    !focusNode.hasFocus) {
                  controller.text = _customerCtrl.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    hintText: 'Search Party...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  onChanged: (val) {
                    _customerCtrl.text = val;
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                  Icons.list_alt_outlined,
                  'Item Details & HSN',
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _rows.add(_InvoiceRow());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
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
          Expanded(
            flex: 3,
            child: _buildTableColText('Item / Service Description'),
          ),
          Expanded(flex: 2, child: _buildTableColText('HSN/SAC')),
          Expanded(child: _buildTableColText('Qty')),
          Expanded(flex: 1, child: _buildTableColText('Unit')),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductAutocomplete(row),
                if (row.availableStock != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 4.w),
                    child: Text(
                      _warehouseId != null
                          ? 'Stock in Selected Warehouse: ${row.availableStock}'
                          : 'Global Stock: ${row.availableStock}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: row.availableStock! <= 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _buildTableField(hint: 'HSN/SAC', controller: row.hsnCtr),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildTableField(
              controller: row.qtyCtr,
              onChanged: (v) => _calculateTotals(),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(flex: 1, child: _buildTableField(controller: row.unitCtr)),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _buildTableField(
              controller: row.rateCtr,
              onChanged: (v) => _calculateTotals(),
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

  Widget _buildProductAutocomplete(_InvoiceRow row) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) =>
          option['product_name'] ??
          option['item_name'] ??
          option['particular'] ??
          option['name'] ??
          '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return _products;
        return _products.where((p) {
          final name =
              (p['product_name'] ??
                      p['item_name'] ??
                      p['particular'] ??
                      p['name'] ??
                      '')
                  .toLowerCase();
          final hsn = (p['hsn_sac_code'] ?? '').toLowerCase();
          final query = textEditingValue.text.toLowerCase();
          return name.contains(query) || hsn.contains(query);
        });
      },
      onSelected: (prod) => _onProductSelected(row, prod),
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
                  final productName =
                      option['product_name'] ??
                      option['item_name'] ??
                      option['particular'] ??
                      option['name'] ??
                      '';
                  return ListTile(
                    title: Text(
                      productName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                      ),
                    ),
                    subtitle: option['hsn_sac_code'] != null
                        ? Text(
                            'HSN: ${option['hsn_sac_code']}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                            ),
                          )
                        : null,
                    trailing: Text(
                      '₹${option['sales_price'] ?? option['price'] ?? 0}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        if (row.productCtr.text != controller.text && !focusNode.hasFocus) {
          controller.text = row.productCtr.text;
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Search Item...',
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
          ),
          onChanged: (val) {
            row.productCtr.text = val;
          },
        );
      },
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
                _buildSectionTitle(
                  Icons.account_balance_wallet_outlined,
                  'Tax Summary',
                ),
                SizedBox(height: 24.h),
                _buildSummaryRow('Taxable Value', _subtotal),
                const Divider(height: 32),
                if (_supplyTypeController.text == 'INTRA_STATE') ...[
                  _buildSummaryRow('CGST', _cgst, isSmall: true),
                  _buildSummaryRow('SGST', _sgst, isSmall: true),
                ] else ...[
                  _buildSummaryRow('IGST', _igst, isSmall: true),
                ],
                _buildSummaryRow('Total Tax', _totalTax),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total',
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
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(Icons.settings_outlined, 'Additional Terms'),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Checkbox(
                      value: _reverseCharge,
                      onChanged: (v) =>
                          setState(() => _reverseCharge = v ?? false),
                    ),
                    Text(
                      'Reverse Charge (RCM)',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  'Payment Terms',
                  controller: _paymentMethodController,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 16.w,
        runSpacing: 8.h,
        children: [
          ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _saveInvoice(),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(
              _isSaving ? 'Validating & Saving...' : 'Generate Tax Invoice',
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
    TextEditingController? controller,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? prefixText,
    int maxLines = 1,
    bool isDropdown = false,
    bool readOnly = false,
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
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isDropdown || readOnly,
          onChanged: onChanged,
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
          validator: (value) {
            if (label == 'Invoice Number' && (value == null || value.isEmpty))
              return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTableField({
    String? hint,
    TextEditingController? controller,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
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
