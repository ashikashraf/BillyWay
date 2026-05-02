import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/master_repository.dart';

class SupabaseMasterRepository implements MasterRepository {
  final SupabaseClient _supabaseClient;

  SupabaseMasterRepository(this._supabaseClient);

  @override
  Future<Map<String, dynamic>> insertMasterRecord(String tableName, Map<String, dynamic> data) async {
    try {
      final response = await _supabaseClient.from(tableName).insert(data).select().single();
      return response;
    } catch (e) {
      // In a production app, map this to domain-specific exceptions.
      throw Exception('Failed to insert record: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMasterRecords(String tableName) async {
    try {
      final response = await _supabaseClient.from(tableName).select().order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch records: $e');
    }
  }
}
