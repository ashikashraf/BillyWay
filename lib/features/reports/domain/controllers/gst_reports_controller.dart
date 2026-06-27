import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class GstReportsController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchGstr1Summary(DateTime startDate, DateTime endDate) async {
    try {
      // Fetch B2B Sales (with GSTIN)
      final b2bData = await _supabase
          .from('sales_invoices')
          .select('subtotal, cgst, sgst, igst, total_tax, total_amount')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .not('gstin', 'is', null)
          .neq('gstin', '');

      // Fetch B2C Sales (without GSTIN)
      final b2cData = await _supabase
          .from('sales_invoices')
          .select('subtotal, cgst, sgst, igst, total_tax, total_amount')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .or('gstin.is.null, gstin.eq.""');

      // Aggregate
      double b2bTaxable = 0, b2bTax = 0;
      for (var row in b2bData) {
        b2bTaxable += (row['subtotal'] as num).toDouble();
        b2bTax += (row['total_tax'] as num).toDouble();
      }

      double b2cTaxable = 0, b2cTax = 0;
      for (var row in b2cData) {
        b2cTaxable += (row['subtotal'] as num).toDouble();
        b2cTax += (row['total_tax'] as num).toDouble();
      }

      return {
        'b2b_taxable': b2bTaxable,
        'b2b_tax': b2bTax,
        'b2c_taxable': b2cTaxable,
        'b2c_tax': b2cTax,
        'total_taxable': b2bTaxable + b2cTaxable,
        'total_tax': b2bTax + b2cTax,
      };
    } catch (e) {
      debugPrint('Error fetching GSTR-1: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchGstr2bSummary(DateTime startDate, DateTime endDate) async {
    try {
      // Fetch all eligible ITC from itc_ledger
      final itcData = await _supabase
          .from('itc_ledger')
          .select('itc_available')
          .eq('itc_eligible', true)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      double totalItc = 0;
      for (var row in itcData) {
        totalItc += (row['itc_available'] as num).toDouble();
      }

      return {
        'total_itc_available': totalItc,
      };
    } catch (e) {
      debugPrint('Error fetching GSTR-2B: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchGstr3bSummary(DateTime startDate, DateTime endDate) async {
    try {
      final gstr1 = await fetchGstr1Summary(startDate, endDate);
      final gstr2b = await fetchGstr2bSummary(startDate, endDate);

      double outwardLiability = gstr1['total_tax'] ?? 0.0;
      double eligibleItc = gstr2b['total_itc_available'] ?? 0.0;
      
      // Calculate Net Liability (Outward - ITC)
      double netLiability = outwardLiability - eligibleItc;
      if (netLiability < 0) netLiability = 0; // ITC Carry forward

      return {
        'outward_tax_liability': outwardLiability,
        'eligible_itc': eligibleItc,
        'net_tax_payable': netLiability,
      };
    } catch (e) {
      debugPrint('Error fetching GSTR-3B: $e');
      return {};
    }
  }
}
