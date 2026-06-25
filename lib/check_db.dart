// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// void main() async {
//   await dotenv.load(fileName: ".env");
//   final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
//   final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

//   await Supabase.initialize(
//     url: supabaseUrl,
//     anonKey: supabaseKey,
//   );

//   final client = Supabase.instance.client;

//   print('--- LEDGERS ---');
//   try {
//     final ledgers = await client.from('ledgers').select().limit(1);
//     print(ledgers);
//   } catch(e) {
//     print('Error fetching ledgers: $e');
//   }

//   print('--- PRODUCTS ---');
//   try {
//     final products = await client.from('products').select().limit(1);
//     print(products);
//   } catch(e) {
//     print('Error fetching products: $e');
//   }
// }
