import 'package:flutter/material.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/quotation/domain/controllers/quotation_controller.dart';
import 'package:billy_way/features/quotation/data/models/quotation.dart';
import 'package:billy_way/features/quotation/presentation/widgets/quotation_preview_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class NewQuotationPage extends StatefulWidget {
  const NewQuotationPage({super.key});

  @override
  State<NewQuotationPage> createState() => _NewQuotationPageState();
}

// ─── per-row state ────────────────────────────────────────────────────────────
class _ItemRow {
  final TextEditingController nameCtr = TextEditingController();
  final TextEditingController hsnCtr = TextEditingController();
  final TextEditingController qtyCtr = TextEditingController(text: '1');
  final TextEditingController rateCtr = TextEditingController(text: '0');
  final TextEditingController unitCtr = TextEditingController();
  final TextEditingController discCtr = TextEditingController(text: '0');
  final LayerLink layerLink = LayerLink();

  void dispose() {
    nameCtr.dispose();
    hsnCtr.dispose();
    qtyCtr.dispose();
    rateCtr.dispose();
    unitCtr.dispose();
    discCtr.dispose();
  }
}

class _NewQuotationPageState extends State<NewQuotationPage> {
  final _formKey = GlobalKey<FormState>();

  // Header controllers
  final _quotNoCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _shippingCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  String _status = 'Draft';

  final List<_ItemRow> _rows = [_ItemRow()];

  bool _isSaving = false;
  bool _isLoadingItems = false;

