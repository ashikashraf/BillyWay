import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/core/theme/app_colors.dart';
import 'package:billy_way/features/quotation/data/models/quotation.dart';

class QuotationPreviewWidget extends StatelessWidget {
  final Quotation quotation;

  const QuotationPreviewWidget({super.key, required this.quotation});

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
                    _buildQuotationHeader(),
                    SizedBox(height: 40.h),
                    _buildPartiesSection(),
                    SizedBox(height: 40.h),
                    _buildItemsTable(),
                    SizedBox(height: 32.h),
                    _buildSummarySection(),
                    if (quotation.notes != null &&
                        quotation.notes!.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      _buildNotesSection(),
                    ],
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
        color: AppColors.secondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quotation Preview',
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
                onPressed: () {},
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

  Widget _buildQuotationHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUOTATION',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8.h),
            _buildInfoLabel('Quot. #', quotation.quotationNumber),
            _buildInfoLabel(
              'Date',
              DateFormat('dd MMM yyyy').format(quotation.date),
            ),
            _buildInfoLabel(
              'Valid Until',
              DateFormat('dd MMM yyyy').format(quotation.validUntil),
            ),
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
              '123 Business Park, Sector 62\nNoida, Uttar Pradesh 201301',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
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
              Text('QUOTE TO', style: _sectionHeaderStyle()),
              SizedBox(height: 12.h),
              Text(
                quotation.customerName,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              if (quotation.mobileNumber != null &&
                  quotation.mobileNumber!.isNotEmpty)
                Text(
                  'Mob: ${quotation.mobileNumber}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (quotation.billingAddress != null &&
                  quotation.billingAddress!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    quotation.billingAddress!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 40.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DELIVER TO', style: _sectionHeaderStyle()),
              SizedBox(height: 12.h),
              Text(
                quotation.shippingAddress?.isNotEmpty == true
                    ? quotation.shippingAddress!
                    : 'Same as Billing Address',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
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
            color: AppColors.secondary.withValues(alpha: 0.07),
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Row(
            children: [
              Expanded(flex: 1, child: Text('#', style: _tableHeaderStyle())),
              Expanded(
                flex: 5,
                child: Text('Description', style: _tableHeaderStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text('HSN/SAC', style: _tableHeaderStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text('Qty/Unit', style: _tableHeaderStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text('Rate', style: _tableHeaderStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: _tableHeaderStyle(),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(quotation.items.length, (index) {
          final item = quotation.items[index];
          return Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    item.name.isEmpty ? 'Untitled Item' : item.name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(item.hsn, style: TextStyle(fontSize: 13.sp)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${item.qty} ${item.unit}',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${item.rate.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${item.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
              _buildSummaryLine('Subtotal', quotation.subtotal),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '₹${quotation.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'No Tax Applied — Quotation Only',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes / Remarks',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            quotation.notes!,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
          ),
        ],
      ),
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
                Text(
                  'Terms & Conditions:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '1. This is a quotation only, not a tax invoice.\n2. Prices are valid until the date mentioned above.\n3. Subject to Noida Jurisdiction.',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
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
                  child: Center(
                    child: Text(
                      'Sign',
                      style: TextStyle(
                        color: AppColors.divider,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Authorised Signatory',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
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
          Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionHeaderStyle() => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w900,
    color: AppColors.secondary,
    letterSpacing: 1,
  );

  TextStyle _tableHeaderStyle() => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary,
  );
}
