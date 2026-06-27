import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:billy_way/main.dart';
import 'package:billy_way/features/reports/domain/controllers/gst_reports_controller.dart';

class GstReportsPage extends StatefulWidget {
  const GstReportsPage({super.key});

  @override
  State<GstReportsPage> createState() => _GstReportsPageState();
}

class _GstReportsPageState extends State<GstReportsPage> {
  final _controller = getIt<GstReportsController>();
  bool _isLoading = true;

  Map<String, dynamic> _gstr1 = {};
  Map<String, dynamic> _gstr2b = {};
  Map<String, dynamic> _gstr3b = {};

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _gstr1 = await _controller.fetchGstr1Summary(_startDate, _endDate);
    _gstr2b = await _controller.fetchGstr2bSummary(_startDate, _endDate);
    _gstr3b = await _controller.fetchGstr3bSummary(_startDate, _endDate);

    if (mounted) setState(() => _isLoading = false);
  }

  void _changeMonth(int offset) {
    setState(() {
      _startDate = DateTime(_startDate.year, _startDate.month + offset, 1);
      _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('GST Reports Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(),
                  SizedBox(height: 24.h),
                  if (isMobile) ...[
                    _buildGstr1Card(),
                    SizedBox(height: 16.h),
                    _buildGstr2bCard(),
                    SizedBox(height: 16.h),
                    _buildGstr3bCard(),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildGstr1Card()),
                        SizedBox(width: 16.w),
                        Expanded(child: _buildGstr2bCard()),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _buildGstr3bCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
        Text(
          DateFormat('MMMM yyyy').format(_startDate),
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
      ],
    );
  }

  Widget _buildGstr1Card() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.outbound, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text('GSTR-1 (Outward Supplies)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 24.h),
            _buildDataRow('B2B Sales Taxable', _gstr1['b2b_taxable'] ?? 0),
            _buildDataRow('B2B Sales Tax', _gstr1['b2b_tax'] ?? 0, isHighlight: true),
            const Divider(),
            _buildDataRow('B2C Sales Taxable', _gstr1['b2c_taxable'] ?? 0),
            _buildDataRow('B2C Sales Tax', _gstr1['b2c_tax'] ?? 0, isHighlight: true),
            const Divider(),
            _buildDataRow('Total Output Liability', _gstr1['total_tax'] ?? 0, isBold: true, isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildGstr2bCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.move_to_inbox, color: Colors.green),
                SizedBox(width: 8.w),
                Text('GSTR-2B (Input Tax Credit)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'Eligible ITC available from automated ledger (Purchase Invoices).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
            SizedBox(height: 32.h),
            _buildDataRow('Total Eligible ITC', _gstr2b['total_itc_available'] ?? 0, isBold: true, isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildGstr3bCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: AppColors.primary, size: 28.sp),
                SizedBox(width: 12.w),
                Text('GSTR-3B Summary (Net Liability)', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
            SizedBox(height: 24.h),
            _buildDataRow('1. Total Outward Tax Liability (GSTR-1)', _gstr3b['outward_tax_liability'] ?? 0),
            _buildDataRow('2. Less: Eligible ITC (GSTR-2B)', _gstr3b['eligible_itc'] ?? 0),
            const Divider(thickness: 2),
            _buildDataRow('Net Tax Payable (Cash)', _gstr3b['net_tax_payable'] ?? 0, isBold: true, isHighlight: true, fontSize: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, double value, {bool isBold = false, bool isHighlight = false, double? fontSize}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize ?? 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            '₹ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize ?? 14.sp,
              fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? (isBold ? AppColors.primary : AppColors.textPrimary) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
