import 'package:url_launcher/url_launcher.dart';
import '../constants/app_config.dart';

/// Support WhatsApp direct pour les testeurs
class WhatsAppSupportService {
  static const String _phone = AppConfig.supportWhatsApp; // +2250749635522
  
  static Future<void> openSupport({
    String? prefillMessage,
    String? screenName,
  }) async {
    final message = prefillMessage ?? _buildDefaultMessage(screenName);
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$_phone?text=$encodedMessage';
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static String _buildDefaultMessage(String? screen) {
    final buffer = StringBuffer();
    buffer.writeln('👋 Bonjour FacilCount Support,');
    buffer.writeln('');
    buffer.writeln('📱 Version: ${AppConfig.version}');
    if (screen != null) buffer.writeln('📍 Écran: $screen');
    buffer.writeln('');
    buffer.writeln('❓ Mon problème/Question:');
    buffer.writeln('...');
    return buffer.toString();
  }

  static Future<void> sendFeedback(String feedback) async {
    final message = '''
📝 RETOUR BETA - FacilCount

$feedback

---
Version: ${AppConfig.version}
''';
    await openSupport(prefillMessage: message);
  }

  static Future<void> reportBug({
    required String description,
    String? screenName,
  }) async {
    final message = '''
🐛 BUG REPORT - FacilCount

Description: $description
${screenName != null ? 'Écran: $screenName' : ''}

Version: ${AppConfig.version}
''';
    await openSupport(prefillMessage: message);
  }
}
