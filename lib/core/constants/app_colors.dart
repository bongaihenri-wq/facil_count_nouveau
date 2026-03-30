import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // COULEURS PRINCIPALES - Identité FacilCount
  // ==========================================
  
  /// Bleu profond - Couleur principale de l'app (header, boutons principaux)
  static const Color primary = Color(0xFF1E3A8A);           // blue-900
  
  /// Bleu moyen - Variante interactive (hover, focus)
  static const Color primaryMedium = Color(0xFF3B82F6);     // blue-500
  
  /// Bleu clair - Fonds, badges, indicateurs
  static const Color primaryLight = Color(0xFF93C5FD);      // blue-300
  
  /// Vert émeraude - Accent secondaire (succès, validation, ventes)
  static const Color accent = Color(0xFF10B981);            // emerald-500
  
  /// Vert clair - Fonds de confirmation
  static const Color accentLight = Color(0xFF6EE7B7);       // emerald-300

  // ==========================================
  // AUTHENTIFICATION - Login & Register
  // ==========================================
  
  /// Dégradé login - Couleur de départ (coin haut-gauche)
  static const Color loginGradientStart = Color(0xFF1E3A8A);  // bleu foncé
  
  /// Dégradé login - Couleur intermédiaire
  static const Color loginGradientMiddle = Color(0xFF3B82F6); // bleu moyen
  
  /// Dégradé login - Couleur finale (coin bas-droit)
  static const Color loginGradientEnd = Color(0xFF10B981);    // vert émeraude
  
  /// Fond des cartes sur dégradé (login/register)
  static const Color authCardBackground = Colors.white;
  
  /// Ombre des cartes d'authentification
  static const Color authShadow = Color(0x40000000);  // noir 25% opacité

  // ==========================================
  // RÔLES UTILISATEURS
  // ==========================================
  
  /// Admin - Orange (autorité, mise en garde)
  static const Color adminPrimary = Color(0xFFF59E0B);      // amber-500
  static const Color adminLight = Color(0xFFFEF3C7);        // amber-100
  static const Color adminDark = Color(0xFFB45309);         // amber-700
  
  /// Utilisateur standard - Bleu (standard, neutre)
  static const Color userPrimary = Color(0xFF3B82F6);       // blue-500
  static const Color userLight = Color(0xFFDBEAFE);         // blue-100
  static const Color userDark = Color(0xFF1E40AF);          // blue-800

  // ==========================================
  // MÉTIERS - Vos couleurs existantes conservées
  // ==========================================
  
  // Ventes (vert)
  static const Color salesPrimary = Color(0xFF2E7D32);      // vert foncé
  static const Color salesAccent = Color(0xFF4CAF50);       // vert moyen
  static const Color salesLight = Color(0xFFC8E6C9);        // vert très clair

  // Achats (bleu)
  static const Color purchasesPrimary = Color(0xFF1565C0);  // bleu foncé
  static const Color purchasesAccent = Color(0xFF2196F3);   // bleu moyen
  static const Color purchasesLight = Color(0xFFBBDEFB);    // bleu clair

  // Dépenses (orange/rouge)
  static const Color expensesPrimary = Color(0xFFEF6C00);   // orange foncé
  static const Color expensesAccent = Color(0xFFFF9800);    // orange moyen
  static const Color expensesLight = Color(0xFFFFE0B2);     // orange clair

  // ==========================================
  // ÉTATS & FEEDBACK
  // ==========================================
  
  static const Color success = Color(0xFF22C55E);           // green-500
  static const Color error = Color(0xFFEF4444);             // red-500
  static const Color warning = Color(0xFFF59E0B);           // amber-500
  static const Color info = Color(0xFF3B82F6);              // blue-500
  static const Color neutral = Color(0xFF6B7280);           // gray-500

  // ==========================================
  // VERROUILLAGE (système de lock)
  // ==========================================
  
  /// Item verrouillé - Rouge doux
  static const Color locked = Color(0xFFEF4444);            // red-500
  static const Color lockedLight = Color(0xFFFEE2E2);       // red-100
  static const Color lockedBackground = Color(0xFFFEF2F2);  // red-50
  
  /// Déverrouillage - Vert de confirmation
  static const Color unlocked = Color(0xFF10B981);          // emerald-500
  static const Color unlockAction = Color(0xFF059669);      // emerald-600

  // ==========================================
  // INTERFACE GÉNÉRALE
  // ==========================================
  
  /// Fond de l'application
  static const Color background = Color(0xFFF8FAFC);        // slate-50
  
  /// Surface des cartes (blanc pur)
  static const Color surface = Colors.white;
  
  /// Bordures et séparateurs
  static const Color border = Color(0xFFE2E8F0);            // slate-200
  static const Color divider = Color(0xFFE2E8F0);           // slate-200

  // Texte
  static const Color textPrimary = Color(0xFF1E293B);       // slate-800
  static const Color textSecondary = Color(0xFF64748B);     // slate-500
  static const Color textMuted = Color(0xFF94A3B8);         // slate-400

  // ==========================================
  // GRIS (conservés pour compatibilité)
  // ==========================================
  
  static const Color greyLight = Color(0xFFE0E0E0);         // gray-300
  static const Color greyMedium = Color(0xFF9E9E9E);        // gray-500
  static const Color greyDark = Color(0xFF424242);          // gray-800

  // ==========================================
  // ACTIONS SPÉCIFIQUES (conservés)
  // ==========================================
  
  static const Color lockYellow = Color(0xFFFFCA28);        // amber-400
  static const Color editBlue = Color(0xFF1976D2);          // blue-700
  static const Color deleteRed = Color(0xFFD32F2F);         // red-700

  // ==========================================
  // DÉGRADÉS PRÉDÉFINIS
  // ==========================================
  
  /// Dégradé principal login/register
  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      loginGradientStart,
      loginGradientMiddle,
      loginGradientEnd,
    ],
  );

  /// Dégradé bouton principal
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      primary,
      accent,
    ],
  );
}
