class TaxEngine {
  /// Computes the overall tax breakdown for an invoice or purchase order.
  /// 
  /// Returns a map containing all computed values:
  /// - `taxableValue`: Total value before tax
  /// - `cgstTotal`: Total CGST amount
  /// - `sgstTotal`: Total SGST amount
  /// - `igstTotal`: Total IGST amount
  /// - `cessTotal`: Total CESS amount
  /// - `grandTotal`: Total invoice value including taxes
  /// - `isInterState`: Boolean indicating if IGST was applied instead of CGST/SGST
  static Map<String, dynamic> computeInvoiceTax({
    required List<Map<String, dynamic>> items,
    required String branchStateCode,
    required String partyStateCode,
  }) {
    // Determine Intra-state vs Inter-state
    // If state codes are same, it's Intra-state (CGST+SGST). Else Inter-state (IGST).
    bool isInterState = branchStateCode.trim().toLowerCase() != partyStateCode.trim().toLowerCase();

    // If either state code is missing, fallback to Intra-state safely or throw error depending on strictness
    if (branchStateCode.isEmpty || partyStateCode.isEmpty) {
      isInterState = false; // Fallback
    }

    double totalTaxableValue = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;
    double totalCess = 0;

    for (var item in items) {
      // Extract values with safe defaults
      double quantity = double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0;
      double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0.0;
      double gstPercent = double.tryParse(item['gst_rate']?.toString() ?? '18') ?? 18.0;
      double discount = double.tryParse(item['discount']?.toString() ?? '0') ?? 0.0;
      double cessPercent = double.tryParse(item['cess_rate']?.toString() ?? '0') ?? 0.0;

      // Basic Taxable Value Calculation (Qty * Rate - Discount)
      double itemTaxableValue = (quantity * rate) - discount;
      if (itemTaxableValue < 0) itemTaxableValue = 0;

      double itemGstAmount = itemTaxableValue * (gstPercent / 100);
      double itemCessAmount = itemTaxableValue * (cessPercent / 100);

      double itemCgst = 0;
      double itemSgst = 0;
      double itemIgst = 0;

      if (isInterState) {
        itemIgst = itemGstAmount;
      } else {
        itemCgst = itemGstAmount / 2;
        itemSgst = itemGstAmount / 2;
      }

      // Mutate the original item map to store its specific tax breakdown (useful for database saving)
      item['taxable_value'] = double.parse(itemTaxableValue.toStringAsFixed(2));
      item['cgst_amount'] = double.parse(itemCgst.toStringAsFixed(2));
      item['sgst_amount'] = double.parse(itemSgst.toStringAsFixed(2));
      item['igst_amount'] = double.parse(itemIgst.toStringAsFixed(2));
      item['cess_amount'] = double.parse(itemCessAmount.toStringAsFixed(2));
      item['total_tax'] = double.parse((itemCgst + itemSgst + itemIgst + itemCessAmount).toStringAsFixed(2));
      item['net_amount'] = double.parse((itemTaxableValue + itemCgst + itemSgst + itemIgst + itemCessAmount).toStringAsFixed(2));

      // Aggregate totals
      totalTaxableValue += itemTaxableValue;
      totalCgst += itemCgst;
      totalSgst += itemSgst;
      totalIgst += itemIgst;
      totalCess += itemCessAmount;
    }

    double grandTotal = totalTaxableValue + totalCgst + totalSgst + totalIgst + totalCess;

    return {
      'isInterState': isInterState,
      'supply_type': isInterState ? 'INTER_STATE' : 'INTRA_STATE',
      'taxableValue': double.parse(totalTaxableValue.toStringAsFixed(2)),
      'cgstTotal': double.parse(totalCgst.toStringAsFixed(2)),
      'sgstTotal': double.parse(totalSgst.toStringAsFixed(2)),
      'igstTotal': double.parse(totalIgst.toStringAsFixed(2)),
      'cessTotal': double.parse(totalCess.toStringAsFixed(2)),
      'grandTotal': double.parse(grandTotal.toStringAsFixed(2)),
    };
  }
}
