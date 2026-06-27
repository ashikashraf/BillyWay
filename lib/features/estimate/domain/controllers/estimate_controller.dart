import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/estimate.dart';

class EstimateController {
  final SupabaseClient _supabaseClient;

  EstimateController(this._supabaseClient);

  /// Save an estimate to Supabase
  Future<Estimate?> saveEstimate(Estimate estimate) async {
    try {
      final response = await _supabaseClient
          .from('estimates')
          .insert(estimate.toJson())
          .select()
          .single();

      final String estimateId = response['id'].toString();

      final itemsData = estimate.items
          .map((item) => item.toJson(estimateId))
          .toList();
      await _supabaseClient.from('estimate_items').insert(itemsData);

      if (estimate.customerName.isNotEmpty) {
        // Update the old balance of the customer
        await _supabaseClient
            .from('estimate_customers')
            .update({'ob': estimate.balance})
            .eq('name', estimate.customerName);
      }

      return Estimate.fromJson(response, estimate.items);
    } catch (e) {
      debugPrint('Error saving estimate: $e');
      return estimate;
    }
  }

  /// Update an existing estimate
  Future<Estimate?> updateEstimate(Estimate estimate) async {
    try {
      if (estimate.id == null || estimate.id!.isEmpty) {
        throw Exception('Estimate ID is required for update');
      }

      final String estimateId = estimate.id!;

      // 1. Update the estimate record
      final response = await _supabaseClient
          .from('estimates')
          .update(estimate.toJson())
          .eq('id', estimateId)
          .select()
          .single();

      // 2. Delete existing items
      await _supabaseClient
          .from('estimate_items')
          .delete()
          .eq('estimate_id', estimateId);

      // 3. Insert new items
      final itemsData = estimate.items
          .map((item) => item.toJson(estimateId))
          .toList();
      await _supabaseClient.from('estimate_items').insert(itemsData);

      // 4. Update the customer's OB
      if (estimate.customerName.isNotEmpty) {
        await _supabaseClient
            .from('estimate_customers')
            .update({'ob': estimate.balance})
            .eq('name', estimate.customerName);
      }

      return Estimate.fromJson(response, estimate.items);
    } catch (e) {
      debugPrint('Error updating estimate: $e');
      rethrow;
    }
  }

  /// Fetch all estimates
  Future<List<Estimate>> getEstimates() async {
    try {
      final response = await _supabaseClient
          .from('estimates')
          .select('*, estimate_items(*)')
          .order('created_at', ascending: false)
          .limit(30);

      return (response as List).map((data) {
        final items = (data['estimate_items'] as List)
            .map((itemData) => EstimateItem.fromJson(itemData))
            .toList();
        return Estimate.fromJson(data, items);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching estimates: $e');
      rethrow;
    }
  }

  /// Update estimate status (e.g., mark as cleared)
  Future<void> updateEstimateStatus(String id, String status, double settledAmount, double balance) async {
    try {
      await _supabaseClient.from('estimates').update({
        'status': status,
        'settled_amount': settledAmount,
        'balance': balance,
      }).eq('id', id);

      // We also need to update the customer's old balance if settled
      // Find the estimate first
      final estRes = await _supabaseClient.from('estimates').select('customer_name, old_balance, total').eq('id', id).single();
      if (estRes['customer_name'] != null && estRes['customer_name'].toString().isNotEmpty) {
        // Find current customer ob
        final custRes = await _supabaseClient.from('estimate_customers').select('ob').eq('name', estRes['customer_name']).maybeSingle();
        if (custRes != null) {
          // If clearing a pending estimate, the customer's balance goes down by the settled amount
          double currentOb = (custRes['ob'] as num).toDouble();
          
          // Re-calculate ob: the previous total was added to their ob when the estimate was created.
          // Now we reduce the ob by the settledAmount.
          double newOb = currentOb - settledAmount;
          
          await _supabaseClient
              .from('estimate_customers')
              .update({'ob': newOb})
              .eq('name', estRes['customer_name']);
        }
      }

    } catch (e) {
      debugPrint('Error updating estimate status: $e');
      rethrow;
    }
  }

  /// Delete an estimate
  Future<void> deleteEstimate(String id) async {
    try {
      await _supabaseClient.from('estimates').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting estimate: $e');
      rethrow;
    }
  }

  /// Get next sequential estimate number
  Future<String> getNextEstimateNumber() async {
    try {
      final response = await _supabaseClient
          .from('estimates')
          .select('estimate_number')
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return 'EST-001';

      final lastNo = response.first['estimate_number'] as String;
      final parts = lastNo.split('-');
      if (parts.length == 2) {
        final numPart = int.tryParse(parts[1]);
        if (numPart != null) {
          return 'EST-${(numPart + 1).toString().padLeft(3, '0')}';
        }
      }
      return 'EST-001';
    } catch (e) {
      debugPrint('Error getting next estimate number: $e');
      return 'EST-001';
    }
  }

  Future<EstimateCustomer?> createEstimateCustomer(EstimateCustomer customer) async {
    try {
      final response = await _supabaseClient
          .from('estimate_customers')
          .insert(customer.toJson())
          .select()
          .single();
      return EstimateCustomer.fromJson(response);
    } catch (e) {
      debugPrint('Error creating estimate customer: $e');
      rethrow;
    }
  }

  Future<EstimateCustomer?> updateEstimateCustomer(EstimateCustomer customer) async {
    try {
      if (customer.id == null) return null;
      final response = await _supabaseClient
          .from('estimate_customers')
          .update(customer.toJson())
          .eq('id', customer.id!)
          .select()
          .single();
      return EstimateCustomer.fromJson(response);
    } catch (e) {
      debugPrint('Error updating estimate customer: $e');
      rethrow;
    }
  }

  Future<List<EstimateCustomer>> getEstimateCustomers() async {
    try {
      final response = await _supabaseClient
          .from('estimate_customers')
          .select()
          .order('name', ascending: true);
      return (response as List).map((data) => EstimateCustomer.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching estimate customers: $e');
      return [];
    }
  }

  Future<EstimateProduct?> createEstimateProduct(EstimateProduct product) async {
    try {
      final response = await _supabaseClient
          .from('estimate_products')
          .insert(product.toJson())
          .select()
          .single();
      return EstimateProduct.fromJson(response);
    } catch (e) {
      debugPrint('Error creating estimate product: $e');
      rethrow;
    }
  }

  Future<EstimateProduct?> updateEstimateProduct(EstimateProduct product) async {
    try {
      if (product.id == null) return null;
      final response = await _supabaseClient
          .from('estimate_products')
          .update(product.toJson())
          .eq('id', product.id!)
          .select()
          .single();
      return EstimateProduct.fromJson(response);
    } catch (e) {
      debugPrint('Error updating estimate product: $e');
      rethrow;
    }
  }

  Future<List<EstimateProduct>> getEstimateProducts() async {
    try {
      final response = await _supabaseClient
          .from('estimate_products')
          .select()
          .order('particular', ascending: true);
      return (response as List).map((data) => EstimateProduct.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching estimate products: $e');
      return [];
    }
  }
}
