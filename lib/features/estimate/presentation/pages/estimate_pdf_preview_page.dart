import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/estimate.dart';
import '../../domain/services/estimate_pdf_service.dart';
import 'package:billy_way/core/theme/app_colors.dart';

class EstimatePdfPreviewPage extends StatelessWidget {
  final Estimate estimate;
  final String formatType;
  final bool fromNewEstimate;

  const EstimatePdfPreviewPage({
    super.key,
    required this.estimate,
    required this.formatType,
    this.fromNewEstimate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview - ${estimate.estimateNumber} ($formatType)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Pop the preview page
            if (fromNewEstimate) {
              context
                  .pop(); // Pop the New Estimate page to return to main list and trigger reload
            }
          },
        ),
      ),
      body: PdfPreview(
        build: (format) => EstimatePdfService.generatePdf(estimate, formatType),
        initialPageFormat: _getInitialFormat(formatType),
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'Estimate_${estimate.estimateNumber}.pdf',
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
