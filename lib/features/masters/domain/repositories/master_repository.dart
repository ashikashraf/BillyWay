abstract class MasterRepository {
  /// Inserts a new master record into the specified table.
  /// 
  /// [tableName] is the Supabase table name (e.g. 'ledger_groups', 'hsn_codes').
  /// [data] is the key-value map corresponding to the table columns.
  Future<Map<String, dynamic>> insertMasterRecord(String tableName, Map<String, dynamic> data);
  
  /// Fetches records from a specified master table.
  /// Optionally supports simple filtering or sorting if needed later.
  Future<List<Map<String, dynamic>>> fetchMasterRecords(String tableName);
}