  // ── product catalog loaded from Supabase ──────────────────────────────────
  List<Map<String, dynamic>> _catalog = [];
  // track which row's overlay is open
  int? _activeOverlayRow;
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
    // auto-generate quotation number
    final now = DateTime.now();
    _quotNoCtrl.text =
        'QUO-${now.year}-${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';
  }

  @override
  void dispose() {
    _removeOverlay();
    _quotNoCtrl.dispose();
    _customerCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _shippingCtrl.dispose();
    _notesCtrl.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchCatalog() async {
    setState(() => _isLoadingItems = true);
    try {
      final res = await Supabase.instance.client
          .from('products')
          .select()
          .order('product_name', ascending: true);
      if (mounted) {
        setState(() {
          _catalog = List<Map<String, dynamic>>.from(res);
          _isLoadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  // ── overlay helpers ───────────────────────────────────────────────────────

  void _showOverlay(int rowIndex, String query) {
    _removeOverlay();
    _activeOverlayRow = rowIndex;

    _filtered = _catalog.where((p) {
      final name = (p['product_name'] ?? '').toString().toLowerCase();
      final hsn = (p['hsn_code'] ?? '').toString().toLowerCase();
      final q = query.toLowerCase();
      return name.contains(q) || hsn.contains(q);
    }).toList();

    if (_filtered.isEmpty) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: 380,
        child: CompositedTransformFollower(
          link: _rows[rowIndex].layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 44),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: _filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final p = _filtered[i];
                  final name = p['product_name'] ?? '';
                  final hsn = p['hsn_code'] ?? '';
                  final unit = p['unit'] ?? p['uom'] ?? '';
                  final rate = (p['sale_price'] ?? p['selling_price'] ?? 0.0)
                      .toDouble();
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'HSN: $hsn  •  $unit',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      '₹${rate.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _selectProduct(rowIndex, p),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _activeOverlayRow = null;
  }

  void _selectProduct(int rowIndex, Map<String, dynamic> p) {
    final row = _rows[rowIndex];
    final name = p['product_name'] ?? '';
    final hsn = p['hsn_code'] ?? '';
    final unit = p['unit'] ?? p['uom'] ?? '';
    final rate = (p['sale_price'] ?? p['selling_price'] ?? 0.0).toDouble();

    setState(() {
      row.nameCtr.text = name;
      row.hsnCtr.text = hsn;
      row.unitCtr.text = unit;
      row.rateCtr.text = rate.toStringAsFixed(2);
    });
    _removeOverlay();
  }

  // ── calculations ───────────────────────────────────────────────────────────

  double _rowAmount(_ItemRow row) {
    final qty = double.tryParse(row.qtyCtr.text) ?? 0;
    final rate = double.tryParse(row.rateCtr.text) ?? 0;
    final disc = double.tryParse(row.discCtr.text) ?? 0;
    return qty * rate * (1 - disc / 100);
  }

  double get _subtotal => _rows.fold(0, (sum, r) => sum + _rowAmount(r));

  // ── save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final items = _rows
          .where((r) => r.nameCtr.text.isNotEmpty)
          .map(
            (r) => QuotationItem(
              name: r.nameCtr.text,
              hsn: r.hsnCtr.text,
              qty: double.tryParse(r.qtyCtr.text) ?? 1,
              unit: r.unitCtr.text,
              rate: double.tryParse(r.rateCtr.text) ?? 0,
              discount: double.tryParse(r.discCtr.text) ?? 0,
              amount: _rowAmount(r),
            ),
          )
          .toList();

      final quotation = Quotation(
        id: '',
        quotationNumber: _quotNoCtrl.text,
        date: _date,
        validUntil: _validUntil,
        customerName: _customerCtrl.text,
        mobileNumber: _mobileCtrl.text,
        billingAddress: _addressCtrl.text,
        shippingAddress: _shippingCtrl.text,
        subtotal: _subtotal,
        notes: _notesCtrl.text,
        status: _status,
        items: items,
      );

      await getIt<QuotationController>().saveQuotation(quotation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quotation saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/quotations');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _removeOverlay,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 24.h),
                      _buildHeaderCard(),
                      SizedBox(height: 16.h),
                      _buildCustomerCard(),
                      SizedBox(height: 16.h),
                      _buildItemsCard(),
                      SizedBox(height: 16.h),
                      _buildNotesCard(),
                      SizedBox(height: 16.h),
                      _buildSummaryCard(),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/quotations'),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'New Quotation',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pending_actions_outlined,
                size: 14.sp,
                color: AppColors.warning,
              ),
              SizedBox(width: 6.w),
              Text(
                'TAX-FREE QUOTATION',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header Info Card ───────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    final quotNoField = _labelField('Quotation No.', _quotNoCtrl);
    final dateField = _datePicker('Date', _date, (d) => setState(() => _date = d));
    final validUntilField = _datePicker('Valid Until', _validUntil, (d) => setState(() => _validUntil = d));
    final statusField = _statusPicker();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.w : 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.receipt_long_outlined, 'Quotation Details'),
            SizedBox(height: 16.h),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: quotNoField),
                  SizedBox(width: 16.w),
                  Expanded(child: dateField),
                  SizedBox(width: 16.w),
                  Expanded(child: validUntilField),
                  SizedBox(width: 16.w),
                  Expanded(child: statusField),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  quotNoField,
                  SizedBox(height: 16.h),
                  dateField,
                  SizedBox(height: 16.h),
                  validUntilField,
                  SizedBox(height: 16.h),
                  statusField,
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: [
            'Draft',
            'Sent',
            'Approved',
            'Rejected',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
      ],
    );
  }

  // ── Customer Card ──────────────────────────────────────────────────────────

  Widget _buildCustomerCard() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final nameField = _labelField('Customer Name', _customerCtrl, required: true);
    final mobileField = _labelField('Mobile Number', _mobileCtrl);
    final billingField = _labelField('Billing Address', _addressCtrl, maxLines: 2);
    final shippingField = _labelField('Shipping Address', _shippingCtrl, maxLines: 2);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.w : 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.person_outline, 'Customer Details'),
            SizedBox(height: 16.h),
            if (isDesktop) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nameField),
                  SizedBox(width: 16.w),
                  Expanded(child: mobileField),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: billingField),
                  SizedBox(width: 16.w),
                  Expanded(child: shippingField),
                ],
              ),
            ] else ...[
              nameField,
              SizedBox(height: 12.h),
              mobileField,
              SizedBox(height: 12.h),
              billingField,
              SizedBox(height: 12.h),
              shippingField,
            ],
          ],
        ),
      ),
    );
  }

  // ── Items Card ─────────────────────────────────────────────────────────────

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle(Icons.list_alt_outlined, 'Items'),
                if (_isLoadingItems)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.secondary,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => _rows.add(_ItemRow())),
                    icon: Icon(Icons.add, size: 16.sp),
                    label: const Text('Add Row'),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < 800 ? 800 : constraints.maxWidth,
                    ),
                    child: SizedBox(
                      width: constraints.maxWidth < 800 ? 800 : constraints.maxWidth,
                      child: Column(
                        children: [
                          // Table header
                          _buildTableHeader(),
                          const Divider(height: 1),
                          // Item rows
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rows.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (_, i) => _buildItemRow(i),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(width: 28.w), // delete btn
          SizedBox(width: 8.w),
          Expanded(
            flex: 4,
            child: Text(
              'Item Name',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              'HSN',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              'Qty',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              'Unit',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              'Rate ₹',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              'Disc %',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int i) {
    final row = _rows[i];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // delete
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.w),
            icon: Icon(
              Icons.remove_circle_outline,
              size: 18.sp,
              color: AppColors.error,
            ),
            onPressed: _rows.length == 1
                ? null
                : () => setState(() {
                    _rows[i].dispose();
                    _rows.removeAt(i);
                  }),
          ),
          SizedBox(width: 8.w),
          // Item Name with autocomplete overlay
          Expanded(
            flex: 4,
            child: CompositedTransformTarget(
              link: row.layerLink,
              child: _overlayTextField(
                controller: row.nameCtr,
                hint: 'Item name  [Space to search]',
                rowIndex: i,
                onChanged: (v) {
                  if (_activeOverlayRow == i) {
                    _showOverlay(i, v);
                  }
                },
                onKeySpace: () => _showOverlay(i, row.nameCtr.text),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // HSN
          Expanded(
            flex: 2,
            child: _compactField(
              row.hsnCtr,
              'HSN',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          // Qty
          Expanded(
            flex: 2,
            child: _compactField(
              row.qtyCtr,
              'Qty',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          // Unit
          Expanded(
            flex: 2,
            child: _compactField(
              row.unitCtr,
              'Unit',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          // Rate
          Expanded(
            flex: 2,
            child: _compactField(
              row.rateCtr,
              '0.00',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          // Discount
          Expanded(
            flex: 2,
            child: _compactField(
              row.discCtr,
              '0',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              '₹${_rowAmount(row).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notes Card ─────────────────────────────────────────────────────────────

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.notes_outlined, 'Notes / Remarks'),
            SizedBox(height: 12.h),
            _labelField(
              'Notes',
              _notesCtrl,
              maxLines: 3,
              hint: 'Additional remarks, delivery terms…',
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary Card ───────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.calculate_outlined, 'Summary'),
            SizedBox(height: 12.h),
            const Divider(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12.h,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.sp,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'No tax applied — quotation price only',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        '₹${_subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => context.go('/quotations'),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
          ),
          SizedBox(width: 12.w),
          OutlinedButton.icon(
            onPressed: () => _showPreview(),
            icon: const Icon(Icons.preview_outlined, size: 16),
            label: const Text('Preview'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save Quotation'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showPreview() {
    final items = _rows
        .where((r) => r.nameCtr.text.isNotEmpty)
        .map(
          (r) => QuotationItem(
            name: r.nameCtr.text,
            hsn: r.hsnCtr.text,
            qty: double.tryParse(r.qtyCtr.text) ?? 1,
            unit: r.unitCtr.text,
            rate: double.tryParse(r.rateCtr.text) ?? 0,
            discount: double.tryParse(r.discCtr.text) ?? 0,
            amount: _rowAmount(r),
          ),
        )
        .toList();

    final q = Quotation(
      id: '',
      quotationNumber: _quotNoCtrl.text,
      date: _date,
      validUntil: _validUntil,
      customerName: _customerCtrl.text,
      mobileNumber: _mobileCtrl.text,
      billingAddress: _addressCtrl.text,
      shippingAddress: _shippingCtrl.text,
      subtotal: _subtotal,
      notes: _notesCtrl.text,
      status: _status,
      items: items,
    );

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(24.w),
        child: QuotationPreviewWidget(quotation: q),
      ),
    );
  }

  // ── Generic helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 18.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _labelField(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    String? hint,
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
        SizedBox(height: 6.h),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
          ),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _datePicker(
    String label,
    DateTime date,
    ValueChanged<DateTime> onPick,
  ) {
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
        SizedBox(height: 6.h),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Compact cell text-field (no label)
  Widget _compactField(
    TextEditingController ctrl,
    String hint, {
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp),
        isDense: true,
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 6.h),
      ),
      onChanged: onChanged,
    );
  }

  /// Name field with spacebar overlay trigger
  Widget _overlayTextField({
    required TextEditingController controller,
    required String hint,
    required int rowIndex,
    required ValueChanged<String> onChanged,
    required VoidCallback onKeySpace,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11.sp, color: AppColors.textTertiary),
        isDense: true,
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 6.h),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                icon: Icon(Icons.close, size: 14.sp),
                onPressed: () {
                  setState(() => controller.clear());
                  _removeOverlay();
                },
              ),
      ),
      onChanged: (v) {
        onChanged(v);
        if (v.isNotEmpty) {
          _showOverlay(rowIndex, v);
        } else {
          _removeOverlay();
        }
        setState(() {});
      },
      onTap: () {
        // show all items on tap if field is empty
        if (controller.text.isEmpty) {
          _showOverlay(rowIndex, '');
        }
      },
    );
  }
}
