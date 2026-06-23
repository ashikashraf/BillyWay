import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/quotation.dart';

class QuotationController {
  final SupabaseClient _supabaseClient;

  QuotationController(this._supabaseClient);

  /// Save a quotation to Supabase
  Future<Quotation?> saveQuotation(Quotation quotation) async {
    try {
      final response = await _supabaseClient
          .from('quotations')
          .insert(quotation.toJson())
          .select()
          .single();

      final String quotationId = response['id'].toString();

      final itemsData = quotation.items
          .map((item) => item.toJson(quotationId))
          .toList();
      await _supabaseClient.from('quotation_items').insert(itemsData);

      return Quotation.fromJson(response, quotation.items);
    } catch (e) {
      debugPrint('Error saving quotation: $e');
      return quotation;
    }
  }

  /// Fetch all quotations
  Future<List<Quotation>> getQuotations() async {
    try {
      final response = await _supabaseClient
          .from('quotations')
          .select('*, quotation_items(*)')
          .order('created_at', ascending: false);

      return (response as List).map((data) {
        final items = (data['quotation_items'] as List)
            .map((itemData) => QuotationItem.fromJson(itemData))
            .toList();
        return Quotation.fromJson(data, items);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching quotations: $e');
      return [];
    }
  }
}
