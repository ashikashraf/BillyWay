class GstCalculator {
  /// Checks if the supply is inter-state (IGST) or intra-state (CGST+SGST)
  static bool isInterState(String fromStateCode, String toStateCode) {
    return fromStateCode.toLowerCase() != toStateCode.toLowerCase();
  }

  /// Calculates GST breakdown for a given taxable amount and GST rate slab.
  /// [gstRate] is the total percentage (e.g., 18.0)
  static Map<String, double> calculate({
    required double taxableAmount,
    required double gstRate,
    required bool isInterState,
  }) {
    if (isInterState) {
      return {
        'igst': (taxableAmount * gstRate) / 100,
        'cgst': 0.0,
        'sgst': 0.0,
        'totalGst': (taxableAmount * gstRate) / 100,
      };
    } else {
      double halfRate = gstRate / 2;
      double gstValue = (taxableAmount * halfRate) / 100;
      return {
        'igst': 0.0,
        'cgst': gstValue,
        'sgst': gstValue,
        'totalGst': gstValue * 2,
      };
    }
  }

  /// Calculates the taxable amount from a GST inclusive price.
  static double getTaxableFromInclusive({
    required double inclusivePrice,
    required double gstRate,
  }) {
    return (inclusivePrice * 100) / (100 + gstRate);
  }
}
