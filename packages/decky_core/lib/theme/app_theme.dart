import 'package:flutter/material.dart';

class AppTheme {
  static const Color ivory = Color(0xFFFAFAFA);
  static const Color charcoalBlack = Color(0xFF1C1C1C);
  static const Color obsidianBlack = Color(0xFF212529);
  static const Color silverGray = Color(0xFFDADADA);
  
  static const Color plainsGold = Color(0xFFF5E6A1);
  static const Color islandBlue = Color(0xFF71C7EC);
  static const Color swampViolet = Color(0xFF5E548E);
  static const Color mountainRed = Color(0xFFE63946);
  static const Color forestGreen = Color(0xFF588157);
  
  static const Color plainsGoldNeon = Color(0xFFFFEFB0);
  static const Color islandBlueNeon = Color(0xFF8DD4FF);
  static const Color swampVioletNeon = Color(0xFF8B7DC6);
  static const Color mountainRedNeon = Color(0xFFFF5757);
  static const Color forestGreenNeon = Color(0xFF7FA877);

  static ThemeData lightTheme({Color? accentColor}) {
    final accent = accentColor ?? plainsGold;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ivory,
      colorScheme: ColorScheme.light(
        primary: obsidianBlack,
        onPrimary: ivory,
        secondary: accent,
        onSecondary: obsidianBlack,
        surface: Colors.white,
        onSurface: obsidianBlack,
        surfaceContainer: ivory,
        error: mountainRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ivory,
        foregroundColor: obsidianBlack,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: obsidianBlack,
          foregroundColor: ivory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: obsidianBlack.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: obsidianBlack.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accent.withOpacity(0.1),
        labelStyle: TextStyle(color: obsidianBlack),
        side: BorderSide(color: accent),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ivory,
        selectedIconTheme: IconThemeData(color: accent),
        selectedLabelTextStyle: TextStyle(color: obsidianBlack),
        unselectedIconTheme: IconThemeData(color: obsidianBlack.withOpacity(0.6)),
        unselectedLabelTextStyle: TextStyle(color: obsidianBlack.withOpacity(0.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ivory,
        indicatorColor: accent.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: obsidianBlack);
          }
          return IconThemeData(color: obsidianBlack.withOpacity(0.6));
        }),
      ),
    );
  }

  static ThemeData darkTheme({Color? accentColor}) {
    final accent = accentColor != null 
        ? _getNeonVersion(accentColor) 
        : plainsGoldNeon;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: charcoalBlack,
      colorScheme: ColorScheme.dark(
        primary: silverGray,
        onPrimary: charcoalBlack,
        secondary: accent,
        onSecondary: charcoalBlack,
        surface: const Color(0xFF2A2A2A),
        onSurface: silverGray,
        surfaceContainer: charcoalBlack,
        error: mountainRedNeon,
        onError: charcoalBlack,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: charcoalBlack,
        foregroundColor: silverGray,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: const Color(0xFF2A2A2A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: silverGray,
          foregroundColor: charcoalBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: silverGray.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: silverGray.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accent.withOpacity(0.15),
        labelStyle: TextStyle(color: silverGray),
        side: BorderSide(color: accent),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: charcoalBlack,
        selectedIconTheme: IconThemeData(color: accent),
        selectedLabelTextStyle: TextStyle(color: silverGray),
        unselectedIconTheme: IconThemeData(color: silverGray.withOpacity(0.6)),
        unselectedLabelTextStyle: TextStyle(color: silverGray.withOpacity(0.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: charcoalBlack,
        indicatorColor: accent.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: silverGray);
          }
          return IconThemeData(color: silverGray.withOpacity(0.6));
        }),
      ),
    );
  }

  static Color _getNeonVersion(Color color) {
    if (color == plainsGold) return plainsGoldNeon;
    if (color == islandBlue) return islandBlueNeon;
    if (color == swampViolet) return swampVioletNeon;
    if (color == mountainRed) return mountainRedNeon;
    if (color == forestGreen) return forestGreenNeon;
    return color;
  }

  static Map<String, Color> get manaColors => {
    'Plains': plainsGold,
    'Island': islandBlue,
    'Swamp': swampViolet,
    'Mountain': mountainRed,
    'Forest': forestGreen,
  };
}