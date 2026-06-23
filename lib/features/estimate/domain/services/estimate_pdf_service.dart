import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/estimate.dart';

class EstimatePdfService {
  static Future<Uint8List> generatePdf(Estimate estimate, String formatType) async {
    final pdf = pw.Document();

    PdfPageFormat format;
    switch (formatType) {
      case 'A5':
        format = PdfPageFormat.a5;
        break;
      case 'POS':
        format = PdfPageFormat.roll80;
        break;
      case 'A4':
      default:
        format = PdfPageFormat.a4;
    }

    if (formatType == 'POS') {
      pdf.addPage(_buildPosPage(estimate, format));
    } else {
      pdf.addPage(_buildStandardPage(estimate, format, formatType));
    }

    return pdf.save();
  }

  static pw.Page _buildStandardPage(Estimate estimate, PdfPageFormat format, String formatType) {
    return pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return [
          _buildHeader(estimate),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(estimate),
          pw.SizedBox(height: 20),
          _buildItemTable(estimate, isPos: false),
          pw.SizedBox(height: 20),
          _buildTotals(estimate, isPos: false),
        ];
      },
    );
  }

  static pw.Page _buildPosPage(Estimate estimate, PdfPageFormat format) {
    return pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(10),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text('BILLYWAY ERP', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(child: pw.Text('TAX-FREE QUOTATION/ESTIMATE')),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Text('Est No: ${estimate.estimateNumber}'),
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(estimate.date)}'),
            pw.Text('Customer: ${estimate.customerName}'),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            _buildItemTable(estimate, isPos: true),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            _buildTotals(estimate, isPos: true),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Center(child: pw.Text('Thank you!')),
          ],
        );
      },
    );
  }

  static pw.Widget _buildHeader(Estimate estimate) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('BILLYWAY ERP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Estimate Bill', style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Est No: ${estimate.estimateNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(estimate.date)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(Estimate estimate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        children: [
          pw.Text('Customer: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(estimate.customerName),
        ],
      ),
    );
  }

  static pw.Widget _buildItemTable(Estimate estimate, {required bool isPos}) {
    final headers = isPos 
      ? ['Item', 'Qty', 'Rate', 'Amt'] 
      : ['Particulars', 'Qty', 'Unit', 'Rate', 'Amount'];
      
    final data = estimate.items.map((item) {
      if (isPos) {
        return [
          item.particular,
          item.qty.toStringAsFixed(0),
          item.rate.toStringAsFixed(2),
          item.amount.toStringAsFixed(2),
        ];
      }
      return [
        item.particular,
        item.qty.toStringAsFixed(2),
        item.unit,
        item.rate.toStringAsFixed(2),
        item.amount.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: isPos ? null : pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isPos ? 10 : 12),
      cellStyle: pw.TextStyle(fontSize: isPos ? 10 : 12),
      headerDecoration: isPos ? null : const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: isPos 
        ? {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight}
        : {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
    );
  }

  static pw.Widget _buildTotals(Estimate estimate, {required bool isPos}) {
    final fontSize = isPos ? 10.0 : 12.0;
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Subtotal:', estimate.subtotal, fontSize),
          _buildTotalRow('Old Balance:', estimate.oldBalance, fontSize),
          pw.Divider(color: PdfColors.grey400),
          _buildTotalRow('Total:', estimate.total, isPos ? 12 : 16, isBold: true),
          if (estimate.settledAmount > 0) ...[
            pw.SizedBox(height: 5),
            _buildTotalRow('Settled Amt:', estimate.settledAmount, fontSize),
            _buildTotalRow('New Balance:', estimate.balance, isPos ? 10 : 14, isBold: true),
          ]
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, double fontSize, {bool isBold = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 80,
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            amount.toStringAsFixed(2),
            style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
      ],
    );
  }
}
