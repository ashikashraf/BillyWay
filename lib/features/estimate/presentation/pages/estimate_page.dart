import 'package:flutter/material.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
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
  DateTime? _selectedMonth;
  final List<DateTime> _availableMonths = [];
  String _statusFilter = 'All'; // 'All', 'pending', 'cleared'

  List<Estimate> get _filteredEstimates {
    return _estimates.where((e) {
      bool dateMatch = true;
      if (_selectedMonth != null) {
        dateMatch = e.date.year == _selectedMonth!.year &&
                    e.date.month == _selectedMonth!.month;
      }
      
      bool statusMatch = true;
      if (_statusFilter != 'All') {
        statusMatch = e.status.toLowerCase() == _statusFilter.toLowerCase();
      }
      
      return dateMatch && statusMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      _availableMonths.add(DateTime(now.year, now.month - i, 1));
    }
    _selectedMonth = _availableMonths.first;
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

  void _showMarkAsClearedDialog(Estimate estimate) {
    final settledCtrl = TextEditingController(text: estimate.total.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Cleared'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimate No: ${estimate.estimateNumber}'),
            SizedBox(height: 8.h),
            Text('Customer: ${estimate.customerName}'),
            SizedBox(height: 8.h),
            Text('Total Amount: ₹ ${estimate.total.toStringAsFixed(2)}'),
            SizedBox(height: 16.h),
            const Text('Settled Amount:'),
            SizedBox(height: 8.h),
            TextField(
              controller: settledCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final settled = double.tryParse(settledCtrl.text) ?? estimate.total;
              final balance = estimate.total - settled;
              Navigator.pop(ctx);
              
              setState(() => _isLoading = true);
              try {
                await getIt<EstimateController>().updateEstimateStatus(
                  estimate.id!,
                  'cleared',
                  settled,
                  balance,
                );
                _loadEstimates();
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating status: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Mark Cleared'),
          ),
        ],
      ),
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
            if (_selectedMonth != null || _statusFilter != 'All')
              IconButton(
                tooltip: 'Clear Filters',
                icon: Icon(Icons.clear, color: AppColors.error),
                onPressed: () {
                  setState(() {
                    _selectedMonth = null;
                    _statusFilter = 'All';
                  });
                },
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'cleared', child: Text('Cleared')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _statusFilter = val);
                    }
                  },
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DateTime?>(
                  value: _selectedMonth,
                  hint: const Text('Filter by Month'),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Months')),
                    ..._availableMonths.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(DateFormat('MMMM yyyy').format(m)),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedMonth = val);
                  },
                ),
              ),
            ),
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
    final filtered = _filteredEstimates;
    final total = filtered.length;
    final totalValue = filtered.fold<double>(0, (sum, e) => sum + e.total);

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
      return const Center(child: AppLoadingAnimation());
    }

    final filtered = _filteredEstimates;

    if (filtered.isEmpty) {
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
        showCheckboxColumn: false,
        minWidth: 950,
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
          DataColumn2(label: Text('Total'), numeric: true),
          DataColumn2(label: Text('Settled'), numeric: true),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Actions'), size: ColumnSize.S),
        ],
        rows: filtered.map((e) {
          final isPending = e.status == 'pending';
          return DataRow(
            onSelectChanged: (_) {
              context.push('/new-estimate', extra: e).then((_) => _loadEstimates());
            },
            cells: [
              DataCell(Text(e.estimateNumber,
                  style: TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(e.date))),
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
              DataCell(Text(
                  '₹ ${e.settledAmount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
              DataCell(
                InkWell(
                  onTap: isPending ? () => _showMarkAsClearedDialog(e) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      e.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: isPending ? Colors.orange[800] : Colors.green[800],
                      ),
                    ),
                  ),
                ),
              ),
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
                      tooltip: 'Actions',
                      icon: Icon(Icons.more_vert, size: 18.sp),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'print_a4', child: Text('Print A4')),
                        const PopupMenuItem(value: 'print_a5', child: Text('Print A5')),
                        const PopupMenuItem(value: 'print_a6', child: Text('Print A6')),
                        const PopupMenuItem(value: 'print_pos', child: Text('Print POS')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (action) {
                        if (action == 'edit') {
                          context.push('/new-estimate', extra: e).then((_) => _loadEstimates());
                        } else if (action == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Estimate'),
                              content: Text(
                                  'Are you sure you want to delete ${e.estimateNumber}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await getIt<EstimateController>()
                                          .deleteEstimate(e.id!);
                                      _loadEstimates();
                                    } catch (err) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error deleting estimate: $err'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        } else if (action.startsWith('print_')) {
                          final format = action.split('_')[1].toUpperCase();
                          context.push(
                            '/estimate-preview',
                            extra: {
                              'estimate': e,
                              'formatType': format,
                            },
                          );
                        }
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
