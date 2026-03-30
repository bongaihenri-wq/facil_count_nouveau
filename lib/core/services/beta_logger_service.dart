import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_config.dart';

/// Logger rapide pour démarrer les tests immédiatement
class BetaLoggerService {
  static Future<void> logError(
    dynamic error,
    StackTrace? stack, {
    String? context,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    
    // Log console en debug
    if (kDebugMode) {
      debugPrint('❌ ERROR [$timestamp]: $error');
      return;
    }

    // Log vers Supabase
    try {
      await Supabase.instance.client.from('beta_logs').insert({
        'type': 'error',
        'message': error.toString(),
        'stack': stack?.toString(),
        'context': context,
        'app_version': AppConfig.version,
        'timestamp': timestamp,
      });
    } catch (e) {
      // Fallback: log local si Supabase down
      await _logLocal('ERROR: $error\nContext: $context');
    }
  }

  static Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (kDebugMode) {
      debugPrint('📊 EVENT: $eventName - $parameters');
      return;
    }

    try {
      await Supabase.instance.client.from('beta_analytics').insert({
        'event_name': eventName,
        'parameters': parameters,
        'app_version': AppConfig.version,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silencieux pour analytics
    }
  }

  static Future<void> _logLocal(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/beta_logs.txt');
      await file.writeAsString('$message\n\n', mode: FileMode.append);
    } catch (_) {}
  }
}
