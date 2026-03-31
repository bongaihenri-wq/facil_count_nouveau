import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/invoices/invoices_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'screens/stock_screen.dart';

// Presentation screens
import 'presentation/screens/expenses/expense_screen.dart';
import 'presentation/screens/sales/sale_screen.dart';
import 'presentation/screens/purchases/purchase_screen.dart';
import 'presentation/screens/products/product_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/cash/cash_screen.dart';
// Routes pour User Profil
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/user_management_screen.dart';
import 'presentation/screens/home/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Erreur chargement .env: $e');
    throw Exception('Impossible de charger les variables d\'environnement.');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Les clés Supabase sont manquantes dans le fichier .env.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: false,
  );

  runApp(const ProviderScope(child: FacilCountApp()));
}

class FacilCountApp extends StatelessWidget {
  const FacilCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facil Count',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      locale: const Locale('fr'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700,
          primary: Colors.blue.shade700,
        ),
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
      ),
      // ✅ PopScope pour confirmation avant quitter
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    const Text('Quitter ?'),
                  ],
                ),
                content: const Text(
                  'Voulez-vous vraiment quitter FacilCount ?',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Non'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Oui'),
                  ),
                ],
              ),
            );
            
            if (shouldExit == true) {
              SystemNavigator.pop();
            }
          },
          child: child!,
        );
      },
      routes: {
        '/': (context) => const HomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/purchases': (context) => const PurchaseScreen(),
        '/sales': (context) => const SaleScreen(),
        '/expenses': (context) => const ExpenseScreen(),
        '/invoices': (context) => const InvoicesScreen(),
        '/products': (context) => const ProductScreen(),
        '/stock': (context) => const StockScreen(),
        '/cash': (context) => const CashScreen(),
        '/login': (context) => const LoginScreen(),
        // ✅ Routes User Profil
        '/profile': (context) => const ProfileScreen(),
        '/user-management': (context) => const UserManagementScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
      initialRoute: '/login',
    );
  }
}
