import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/sales_invoice.dart';

class SalesInvoicePdfService {
  static Future<Uint8List> generatePdf(
    SalesInvoice invoice,
    String formatType,
  ) async {
    final pdf = pw.Document();

    PdfPageFormat format;
    switch (formatType) {
      case 'A6':
        format = PdfPageFormat.a6;
        break;
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
      pdf.addPage(_buildPosPage(invoice, format));
    } else {
      pdf.addPage(_buildStandardPage(invoice, format, formatType));
    }

    return pdf.save();
  }

  static pw.Page _buildStandardPage(
    SalesInvoice invoice,
    PdfPageFormat format,
    String formatType,
  ) {
    final isA6 = formatType == 'A6';
    final isA5 = formatType == 'A5';
    final baseFontSize = isA6 ? 8.0 : (isA5 ? 10.0 : 12.0);

    return pw.MultiPage(
      pageFormat: format,
      margin: pw.EdgeInsets.all(isA6 ? 12 : 32),
      build: (context) {
        return [
          _buildHeader(invoice, isA6: isA6),
          pw.SizedBox(height: isA6 ? 8 : 16),
          _buildPartiesInfo(invoice, isA6: isA6, baseFontSize: baseFontSize),
          pw.SizedBox(height: isA6 ? 8 : 16),
          _buildItemTable(invoice, isPos: false, isA6: isA6, baseFontSize: baseFontSize),
          pw.SizedBox(height: isA6 ? 8 : 16),
          _buildTaxBreakdownAndTotals(invoice, isA6: isA6, baseFontSize: baseFontSize),
          pw.SizedBox(height: isA6 ? 8 : 20),
          _buildFooter(invoice, baseFontSize: baseFontSize),
        ];
      },
    );
  }

  static pw.Page _buildPosPage(SalesInvoice invoice, PdfPageFormat format) {
    return pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(10),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Text('Inv No: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.date)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Customer: ${invoice.customerName}', style: const pw.TextStyle(fontSize: 10)),
            if (invoice.gstin != null && invoice.gstin!.isNotEmpty)
              pw.Text('GSTIN: ${invoice.gstin}', style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            _buildItemTable(invoice, isPos: true, baseFontSize: 10),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total: ₹${invoice.totalAmount.toStringAsFixed(2)}', 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Center(child: pw.Text('Thank you!', style: const pw.TextStyle(fontSize: 10))),
          ],
        );
      },
    );
  }

  static pw.Widget _buildHeader(SalesInvoice invoice, {bool isA6 = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'TAX INVOICE',
              style: pw.TextStyle(
                fontSize: isA6 ? 16 : 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (invoice.reverseCharge)
              pw.Text(
                '(Subject to Reverse Charge)',
                style: pw.TextStyle(fontSize: isA6 ? 8 : 10),
              ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Invoice No: ${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: isA6 ? 10 : 12,
              ),
            ),
            pw.Text(
              'Date: ${DateFormat('dd MMM yyyy').format(invoice.date)}',
              style: pw.TextStyle(fontSize: isA6 ? 10 : 12),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPartiesInfo(SalesInvoice invoice, {bool isA6 = false, required double baseFontSize}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Supplier Info
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.all(isA6 ? 4 : 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Billed By (Supplier):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: baseFontSize)),
                pw.Text('Acme Corporation', style: pw.TextStyle(fontSize: baseFontSize)),
                pw.Text('GSTIN: 32XXXXX1234X1Z5', style: pw.TextStyle(fontSize: baseFontSize)),
                pw.Text('State: Kerala (32)', style: pw.TextStyle(fontSize: baseFontSize)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        // Customer Info
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.all(isA6 ? 4 : 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Billed To (Recipient):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: baseFontSize)),
                pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: baseFontSize)),
                if (invoice.gstin != null && invoice.gstin!.isNotEmpty)
                  pw.Text('GSTIN: ${invoice.gstin}', style: pw.TextStyle(fontSize: baseFontSize)),
                if (invoice.billingAddress != null && invoice.billingAddress!.isNotEmpty)
                  pw.Text('Address: ${invoice.billingAddress}', style: pw.TextStyle(fontSize: baseFontSize)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemTable(
    SalesInvoice invoice, {
    required bool isPos,
    bool isA6 = false,
    required double baseFontSize,
  }) {
    final isInter = invoice.supplyType == 'INTER_STATE';

    final headers = isPos
        ? ['Item', 'Qty', 'Rate', 'Amt']
        : (isA6
              ? ['Item', 'HSN', 'Qty', 'Rate', 'Taxable', 'GST%', 'Amt']
              : ['Description', 'HSN/SAC', 'Qty', 'Rate', 'Taxable Val', isInter ? 'IGST' : 'CGST+SGST', 'Total']);

    final data = invoice.items.map((item) {
      if (isPos) {
        return [
          item.name,
          item.qty.toStringAsFixed(0),
          item.rate.toStringAsFixed(2),
          (item.qty * item.rate).toStringAsFixed(2),
        ];
      }

      final taxStr = isInter
          ? '${item.igstAmount.toStringAsFixed(2)} (${item.gstRate}%)'
          : '${(item.cgstAmount + item.sgstAmount).toStringAsFixed(2)} (${item.gstRate}%)';

      return [
        item.name,
        item.hsn,
        item.qty.toStringAsFixed(2),
        item.rate.toStringAsFixed(2),
        item.taxableValue.toStringAsFixed(2),
        isA6 ? '${item.gstRate}%' : taxStr,
        (item.taxableValue + item.cgstAmount + item.sgstAmount + item.igstAmount + item.cessAmount).toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: isPos ? null : pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: isPos ? 10 : (isA6 ? 8 : 10),
      ),
      cellStyle: pw.TextStyle(fontSize: isPos ? 10 : (isA6 ? 8 : 10)),
      cellPadding: pw.EdgeInsets.symmetric(
        horizontal: isA6 ? 4 : 5,
        vertical: isA6 ? 2 : 5,
      ),
      headerDecoration: isPos ? null : const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: isPos
          ? { 0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight }
          : { 0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight, 5: pw.Alignment.centerRight, 6: pw.Alignment.centerRight },
    );
  }

  static pw.Widget _buildTaxBreakdownAndTotals(
    SalesInvoice invoice, {
    bool isA6 = false,
    required double baseFontSize,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Empty space or extra info on the left
        pw.Expanded(
          flex: 2,
          child: pw.Container(),
        ),
        // Totals on the right
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: pw.EdgeInsets.all(isA6 ? 4 : 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              children: [
                _buildTotalRow('Taxable Amount:', invoice.subtotal, baseFontSize),
                if (invoice.cgst > 0) _buildTotalRow('CGST:', invoice.cgst, baseFontSize),
                if (invoice.sgst > 0) _buildTotalRow('SGST:', invoice.sgst, baseFontSize),
                if (invoice.igst > 0) _buildTotalRow('IGST:', invoice.igst, baseFontSize),
                pw.Divider(color: PdfColors.grey400),
                _buildTotalRow(
                  'Grand Total:',
                  invoice.totalAmount,
                  baseFontSize + 2,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double amount,
    double fontSize, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '₹${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(SalesInvoice invoice, {required double baseFontSize}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Declaration:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: baseFontSize)),
        pw.Text(
          'We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.',
          style: pw.TextStyle(fontSize: baseFontSize - 2),
        ),
        pw.SizedBox(height: 20),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Authorized Signatory', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: baseFontSize)),
        ),
      ],
    );
  }
}
