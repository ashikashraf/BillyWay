import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SettingsController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cached settings
  Map<String, dynamic>? companySettings;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SettingsController() {
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('company_settings').select().maybeSingle();
      
      if (response != null) {
        companySettings = response;
      }
    } catch (e) {
      debugPrint('Error fetching company settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (companySettings != null && companySettings!['id'] != null) {
        // Update existing
        final response = await _supabase
            .from('company_settings')
            .update(data)
            .eq('id', companySettings!['id'])
            .select()
            .single();
        companySettings = response;
      } else {
        // Insert new
        final response = await _supabase
            .from('company_settings')
            .insert(data)
            .select()
            .single();
        companySettings = response;
      }
    } catch (e) {
      debugPrint('Error updating company settings: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to get Branch State Code quickly
  String get branchStateCode {
    return companySettings?['state_code'] ?? '32';
  }

  /// Multi-Warehouse Settings
  bool get enableMultiWarehouse {
    return companySettings?['enable_multi_warehouse'] ?? false;
  }

  String? get defaultWarehouseId {
    return companySettings?['default_warehouse_id'];
  }
}
