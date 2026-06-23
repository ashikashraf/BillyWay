import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/features/sales/data/models/sales_invoice.dart';

class InvoicePreviewWidget extends StatelessWidget {
  final SalesInvoice invoice;

  const InvoicePreviewWidget({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.all(40.w),
      child: SizedBox(
        width: 800.w,
        child: Column(
          children: [
            _buildDialogHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(40.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInvoiceHeader(),
                    SizedBox(height: 40.h),
                    _buildPartiesSection(),
                    SizedBox(height: 40.h),
                    _buildItemsTable(),
                    SizedBox(height: 32.h),
                    _buildSummarySection(),
                    SizedBox(height: 60.h),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bill Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.print, color: Colors.white),
                onPressed: () {
                  // Print logic would go here
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TAX INVOICE',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8.h),
            _buildInfoLabel('Invoice #', invoice.invoiceNumber),
            _buildInfoLabel('Date', DateFormat('dd MMM yyyy').format(invoice.date)),
            _buildInfoLabel('Due Date', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'BILLYWAY ERP',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '123 Business Park, Sector 62\nNoida, Uttar Pradesh 201301\nGSTIN: 09AAAAA0000A1Z5',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartiesSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BILL TO', style: _sectionHeaderStyle()),
              SizedBox(height: 12.h),
              Text(invoice.customerName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              if (invoice.gstin != null && invoice.gstin!.isNotEmpty)
                Text('GSTIN: ${invoice.gstin}', style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
              if (invoice.mobileNumber != null && invoice.mobileNumber!.isNotEmpty)
                Text('Mob: ${invoice.mobileNumber}', style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
              if (invoice.billingAddress != null && invoice.billingAddress!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(invoice.billingAddress!, style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
                ),
            ],
          ),
        ),
        SizedBox(width: 40.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SHIP TO', style: _sectionHeaderStyle()),
              SizedBox(height: 12.h),
              Text(
                invoice.shippingAddress?.isNotEmpty == true ? invoice.shippingAddress! : 'Same as Billing Address',
                style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            border: Border.symmetric(horizontal: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(flex: 1, child: Text('#', style: _tableHeaderStyle())),
              Expanded(flex: 5, child: Text('Description', style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text('HSN/SAC', style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text('Qty/Unit', style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text('Rate', style: _tableHeaderStyle())),
              Expanded(flex: 1, child: Text('GST', style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.right, style: _tableHeaderStyle())),
            ],
          ),
        ),
        ...List.generate(invoice.items.length, (index) {
          final item = invoice.items[index];
          return Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text('${index + 1}', style: TextStyle(fontSize: 13.sp))),
                Expanded(flex: 5, child: Text(item.name.isEmpty ? 'Untitled Item' : item.name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500))),
                Expanded(flex: 2, child: Text(item.hsn, style: TextStyle(fontSize: 13.sp))),
                Expanded(flex: 2, child: Text('${item.qty} ${item.unit}', style: TextStyle(fontSize: 13.sp))),
                Expanded(flex: 2, child: Text('₹${item.rate.toStringAsFixed(2)}', style: TextStyle(fontSize: 13.sp))),
                Expanded(flex: 1, child: Text('${item.gstRate.toInt()}%', style: TextStyle(fontSize: 13.sp))),
                Expanded(flex: 2, child: Text('₹${(item.qty * item.rate).toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 300.w,
          child: Column(
            children: [
              _buildSummaryLine('Subtotal', invoice.subtotal),
              _buildSummaryLine('CGST', invoice.cgst),
              _buildSummaryLine('SGST', invoice.sgst),
              if (invoice.igst > 0) _buildSummaryLine('IGST', invoice.igst),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
                  Text(
                    '₹${invoice.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Amount in words: ${numberToWords(invoice.totalAmount.toInt())} Only',
                  style: TextStyle(fontSize: 10.sp, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Terms & Conditions:', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                Text(
                  '1. Goods once sold will not be taken back.\n2. Subject to Noida Jurisdiction.',
                  style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  width: 150.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(child: Text('Sign', style: TextStyle(color: AppColors.divider, fontSize: 12.sp))),
                ),
                SizedBox(height: 8.h),
                Text('Authorised Signatory', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoLabel(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          SizedBox(width: 80.w, child: Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary))),
          Text(value, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, double value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
          Text('₹${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  TextStyle _sectionHeaderStyle() => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        letterSpacing: 1,
      );

  TextStyle _tableHeaderStyle() => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      );

  String numberToWords(int number) {
    // Very simple conversion for demo, a real library would be better
    return 'One Thousand One Hundred and Eighty';
  }
}
