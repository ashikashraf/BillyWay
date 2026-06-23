import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/quotation/domain/controllers/quotation_controller.dart';
import 'package:billy_way/features/quotation/data/models/quotation.dart';

class QuotationPage extends StatefulWidget {
  const QuotationPage({super.key});

  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage> {
  List<Quotation> _quotations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    final list = await getIt<QuotationController>().getQuotations();
    if (mounted) setState(() { _quotations = list; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: 24.h),
            _buildStatsRow(),
            SizedBox(height: 24.h),
            Expanded(child: _buildQuotationTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quotations',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Create and manage price quotations (tax-free)',
              style:
                  TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: _loadQuotations,
            ),
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              onPressed: () => context.go('/new-quotation'),
              icon: const Icon(Icons.add),
              label: const Text('New Quotation'),
              style: ElevatedButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final total = _quotations.length;
    final pending = _quotations.where((q) => q.status == 'Draft' || q.status == 'Sent').length;
    final approved = _quotations.where((q) => q.status == 'Approved').length;
    final totalValue = _quotations.fold<double>(0, (sum, q) => sum + q.subtotal);

    return Row(
      children: [
        _buildStatCard('Total Quotations', '$total',
            Icons.request_quote_outlined, AppColors.secondary),
        SizedBox(width: 16.w),
        _buildStatCard(
            'Quoted Value',
            '₹ ${NumberFormat('#,##,###').format(totalValue.toInt())}',
            Icons.currency_rupee,
            AppColors.primary),
        SizedBox(width: 16.w),
        _buildStatCard('Pending', '$pending',
            Icons.pending_actions_outlined, AppColors.warning),
        SizedBox(width: 16.w),
        _buildStatCard('Approved', '$approved',
            Icons.check_circle_outline, AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(value,
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_quotations.isEmpty) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.request_quote_outlined,
                  size: 64.sp, color: AppColors.textTertiary),
              SizedBox(height: 16.h),
              Text('No quotations yet',
                  style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              SizedBox(height: 8.h),
              Text('Click "New Quotation" to create one.',
                  style: TextStyle(
                      fontSize: 14.sp, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 850,
        headingRowHeight: 56.h,
        dataRowHeight: 64.h,
        headingRowColor: WidgetStateProperty.all(
            AppColors.divider.withValues(alpha: 0.5)),
        columns: const [
          DataColumn2(label: Text('Quot. No'), size: ColumnSize.S),
          DataColumn2(label: Text('Date'), size: ColumnSize.S),
          DataColumn2(label: Text('Valid Until'), size: ColumnSize.S),
          DataColumn2(label: Text('Customer'), size: ColumnSize.L),
          DataColumn2(label: Text('Amount'), numeric: true),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Actions'), size: ColumnSize.S),
        ],
        rows: _quotations.map((q) {
          return DataRow(
            cells: [
              DataCell(Text(q.quotationNumber,
                  style: TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(
                  DateFormat('dd MMM yyyy').format(q.date))),
              DataCell(Text(
                  DateFormat('dd MMM yyyy').format(q.validUntil))),
              DataCell(Text(q.customerName)),
              DataCell(Text(
                  '₹ ${q.subtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right)),
              DataCell(_buildStatusChip(q.status)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Preview',
                      icon: Icon(Icons.remove_red_eye_outlined,
                          size: 18.sp),
                      onPressed: () {},
                    ),
                    IconButton(
                      tooltip: 'Convert to Invoice',
                      icon: Icon(Icons.receipt_long_outlined,
                          size: 18.sp, color: AppColors.primary),
                      onPressed: () {},
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: Icon(Icons.delete_outline,
                          size: 18.sp, color: AppColors.error),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = AppColors.success;
        break;
      case 'Sent':
        color = AppColors.primary;
        break;
      case 'Rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600)),
    );
  }
}
