import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/pages/master_management_page.dart';

class MasterDataController {
  final SupabaseClient _supabaseClient;
  
  // A notifier containing a map of all master data, keyed by table name
  final ValueNotifier<Map<String, List<Map<String, dynamic>>>> masterDataNotifier = 
    ValueNotifier({});

  // To track initialization state
  bool isInitialized = false;

  MasterDataController(this._supabaseClient);

  /// Get the table name from MasterModule
  String getTableName(MasterModule module) {
    switch (module) {
      case MasterModule.ledgerGroup: return 'ledger_groups';
      case MasterModule.hsnCode: return 'hsn_codes';
      case MasterModule.itemCategory: return 'item_categories';
      case MasterModule.taxClass: return 'tax_classes';
      case MasterModule.transactionType: return 'transaction_types';
      case MasterModule.sundryType: return 'sundry_types';
      case MasterModule.uom: return 'units';
      case MasterModule.brand: return 'brands';
      case MasterModule.warehouse: return 'warehouses';
    }
  }

  /// Initialize real-time sync for all master tables
  Future<void> initRealtimeSync() async {
    if (isInitialized) return;

    final initialData = <String, List<Map<String, dynamic>>>{};
    final tables = MasterModule.values.map((m) => getTableName(m)).toList();
    
    // Also include ledgers and products
    tables.addAll(['ledgers', 'products']);
    
    // 1. Fetch initial data concurrently
    await Future.wait(tables.map((table) async {
      try {
        final response = await _supabaseClient.from(table).select().order('created_at', ascending: false);
        initialData[table] = List<Map<String, dynamic>>.from(response);
      } catch (e) {
        debugPrint('Error fetching initial data for $table: $e');
        initialData[table] = [];
      }
    }));
    
    masterDataNotifier.value = initialData;
    isInitialized = true;

    // 2. Subscribe to real-time events for each table
    for (final table in tables) {
      _supabaseClient.channel('public:$table').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) {
          _handleRealtimeUpdate(table, payload);
        },
      ).subscribe();
    }
  }

  /// Optimistically add a newly created record to the local cache 
  /// so UI updates immediately without waiting for the WebSocket ping.
  void addRecordOptimistically(String table, Map<String, dynamic> record) {
    final currentData = Map<String, List<Map<String, dynamic>>>.from(masterDataNotifier.value);
    final tableList = List<Map<String, dynamic>>.from(currentData[table] ?? []);
    
    if (!tableList.any((e) => e['id'] == record['id'])) {
      tableList.insert(0, record);
      currentData[table] = tableList;
      masterDataNotifier.value = currentData;
    }
  }

  void _handleRealtimeUpdate(String table, PostgresChangePayload payload) {
    final currentData = Map<String, List<Map<String, dynamic>>>.from(masterDataNotifier.value);
    final tableList = List<Map<String, dynamic>>.from(currentData[table] ?? []);

    if (payload.eventType == PostgresChangeEvent.insert) {
      final newRecord = payload.newRecord;
      if (!tableList.any((e) => e['id'] == newRecord['id'])) {
        tableList.insert(0, newRecord); // Insert at top
      }
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final updatedRecord = payload.newRecord;
      final index = tableList.indexWhere((e) => e['id'] == updatedRecord['id']);
      if (index != -1) {
        tableList[index] = updatedRecord;
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final deletedId = payload.oldRecord['id'];
      tableList.removeWhere((e) => e['id'] == deletedId);
    }

    currentData[table] = tableList;
    masterDataNotifier.value = currentData;
  }
}
