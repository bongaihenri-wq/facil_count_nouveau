import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
// ignore: unused_import
import 'screens/dashboard_screen.dart';
// ignore: unused_import
import 'screens/purchases_screen.dart';
// ignore: unused_import
import 'screens/sales_screen.dart';
// ignore: unused_import
import 'screens/expenses_screen.dart';
// ignore: unused_import
import 'screens/invoices_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On charge le fichier .env
  await dotenv.load(fileName: ".env");

  // On utilise les variables chargées au lieu de les écrire en dur
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(const FacilCountApp());
}

class FacilCountApp extends StatelessWidget {
  const FacilCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facil Count',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue[700]!,
          primary: Colors.blue[700],
          secondary: Colors.grey[600]!,
          background: Colors.grey[100],
          surface: Colors.white,
          error: Colors.red[700],
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 30, 136, 229),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color.fromARGB(255, 30, 136, 229),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
