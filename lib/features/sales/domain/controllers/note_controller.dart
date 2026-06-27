import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/credit_note.dart';
import '../../../purchase/data/models/debit_note.dart';

class NoteController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<CreditNote?> saveCreditNote(CreditNote note) async {
    try {
      final noteData = note.toJson();

      final insertedNoteData = await _supabase
          .from('credit_notes')
          .insert(noteData)
          .select()
          .single();

      final noteId = insertedNoteData['id'].toString();

      final itemsData = note.items.map((item) => item.toJson(noteId)).toList();

      final insertedItemsData = await _supabase
          .from('credit_note_items')
          .insert(itemsData)
          .select();

      final insertedItems = (insertedItemsData as List)
          .map((itemJson) => CreditNoteItem.fromJson(itemJson))
          .toList();

      return CreditNote.fromJson(insertedNoteData, insertedItems);
    } catch (e) {
      debugPrint('Error saving credit note: $e');
      rethrow;
    }
  }

  Future<DebitNote?> saveDebitNote(DebitNote note) async {
    try {
      final noteData = note.toJson();

      final insertedNoteData = await _supabase
          .from('debit_notes')
          .insert(noteData)
          .select()
          .single();

      final noteId = insertedNoteData['id'].toString();

      final itemsData = note.items.map((item) => item.toJson(noteId)).toList();

      final insertedItemsData = await _supabase
          .from('debit_note_items')
          .insert(itemsData)
          .select();

      final insertedItems = (insertedItemsData as List)
          .map((itemJson) => DebitNoteItem.fromJson(itemJson))
          .toList();

      return DebitNote.fromJson(insertedNoteData, insertedItems);
    } catch (e) {
      debugPrint('Error saving debit note: $e');
      rethrow;
    }
  }
}
