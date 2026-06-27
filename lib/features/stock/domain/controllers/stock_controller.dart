import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StockController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches real-time available stock for a specific product
  Future<double> getAvailableStock(String productName, {String? warehouseId}) async {
    try {
      var query = _supabase
          .from('current_stock_view')
          .select('available_stock')
          .eq('product_name', productName);
          
      if (warehouseId != null) {
        query = query.eq('warehouse_id', warehouseId);
      }
      
      final response = await query;
      
      double totalStock = 0.0;
      for (var row in response) {
        if (row['available_stock'] != null) {
          totalStock += (row['available_stock'] as num).toDouble();
        }
      }
      return totalStock;
      return 0.0;
    } catch (e) {
      debugPrint('Error fetching stock for $productName: $e');
      return 0.0;
    }
  }

  /// Injects Opening Stock into the Stock Ledger
  Future<void> addOpeningStock(String productName, double qty) async {
    try {
      await _supabase.from('stock_ledger').insert({
        'product_name': productName,
        'transaction_type': 'OPENING',
        'document_ref': 'OPENING_BAL',
        'qty_in': qty,
        'qty_out': 0,
      });
    } catch (e) {
      debugPrint('Error inserting opening stock: $e');
      rethrow;
    }
  }

  /// Create a new Product and set its Opening Stock
  Future<void> createProductWithOpeningStock(Map<String, dynamic> productData, double openingStock) async {
    try {
      final productName = productData['name'] as String;
      
      // 1. Insert product into products master table
      await _supabase.from('products').insert(productData);

      // 2. Insert opening stock into ledger
      if (openingStock > 0) {
        await addOpeningStock(productName, openingStock);
      }
    } catch (e) {
      debugPrint('Error creating product: $e');
      rethrow;
    }
  }
}
