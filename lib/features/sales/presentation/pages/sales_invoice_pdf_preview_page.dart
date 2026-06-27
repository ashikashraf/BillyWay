import 'package:flutter/material.dart';
import 'package:billy_way/core/widgets/app_loading_animation.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/sales_invoice.dart';
import '../../domain/services/sales_invoice_pdf_service.dart';
import 'package:billy_way/core/theme/app_colors.dart';

class SalesInvoicePdfPreviewPage extends StatelessWidget {
  final SalesInvoice invoice;
  final String formatType;
  final bool fromNewInvoice;

  const SalesInvoicePdfPreviewPage({
    super.key,
    required this.invoice,
    required this.formatType,
    this.fromNewInvoice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview - ${invoice.invoiceNumber} ($formatType)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Pop the preview page
            if (fromNewInvoice) {
              context.pop(); // Pop the New Invoice page to return to main list and trigger reload
            }
          },
        ),
      ),
      body: PdfPreview(
        build: (format) => SalesInvoicePdfService.generatePdf(invoice, formatType),
        initialPageFormat: _getInitialFormat(formatType),
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'Invoice_${invoice.invoiceNumber.replaceAll('/', '_')}.pdf',
        previewPageMargin: const EdgeInsets.all(10),
        loadingWidget: const Center(
          child: const AppLoadingAnimation(),
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
