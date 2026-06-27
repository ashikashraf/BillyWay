import 'package:flutter/material.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/masters/domain/controllers/master_data_controller.dart';
import 'package:billy_way/features/payments/domain/controllers/payment_controller.dart';

class NewPaymentPage extends StatefulWidget {
  const NewPaymentPage({super.key});

  @override
  State<NewPaymentPage> createState() => _NewPaymentPageState();
}

class _NewPaymentPageState extends State<NewPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  // State
  String _paymentType = 'RECEIPT'; // RECEIPT or PAYMENT
  String _paymentMode = 'BANK'; // CASH, BANK, UPI, CHEQUE
  Map<String, dynamic>? _selectedLedger;

  // Controllers
  final _paymentNumberController = TextEditingController(
    text: '(Auto-generated on save)',
  );
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceNoController = TextEditingController();
  final _notesController = TextEditingController();

  late MasterDataController _masterController;
  late PaymentController _paymentController;

  List<Map<String, dynamic>> _ledgers = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd MMM yyyy').format(DateTime.now());

    _masterController = getIt<MasterDataController>();
    _paymentController = getIt<PaymentController>();

    _masterController.masterDataNotifier.addListener(_onMasterDataChanged);

    if (!_masterController.isInitialized) {
      _masterController.initRealtimeSync();
    } else {
      _onMasterDataChanged();
    }
  }

  void _onMasterDataChanged() {
    final data = _masterController.masterDataNotifier.value;
    if (mounted) {
      setState(() {
        _ledgers = data['ledgers'] ?? [];
      });
    }
  }

  @override
  void dispose() {
    _masterController.masterDataNotifier.removeListener(_onMasterDataChanged);
    _paymentNumberController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _referenceNoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLedger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Party (Ledger)')),
      );
      return;
    }

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final parsedDate = DateFormat('dd MMM yyyy').parse(_dateController.text);
      final paymentNum =
          'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      await _paymentController.recordPayment(
        paymentNumber: paymentNum,
        ledgerId: _selectedLedger!['id'],
        paymentType: _paymentType,
        paymentMode: _paymentMode,
        amount: amount,
        paymentDate: parsedDate,
        referenceNo: _referenceNoController.text,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              _buildHeader(isMobile),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPaymentTypeToggle(),
                            SizedBox(height: 24.h),
                            Card(
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.payment,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Payment Details',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            'Payment Number',
                                            controller:
                                                _paymentNumberController,
                                            readOnly: true,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _selectDate(context),
                                            child: IgnorePointer(
                                              child: _buildTextField(
                                                'Date *',
                                                controller: _dateController,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Party (Ledger) *',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Autocomplete<Map<String, dynamic>>(
                                      displayStringForOption: (option) =>
                                          option['ledger_name']?.toString() ??
                                          '',
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                            if (textEditingValue.text.isEmpty) {
                                              return const Iterable<
                                                Map<String, dynamic>
                                              >.empty();
                                            }
                                            final query = textEditingValue.text
                                                .toLowerCase();
                                            return _ledgers.where((ledger) {
                                              final name =
                                                  ledger['ledger_name']
                                                      ?.toString()
                                                      .toLowerCase() ??
                                                  '';
                                              final group =
                                                  ledger['ledger_group']
                                                      ?.toString()
                                                      .toLowerCase() ??
                                                  '';
                                              final gstin =
                                                  ledger['gstin']
                                                      ?.toString()
                                                      .toLowerCase() ??
                                                  '';
                                              return name.contains(query) ||
                                                  group.contains(query) ||
                                                  gstin.contains(query);
                                            });
                                          },
                                      onSelected: (ledger) {
                                        setState(
                                          () => _selectedLedger = ledger,
                                        );
                                      },
                                      fieldViewBuilder:
                                          (
                                            context,
                                            controller,
                                            focusNode,
                                            onEditingComplete,
                                          ) {
                                            return TextFormField(
                                              controller: controller,
                                              focusNode: focusNode,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Search Customer/Vendor...',
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 16.w,
                                                      vertical: 12.h,
                                                    ),
                                              ),
                                              validator: (value) {
                                                if (_selectedLedger == null) {
                                                  return 'Please select a valid party from the list';
                                                }
                                                return null;
                                              },
                                            );
                                          },
                                    ),
                                    if (_selectedLedger != null) ...[
                                      SizedBox(height: 8.h),
                                      ListenableBuilder(
                                        listenable: _paymentController,
                                        builder: (context, _) {
                                          final bal = _paymentController
                                              .getBalanceForLedger(
                                                _selectedLedger!['id'],
                                              );
                                          return Text(
                                            'Current Balance: ₹${bal.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: bal > 0
                                                  ? AppColors.success
                                                  : AppColors.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    SizedBox(height: 16.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildTextField(
                                            'Amount *',
                                            controller: _amountController,
                                            prefix: '₹ ',
                                            isNumeric: true,
                                            validator: (v) =>
                                                v!.isEmpty ? 'Required' : null,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Payment Mode *',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              DropdownButtonFormField<String>(
                                                value: _paymentMode,
                                                decoration:
                                                    const InputDecoration(),
                                                items:
                                                    [
                                                          'CASH',
                                                          'BANK',
                                                          'UPI',
                                                          'CHEQUE',
                                                        ]
                                                        .map(
                                                          (e) =>
                                                              DropdownMenuItem(
                                                                value: e,
                                                                child: Text(e),
                                                              ),
                                                        )
                                                        .toList(),
                                                onChanged: (v) => setState(
                                                  () => _paymentMode = v!,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    _buildTextField(
                                      'Reference No (UTR / Cheque No)',
                                      controller: _referenceNoController,
                                    ),
                                    SizedBox(height: 16.h),
                                    _buildTextField(
                                      'Notes / Narration',
                                      controller: _notesController,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildStickyFooter(isMobile),
            ],
          ),
          ListenableBuilder(
            listenable: _paymentController,
            builder: (context, _) {
              if (_paymentController.isLoading) {
                return Container(
                  color: Colors.black26,
                  child: const Center(child: AppLoadingAnimation()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8.w),
          Text(
            'Record Payment',
            style: TextStyle(
              fontSize: isMobile ? 20.sp : 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeToggle() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _paymentType = 'RECEIPT'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _paymentType == 'RECEIPT'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Money In (Receipt)',
                  style: TextStyle(
                    color: _paymentType == 'RECEIPT'
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: _paymentType == 'RECEIPT'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _paymentType = 'PAYMENT'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _paymentType == 'PAYMENT'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Money Out (Payment)',
                  style: TextStyle(
                    color: _paymentType == 'PAYMENT'
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontWeight: _paymentType == 'PAYMENT'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    TextEditingController? controller,
    bool readOnly = false,
    int maxLines = 1,
    String? prefix,
    bool isNumeric = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: isNumeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          validator: validator,
          decoration: InputDecoration(
            prefixText: prefix,
            filled: readOnly,
            fillColor: readOnly
                ? AppColors.border.withValues(alpha: 0.3)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              SizedBox(width: 16.w),
              ElevatedButton.icon(
                onPressed: _savePayment,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Save Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _paymentType == 'RECEIPT'
                      ? AppColors.success
                      : AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
