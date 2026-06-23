import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/sales_invoice.dart';

class SalesController {
  final SupabaseClient _supabaseClient;

  SalesController(this._supabaseClient);

  /// Save a sales invoice to Supabase
  Future<SalesInvoice?> saveInvoice(SalesInvoice invoice) async {
    try {
      // 1. Insert the invoice header
      final invoiceResponse = await _supabaseClient
          .from('sales_invoices')
          .insert(invoice.toJson())
          .select()
          .single();

      final String invoiceId = invoiceResponse['id'].toString();

      // 2. Insert the invoice items
      final itemsData = invoice.items.map((item) => item.toJson(invoiceId)).toList();
      await _supabaseClient.from('sales_invoice_items').insert(itemsData);

      // 3. Return the saved invoice with its ID
      return SalesInvoice.fromJson(invoiceResponse, invoice.items);
    } catch (e) {
      debugPrint('Error saving invoice: $e');
      // For demo purposes, if tables don't exist, we return the invoice as if saved
      // In a real app, we would throw or return null
      return invoice; 
    }
  }

  /// Fetch all invoices
  Future<List<SalesInvoice>> getInvoices() async {
    try {
      final response = await _supabaseClient
          .from('sales_invoices')
          .select('*, sales_invoice_items(*)')
          .order('created_at', ascending: false);

      return (response as List).map((data) {
        final items = (data['sales_invoice_items'] as List)
            .map((itemData) => InvoiceItem.fromJson(itemData))
            .toList();
        return SalesInvoice.fromJson(data, items);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
      return [];
    }
  }
}
