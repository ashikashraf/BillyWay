import 'package:billy_way/features/purchase/data/models/purchase_invoice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PurchaseController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<PurchaseInvoice?> savePurchaseInvoice(PurchaseInvoice invoice) async {
    try {
      final invoiceData = invoice.toJson();

      // Insert purchase invoice
      final insertedInvoiceData = await _supabase
          .from('purchase_invoices')
          .insert(invoiceData)
          .select()
          .single();

      final purchaseInvoiceId = insertedInvoiceData['id'].toString();

      // Insert purchase invoice items
      final itemsData = invoice.items
          .map((item) => item.toJson(purchaseInvoiceId))
          .toList();

      final insertedItemsData = await _supabase
          .from('purchase_invoice_items')
          .insert(itemsData)
          .select();

      final insertedItems = (insertedItemsData as List)
          .map((itemJson) => PurchaseInvoiceItem.fromJson(itemJson))
          .toList();

      return PurchaseInvoice.fromJson(insertedInvoiceData, insertedItems);
    } catch (e) {
      debugPrint('Error saving purchase invoice: $e');
      rethrow;
    }
  }

  Future<List<PurchaseInvoice>> getPurchaseInvoices() async {
    try {
      final response = await _supabase
          .from('purchase_invoices')
          .select('*, purchase_invoice_items(*)')
          .order('created_at', ascending: false);

      return (response as List).map((data) {
        final items = (data['purchase_invoice_items'] as List)
            .map((itemData) => PurchaseInvoiceItem.fromJson(itemData))
            .toList();
        return PurchaseInvoice.fromJson(data, items);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching purchase invoices: $e');
      return [];
    }
  }
}
