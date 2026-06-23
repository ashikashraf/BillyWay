import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:billy_way/features/estimate/data/models/estimate.dart';

class EstimatePreviewWidget extends StatelessWidget {
  final Estimate estimate;

  const EstimatePreviewWidget({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: EdgeInsets.all(40.w),
      child: SizedBox(
        width: 600.w,
        child: Column(
          children: [
            _buildDialogHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(40.w),
                child: _buildBillDesign(),
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
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Estimate Preview',
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

  Widget _buildBillDesign() {
    // Light blue color theme based on the uploaded image
    const Color billBlue = Color(0xFFE3F2FD);
    const Color borderBlue = Color(0xFF64B5F6);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderBlue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderBlue, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60), // Spacer to center ESTIMATE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ESTIMATE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const Text('Brought of', style: TextStyle(color: borderBlue, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('M/s ', style: TextStyle(color: borderBlue, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: borderBlue, width: 1)),
                        ),
                        child: Text(estimate.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('No. ', style: TextStyle(color: borderBlue)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: borderBlue, width: 1)),
                        ),
                        child: Text(estimate.estimateNumber),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Date ', style: TextStyle(color: borderBlue)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: borderBlue, width: 1)),
                        ),
                        child: Text(DateFormat('dd-MMM-yyyy').format(estimate.date)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          
          // Table Header
          Container(
            color: billBlue,
            child: Row(
              children: [
                _buildCell('Qty', flex: 1, isHeader: true, rightBorder: true),
                _buildCell('Particulars', flex: 4, isHeader: true, rightBorder: true),
                _buildCell('Rate', flex: 2, isHeader: true, rightBorder: true),
                _buildCell('Amount', flex: 2, isHeader: true, rightBorder: false),
              ],
            ),
          ),
          
          // Table Body
          ...List.generate(15, (index) {
            // Display empty rows to fill the bill exactly like the printed one
            if (index < estimate.items.length) {
              final item = estimate.items[index];
              return Row(
                children: [
                  _buildCell(item.qty.toStringAsFixed(0), flex: 1, rightBorder: true, bottomBorder: true),
                  _buildCell(item.particular, flex: 4, rightBorder: true, bottomBorder: true, align: Alignment.centerLeft),
                  _buildCell(item.rate.toStringAsFixed(2), flex: 2, rightBorder: true, bottomBorder: true),
                  _buildCell(item.amount.toStringAsFixed(2), flex: 2, rightBorder: false, bottomBorder: true),
                ],
              );
            } else {
              // Empty filler row
              return Row(
                children: [
                  _buildCell('', flex: 1, rightBorder: true, bottomBorder: true),
                  _buildCell('', flex: 4, rightBorder: true, bottomBorder: true),
                  _buildCell('', flex: 2, rightBorder: true, bottomBorder: true),
                  _buildCell('', flex: 2, rightBorder: false, bottomBorder: true),
                ],
              );
            }
          }),
          
          // Old Balance Row
          Row(
            children: [
              _buildCell('', flex: 1, rightBorder: true, bottomBorder: true),
              _buildCell('Old Balance (OB)', flex: 4, align: Alignment.centerRight, rightBorder: true, bottomBorder: true),
              _buildCell('', flex: 2, rightBorder: true, bottomBorder: true),
              _buildCell(estimate.oldBalance.toStringAsFixed(2), flex: 2, rightBorder: false, bottomBorder: true),
            ],
          ),

          // Footer Row
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderBlue, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        const Text('E & O.E.', style: TextStyle(color: borderBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Text('Thank you Visit Again', style: TextStyle(color: borderBlue, fontSize: 10)),
                        const Spacer(),
                        const Text('Total', style: TextStyle(color: borderBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: borderBlue,
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      estimate.total.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Signature
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('* Goods once sold will not be taken back', style: TextStyle(color: borderBlue, fontSize: 10)),
                const Text('Signature', style: TextStyle(color: borderBlue, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    String text, {
    required int flex,
    bool isHeader = false,
    bool rightBorder = false,
    bool bottomBorder = false,
    Alignment align = Alignment.center,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: isHeader ? 30 : 25,
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            right: rightBorder ? const BorderSide(color: Color(0xFF64B5F6), width: 1) : BorderSide.none,
            bottom: bottomBorder ? const BorderSide(color: Color(0xFF64B5F6), width: 1) : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isHeader ? const Color(0xFF1976D2) : Colors.black87,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
