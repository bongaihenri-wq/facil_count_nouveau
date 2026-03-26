import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
// import 'screens/home_screen_old.dart';
import 'presentation/screens/home/home_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/login_screen.dart';
import 'screens/stock_screen.dart';

// Presentation screens
import 'presentation/screens/expenses/expense_screen.dart';
import 'presentation/screens/sales/sale_screen.dart';
import 'presentation/screens/purchases/purchase_screen.dart';
import 'presentation/screens/products/product_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/cash/cash_screen.dart';

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
      },
      initialRoute: '/',
    );
  }
}
