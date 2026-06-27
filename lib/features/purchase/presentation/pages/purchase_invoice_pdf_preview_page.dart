import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/purchase_invoice.dart';
import '../../domain/services/purchase_invoice_pdf_service.dart';
import 'package:billy_way/core/theme/app_colors.dart';

class PurchaseInvoicePdfPreviewPage extends StatelessWidget {
  final PurchaseInvoice invoice;
  final String formatType;
  final bool fromNewPurchase;

  const PurchaseInvoicePdfPreviewPage({
    super.key,
    required this.invoice,
    required this.formatType,
    this.fromNewPurchase = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview - ${invoice.vendorBillNo ?? invoice.internalRefNo} ($formatType)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Pop the preview page
            if (fromNewPurchase) {
              context.pop(); // Pop the New Purchase page to return to main list and trigger reload
            }
          },
        ),
      ),
      body: PdfPreview(
        build: (format) => PurchaseInvoicePdfService.generatePdf(invoice, formatType),
        initialPageFormat: _getInitialFormat(formatType),
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'Purchase_${(invoice.vendorBillNo ?? invoice.internalRefNo).replaceAll('/', '_')}.pdf',
        previewPageMargin: const EdgeInsets.all(10),
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }

  PdfPageFormat _getInitialFormat(String type) {
    switch (type) {
      case 'A6':
        return PdfPageFormat.a6;
      case 'A5':
        return PdfPageFormat.a5;
      case 'POS':
        return PdfPageFormat.roll80;
      case 'A4':
      default:
        return PdfPageFormat.a4;
    }
  }
}
