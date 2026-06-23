import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:billy_way/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:billy_way/shared/widgets/main_layout.dart';
import 'package:billy_way/features/sales/presentation/pages/sales_page.dart';
import 'package:billy_way/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:billy_way/features/sales/presentation/pages/new_invoice_page.dart';
import 'package:billy_way/features/purchase/presentation/pages/purchase_page.dart';
import 'package:billy_way/features/purchase/presentation/pages/new_purchase_page.dart';
import 'package:billy_way/features/stock/presentation/pages/product_entry_page.dart';
import 'package:billy_way/features/parties/presentation/pages/ledger_entry_page.dart';
import 'package:billy_way/features/masters/presentation/pages/master_management_page.dart';
import 'package:billy_way/features/auth/presentation/pages/login_page.dart';
import 'package:billy_way/features/auth/presentation/pages/user_management_page.dart';
import 'package:billy_way/features/quotation/presentation/pages/quotation_page.dart';
import 'package:billy_way/features/quotation/presentation/pages/new_quotation_page.dart';
import 'package:billy_way/features/quotation/domain/controllers/quotation_controller.dart';
import 'package:billy_way/features/estimate/presentation/pages/estimate_page.dart';
import 'package:billy_way/features/estimate/presentation/pages/new_estimate_page.dart';
import 'package:billy_way/features/estimate/presentation/pages/estimate_pdf_preview_page.dart';
import 'package:billy_way/features/estimate/domain/controllers/estimate_controller.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:billy_way/features/auth/domain/repositories/auth_repository.dart';
import 'package:billy_way/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:billy_way/features/masters/domain/controllers/master_data_controller.dart';
import 'package:billy_way/features/sales/domain/controllers/sales_controller.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(Supabase.instance.client),
  );
  getIt.registerLazySingleton<MasterDataController>(
    () => MasterDataController(Supabase.instance.client),
  );
  getIt.registerLazySingleton<SalesController>(
    () => SalesController(Supabase.instance.client),
  );
  getIt.registerLazySingleton<QuotationController>(
    () => QuotationController(Supabase.instance.client),
  );
  getIt.registerLazySingleton<EstimateController>(
    () => EstimateController(Supabase.instance.client),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (Placeholder credentials - user needs to provide real ones)
  await Supabase.initialize(
    url: 'https://yoactmzcmfitnfzmyffe.supabase.co',
    anonKey: 'sb_publishable_PlCQZOxkOiF6sD49QPy37Q_I9nMujol',
  );

  setupDependencies();
  
  // Optionally fetch initial role if already logged in
  if (Supabase.instance.client.auth.currentSession != null) {
    await getIt<AuthRepository>().getUserRole();
    getIt<MasterDataController>().initRealtimeSync();
  }

  runApp(const BillyWayApp());
}


class BillyWayApp extends StatelessWidget {
  const BillyWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(
        1440,
        900,
      ), // Standard Desktop size for responsiveness
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'BillyWay ERP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _router,
        );
      },
    );
  }
}

// Simple placeholder router
final GoRouter _router = GoRouter(
  initialLocation: '/login', // Start with login
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggingIn = state.matchedLocation == '/login';

    if (session == null) {
      return isLoggingIn ? null : '/login';
    }

    if (isLoggingIn) {
      return '/'; // Redirect to dashboard if logged in
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
        GoRoute(path: '/sales', builder: (context, state) => const SalesPage()),
        GoRoute(
          path: '/new-invoice',
          builder: (context, state) => const NewInvoicePage(),
        ),
        GoRoute(
          path: '/quotations',
          builder: (context, state) => const QuotationPage(),
        ),
        GoRoute(
          path: '/new-quotation',
          builder: (context, state) => const NewQuotationPage(),
        ),
        GoRoute(
          path: '/estimates',
          builder: (context, state) => const EstimatePage(),
        ),
        GoRoute(
          path: '/new-estimate',
          builder: (context, state) => const NewEstimatePage(),
        ),
        GoRoute(
          path: '/estimate-preview',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return EstimatePdfPreviewPage(
              estimate: args['estimate'],
              formatType: args['formatType'] ?? 'A4',
              fromNewEstimate: args['fromNewEstimate'] ?? false,
            );
          },
        ),
        GoRoute(
          path: '/purchase',
          builder: (context, state) => const PurchasePage(),
        ),
        GoRoute(
          path: '/new-purchase',
          builder: (context, state) => const NewPurchasePage(),
        ),
        GoRoute(
          path: '/stock',
          builder: (context, state) => const PlaceholderPage(title: 'Stock'),
        ),
        GoRoute(
          path: '/transfers',
          builder: (context, state) =>
              const PlaceholderPage(title: 'Transfers'),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) =>
              const PlaceholderPage(title: 'GST Reports'),
        ),
        GoRoute(
          path: '/masters',
          builder: (context, state) => const MasterManagementPage(),
        ),
        GoRoute(
          path: '/parties',
          builder: (context, state) => const LedgerEntryPage(),
        ),
        GoRoute(
          path: '/items',
          builder: (context, state) => const ProductEntryPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const PlaceholderPage(title: 'Settings'),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UserManagementPage(),
        ),
      ],
    ),
  ],
);

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to BillyWay',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: const Text('Get Started')),
          ],
        ),
      ),
    );
  }
}
