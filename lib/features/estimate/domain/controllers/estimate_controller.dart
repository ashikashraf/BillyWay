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

  /// Fetch all estimates
  Future<List<Estimate>> getEstimates() async {
    try {
      final response = await _supabaseClient
          .from('estimates')
          .select('*, estimate_items(*)')
          .order('created_at', ascending: false);

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
