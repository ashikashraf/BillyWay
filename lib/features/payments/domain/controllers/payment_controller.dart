import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PaymentController extends ChangeNotifier {
  final SupabaseClient _supabase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _partyBalances = [];
  List<Map<String, dynamic>> get partyBalances => _partyBalances;

  PaymentController(this._supabase) {
    fetchPartyBalances();
  }

  /// Fetch all real-time party balances from the database view
  Future<void> fetchPartyBalances() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.from('current_party_balances').select();
      _partyBalances = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching party balances: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get the current balance of a specific ledger
  double getBalanceForLedger(String ledgerId) {
    final ledger = _partyBalances.firstWhere(
      (element) => element['ledger_id'] == ledgerId,
      orElse: () => {'current_balance': 0.0},
    );
    // Convert to double carefully
    final balance = ledger['current_balance'];
    if (balance is double) return balance;
    if (balance is int) return balance.toDouble();
    if (balance is String) return double.tryParse(balance) ?? 0.0;
    return 0.0;
  }

  /// Record a new payment (either receipt or out)
  Future<void> recordPayment({
    required String paymentNumber,
    required String ledgerId,
    required String paymentType, // 'RECEIPT' or 'PAYMENT'
    required String paymentMode, // 'CASH', 'BANK', 'UPI', 'CHEQUE'
    required double amount,
    required DateTime paymentDate,
    String? referenceNo,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.from('payments').insert({
        'payment_number': paymentNumber,
        'ledger_id': ledgerId,
        'payment_type': paymentType,
        'payment_mode': paymentMode,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        'reference_no': referenceNo,
        'notes': notes,
      });

      // After recording a payment, refresh balances so UI updates
      await fetchPartyBalances();
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
