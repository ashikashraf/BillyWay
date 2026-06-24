import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/estimate/domain/controllers/estimate_controller.dart';
import 'package:billy_way/features/estimate/data/models/estimate.dart';
import 'package:billy_way/features/estimate/presentation/widgets/estimate_preview_widget.dart';

class EstimatePage extends StatefulWidget {
  const EstimatePage({super.key});

  @override
  State<EstimatePage> createState() => _EstimatePageState();
}

class _EstimatePageState extends State<EstimatePage> {
  List<Estimate> _estimates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEstimates();
  }

  Future<void> _loadEstimates() async {
    setState(() => _isLoading = true);
    try {
      final list = await getIt<EstimateController>().getEstimates();
      if (mounted) setState(() { _estimates = list; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading estimates: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showPreview(Estimate estimate) {
    showDialog(
      context: context,
      builder: (_) => EstimatePreviewWidget(estimate: estimate),
    );
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
            Expanded(child: _buildEstimateTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16.h,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimate Bills',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Create and manage simple estimate bills',
              style:
                  TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: _loadEstimates,
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push('/new-estimate');
                _loadEstimates();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Estimate Bill'),
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
    final total = _estimates.length;
    final totalValue = _estimates.fold<double>(0, (sum, e) => sum + e.subtotal);

    bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildStatCard('Total Estimates', '$total',
                  Icons.request_quote_outlined, AppColors.secondary),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildStatCard(
                  'Total Value',
                  '₹ ${NumberFormat('#,##,###').format(totalValue.toInt())}',
                  Icons.currency_rupee,
                  AppColors.primary),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildStatCard('Total Estimates', '$total',
            Icons.request_quote_outlined, AppColors.secondary),
        SizedBox(width: 16.w),
        _buildStatCard(
            'Total Value',
            '₹ ${NumberFormat('#,##,###').format(totalValue.toInt())}',
            Icons.currency_rupee,
            AppColors.primary),
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

  Widget _buildEstimateTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_estimates.isEmpty) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.request_quote_outlined,
                  size: 64.sp, color: AppColors.textTertiary),
              SizedBox(height: 16.h),
              Text('No estimates yet',
                  style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              SizedBox(height: 8.h),
              Text('Click "New Estimate Bill" to create one.',
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
          DataColumn2(label: Text('Estimate No.'), size: ColumnSize.S),
          DataColumn2(label: Text('Date'), size: ColumnSize.S),
          DataColumn2(label: Text('Customer'), size: ColumnSize.L),
          DataColumn2(label: Text('Subtotal'), numeric: true),
          DataColumn2(label: Text('Old Balance'), numeric: true),
          DataColumn2(label: Text('Total Amount'), numeric: true),
          DataColumn2(label: Text('Actions'), size: ColumnSize.S),
        ],
        rows: _estimates.map((e) {
          return DataRow(
            cells: [
              DataCell(Text(e.estimateNumber,
                  style: TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(
                  DateFormat('dd MMM yyyy').format(e.date))),
              DataCell(Text(e.customerName)),
              DataCell(Text(
                  '₹ ${e.subtotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right)),
              DataCell(Text(
                  '₹ ${e.oldBalance.toStringAsFixed(2)}',
                  textAlign: TextAlign.right)),
              DataCell(Text(
                  '₹ ${e.total.toStringAsFixed(2)}',
                  textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
              DataCell(
                Wrap(
                  spacing: 4.w,
                  children: [
                    IconButton(
                      tooltip: 'Preview',
                      icon: Icon(Icons.remove_red_eye_outlined,
                          size: 18.sp),
                      onPressed: () => _showPreview(e),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Print',
                      icon: Icon(Icons.print_outlined, size: 18.sp),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'A4', child: Text('Print A4')),
                        const PopupMenuItem(value: 'A5', child: Text('Print A5')),
                        const PopupMenuItem(value: 'A6', child: Text('Print A6')),
                        const PopupMenuItem(value: 'POS', child: Text('Print POS (Thermal)')),
                      ],
                      onSelected: (format) {
                        context.push(
                          '/estimate-preview',
                          extra: {
                            'estimate': e,
                            'formatType': format,
                          },
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: Icon(Icons.delete_outline,
                          size: 18.sp, color: AppColors.error),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Estimate'),
                            content: Text('Are you sure you want to delete ${e.estimateNumber}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  if (e.id != null) {
                                    await getIt<EstimateController>().deleteEstimate(e.id!);
                                    _loadEstimates();
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
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
}
