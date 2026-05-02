import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class LedgerEntryPage extends StatefulWidget {
  const LedgerEntryPage({super.key});

  @override
  State<LedgerEntryPage> createState() => _LedgerEntryPageState();
}

class _LedgerEntryPageState extends State<LedgerEntryPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isDebit = true;
  final String _selectedGroup = 'Sundry Debtors';
  bool _tdsApplicable = false;

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 1100;
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
                      _buildBasicInfoCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildGstComplianceCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildAddressContactCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildFinancialsCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildBankInfoCard(isMobile),
                      SizedBox(height: 16.h),
                      _buildLedgerSummaryCard(),
                      SizedBox(height: 16.h),
                      _buildQuickActionsCard(),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildBasicInfoCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildGstComplianceCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildAddressContactCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildFinancialsCard(isMobile),
                                SizedBox(height: 24.h),
                                _buildBankInfoCard(isMobile),
                              ],
                            ),
                          ),
                          SizedBox(width: 24.w),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _buildLedgerSummaryCard(),
                                SizedBox(height: 24.h),
                                _buildQuickActionsCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildStickyFooter(isMobile),
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
        Text(
          isMobile ? 'New Ledger' : 'Create New Ledger Master',
          style: TextStyle(
            fontSize: isMobile ? 20.sp : 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (!isMobile) _buildStatusChip('ACTIVE'),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          SizedBox(width: 8.w),
          Text(status, style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.account_tree_outlined, 'Basic Information'),
            SizedBox(height: 24.h),
            _buildTextField('Ledger Name', hint: 'e.g. Acme Corporation Pvt Ltd'),
            SizedBox(height: 16.h),
            if (isMobile) ...[
              _buildDropdownField('Ledger Group', ['Sundry Debtors', 'Sundry Creditors', 'Bank Accounts', 'Cash-in-Hand', 'Indirect Expenses']),
              SizedBox(height: 16.h),
              _buildTextField('Ledger Code', hint: 'LDR-0042'),
              SizedBox(height: 16.h),
              _buildTextField('Alias', hint: 'Optional nickname'),
            ] else
              Row(
                children: [
                  Expanded(child: _buildDropdownField('Ledger Group', ['Sundry Debtors', 'Sundry Creditors', 'Bank Accounts', 'Cash-in-Hand', 'Indirect Expenses'])),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Ledger Code', hint: 'LDR-0042')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Alias', hint: 'Optional nickname')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGstComplianceCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.verified_user_outlined, 'GST & Compliance'),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              _buildDropdownField('GST Registration Type', ['Regular', 'Composition', 'Unregistered', 'Consumer']),
              SizedBox(height: 16.h),
              _buildTextField('GSTIN Number', hint: '27AAAAA0000A1Z5'),
              SizedBox(height: 16.h),
              _buildTextField('Place of Supply', hint: 'Maharashtra (27)'),
              SizedBox(height: 16.h),
              _buildTextField('PAN Number', hint: 'ABCDE1234F'),
              SizedBox(height: 16.h),
              _buildTdsApplicabilitySelection(),
              SizedBox(height: 16.h),
              _buildDropdownField('MSME Type', ['None', 'Micro', 'Small', 'Medium']),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildDropdownField('GST Registration Type', ['Regular', 'Composition', 'Unregistered', 'Consumer'])),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('GSTIN Number', hint: '27AAAAA0000A1Z5')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Place of Supply', hint: 'Maharashtra (27)')),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: _buildTextField('PAN Number', hint: 'ABCDE1234F')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTdsApplicabilitySelection()),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildDropdownField('MSME Type', ['None', 'Micro', 'Small', 'Medium'])),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTdsApplicabilitySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TDS/TCS Applicability', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Yes'),
              selected: _tdsApplicable,
              onSelected: (v) => setState(() => _tdsApplicable = true),
            ),
            SizedBox(width: 8.w),
            ChoiceChip(
              label: const Text('No'),
              selected: !_tdsApplicable,
              onSelected: (v) => setState(() => _tdsApplicable = false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressContactCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.contact_mail_outlined, 'Address & Contact'),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              _buildTextField('Contact Person', hint: 'e.g. John Doe'),
              SizedBox(height: 16.h),
              _buildTextField('Mobile Number', prefixText: '+91 '),
              SizedBox(height: 16.h),
              _buildTextField('Email ID', hint: 'john@example.com'),
              SizedBox(height: 16.h),
              _buildTextField('Billing Address', maxLines: 2),
              SizedBox(height: 16.h),
              _buildTextField('Shipping Address', maxLines: 2, hint: 'Leave blank if same'),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildTextField('Contact Person', hint: 'e.g. John Doe')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Mobile Number', prefixText: '+91 ')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Email ID', hint: 'john@example.com')),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: _buildTextField('Billing Address', maxLines: 2)),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Shipping Address', maxLines: 2, hint: 'Leave blank if same')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialsCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.account_balance_wallet_outlined, 'Opening & Financials'),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              Row(
                children: [
                  Expanded(child: _buildTextField('Opening Balance', initialValue: '0.00', prefixText: '₹ ')),
                  SizedBox(width: 8.w),
                  _buildDrCrToggle(),
                ],
              ),
              SizedBox(height: 16.h),
              _buildTextField('Credit Limit', initialValue: '0.00', prefixText: '₹ '),
              SizedBox(height: 16.h),
              _buildTextField('Payment Terms (Days)', initialValue: '30'),
            ] else
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(child: _buildTextField('Opening Balance', initialValue: '0.00', prefixText: '₹ ')),
                        SizedBox(width: 8.w),
                        _buildDrCrToggle(),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Credit Limit', initialValue: '0.00', prefixText: '₹ ')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Payment Terms (Days)', initialValue: '30')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrCrToggle() {
    return Column(
      children: [
        const SizedBox(height: 20), // Alignment
        ToggleButtons(
          constraints: BoxConstraints(minHeight: 40.h, minWidth: 40.w),
          borderRadius: BorderRadius.circular(8),
          isSelected: [_isDebit, !_isDebit],
          onPressed: (index) => setState(() => _isDebit = index == 0),
          children: const [Text('Dr'), Text('Cr')],
        ),
      ],
    );
  }

  Widget _buildBankInfoCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.account_balance_outlined, 'Bank Information (Optional)'),
            SizedBox(height: 24.h),
            if (isMobile) ...[
              _buildTextField('Bank Name'),
              SizedBox(height: 16.h),
              _buildTextField('Account Number'),
              SizedBox(height: 16.h),
              _buildTextField('IFSC Code'),
              SizedBox(height: 16.h),
              _buildTextField('Branch Name'),
              SizedBox(height: 16.h),
              _buildTextField('UPI ID', hint: 'user@bank'),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildTextField('Bank Name')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('Account Number')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('IFSC Code')),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: _buildTextField('Branch Name')),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildTextField('UPI ID', hint: 'user@bank')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerSummaryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LEDGER PREVIEW', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
            SizedBox(height: 16.h),
            _buildSummaryRow(Icons.business, 'Ledger Name', 'Pending Input...'),
            _buildSummaryRow(Icons.category, 'Group', _selectedGroup),
            _buildSummaryRow(Icons.payments, 'Opening Bal', '₹ 0.00 ${_isDebit ? "Dr" : "Cr"}'),
            _buildSummaryRow(Icons.fingerprint, 'GSTIN', 'Not Provided'),
            const Divider(height: 32),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text('Compliance: Pending', style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppColors.textSecondary),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
              Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Settings', style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            _buildWhiteSwitch('Default for Sales'),
            _buildWhiteSwitch('Default for Purchase'),
            _buildWhiteSwitch('Allow Credit Limit'),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteSwitch(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w500)),
          Switch.adaptive(
            value: false,
            onChanged: (v) {},
            activeTrackColor: Colors.white24,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {},
            child: const Text('Reset Form'),
          ),
          SizedBox(width: 16.w),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save Ledger Master'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
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
        Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildTextField(String label, {String? hint, String? initialValue, TextEditingController? controller, IconData? prefixIcon, IconData? suffixIcon, String? prefixText, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20.sp) : null,
            prefixText: prefixText,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18.sp) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {},
        ),
      ],
    );
  }
}
