import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:intl/intl.dart';
import '../../../../main.dart';
import '../../data/models/purchase_invoice.dart';
import '../../domain/controllers/purchase_controller.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  bool _isLoading = true;
  List<PurchaseInvoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final purchaseController = getIt<PurchaseController>();
    final invoices = await purchaseController.getPurchaseInvoices();
    if (mounted) {
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    }
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
            Expanded(child: _buildPurchaseTable(context)),
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
              'Purchase Register',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Manage your purchase bills and vendor payments',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => context.go('/new-purchase'),
          icon: const Icon(Icons.add),
          label: const Text('Add Purchase Bill'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          'Total Purchase',
          '₹ 8,12,000',
          Icons.shopping_bag_outlined,
          AppColors.primary,
        ),
        SizedBox(width: 16.w),
        _buildStatCard(
          'Input Tax Credit',
          '₹ 1,46,160',
          Icons.account_balance_outlined,
          AppColors.secondary,
        ),
        SizedBox(width: 16.w),
        _buildStatCard(
          'To Pay',
          '₹ 45,000',
          Icons.payments_outlined,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseTable(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: DataTable2(
        showCheckboxColumn: false,
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 800,
        headingRowHeight: 56.h,
        dataRowHeight: 64.h,
        headingRowColor: WidgetStateProperty.all(
          AppColors.divider.withValues(alpha: 0.5),
        ),
        columns: const [
          DataColumn2(label: Text('Bill No'), size: ColumnSize.S),
          DataColumn2(label: Text('Date'), size: ColumnSize.S),
          DataColumn2(label: Text('Vendor'), size: ColumnSize.L),
          DataColumn2(label: Text('Taxable Amt'), numeric: true),
          DataColumn2(label: Text('GST'), numeric: true),
          DataColumn2(label: Text('Total'), numeric: true),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Actions'), size: ColumnSize.S),
        ],
        rows: _isLoading
            ? []
            : _invoices.isEmpty
            ? [
                const DataRow(
                  cells: [
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('No bills found')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                  ],
                ),
              ]
            : _invoices.map((invoice) {
                return DataRow(
                  onSelectChanged: (_) {
                    context.push(
                      '/purchase-invoice-pdf-preview',
                      extra: {'invoice': invoice, 'formatType': 'A4'},
                    );
                  },
                  cells: [
                    DataCell(
                      Text(invoice.vendorBillNo ?? invoice.internalRefNo),
                    ),
                    DataCell(
                      Text(DateFormat('dd MMM yyyy').format(invoice.date)),
                    ),
                    DataCell(Text(invoice.vendorName)),
                    DataCell(Text('₹ ${invoice.subtotal.toStringAsFixed(2)}')),
                    DataCell(Text('₹ ${invoice.totalTax.toStringAsFixed(2)}')),
                    DataCell(
                      Text('₹ ${invoice.totalAmount.toStringAsFixed(2)}'),
                    ),
                    DataCell(_buildStatusChip(invoice.status)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.print, size: 18),
                            onPressed: () {
                              context.push(
                                '/purchase-invoice-pdf-preview',
                                extra: {'invoice': invoice, 'formatType': 'A4'},
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 18),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: AppColors.success,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
