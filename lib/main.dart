import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/expenses/expense_screen.dart';
import 'presentation/screens/sales/sale_screen.dart';
import 'presentation/screens/purchases/purchase_screen.dart';

import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
//import 'screens/purchases_screen.dart';
//import 'screens/sales_screen.dart';
// import 'screens/expenses_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des données de localisation
  await initializeDateFormatting('fr');

  // Chargement des variables d'environnement
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Erreur chargement .env: $e');
    throw Exception(
      'Impossible de charger les variables d\'environnement. Vérifiez le fichier .env.',
    );
  }

  // Validation des variables Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Les clés Supabase sont manquantes dans le fichier .env.');
  }

  // Initialisation de Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: false,
  );

  runApp(ProviderScope(child: const FacilCountApp()));
}

class FacilCountApp extends ConsumerWidget {
  const FacilCountApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          secondary: Colors.grey.shade600,
          background: Colors.grey.shade100,
          surface: Colors.white,
          error: Colors.red.shade700,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          // Utilisation correcte de CardTheme
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
        ),
      ),
      routes: {
        '/': (context) => const HomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        // '/purchases': (context) => const PurchasesScreen(),
        '/purchases': (context) => const PurchaseScreen(),
        //'/sales': (context) => const SalesScreen(),
        //'/expenses': (context) => const ExpensesScreen(),
        '/invoices': (context) => const InvoicesScreen(),
        '/login': (context) => const LoginScreen(),
        '/expenses': (context) => const ExpenseScreen(),
        '/sales': (context) => const SaleScreen(),
      },
      initialRoute: '/',
    );
  }
}
