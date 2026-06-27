import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class TransferController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createTransfer({
    required String transferNumber,
    required DateTime date,
    required String sourceWarehouseId,
    required String destinationWarehouseId,
    required String status,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // 1. Insert the Transfer Document
      final transferResponse = await _supabase.from('stock_transfers').insert({
        'transfer_number': transferNumber,
        'date': date.toIso8601String(),
        'source_warehouse_id': sourceWarehouseId,
        'destination_warehouse_id': destinationWarehouseId,
        'status': status,
        'notes': notes,
      }).select().single();

      final transferId = transferResponse['id'];

      // 2. Insert Transfer Items
      final itemsData = items.map((item) {
        return {
          'transfer_id': transferId,
          'product_name': item['product_name'],
          'qty': item['qty'],
        };
      }).toList();

      await _supabase.from('stock_transfer_items').insert(itemsData);

    } catch (e) {
      debugPrint('Error creating transfer: $e');
      rethrow;
    }
  }
}
