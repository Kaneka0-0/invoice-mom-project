import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────

class AppColors {
  // Greens — primary palette
  static const forest   = Color(0xFF1B4D3E);   // primary action color
  static const forestDk = Color(0xFF0D2B22);   // dark variant
  static const medium   = Color(0xFF2D7A5B);   // secondary / hover
  static const sage     = Color(0xFF52B788);   // lighter accent
  static const pale     = Color(0xFFD8F3DC);   // containers / chips
  static const mint     = Color(0xFFF0FAF4);   // page background tint

  // Neutrals
  static const ink      = Color(0xFF0D1F17);   // primary text
  static const slate    = Color(0xFF4A6A58);   // secondary text
  static const muted    = Color(0xFF8CA89A);   // placeholder / hint
  static const border   = Color(0xFFD6EAE0);   // card / input borders
  static const surface  = Color(0xFFFFFFFF);   // card surface
  static const canvas   = Color(0xFFF4FAF6);   // page background

  // Semantic
  static const success  = Color(0xFF22A854);
  static const warning  = Color(0xFFF59E0B);
  static const danger   = Color(0xFFEF4444);
  static const neutral  = Color(0xFF9CA3AF);
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary:            AppColors.forest,
      onPrimary:          Colors.white,
      primaryContainer:   AppColors.pale,
      onPrimaryContainer: AppColors.forestDk,
      secondary:          AppColors.sage,
      onSecondary:        Colors.white,
      secondaryContainer: const Color(0xFFE9F7EF),
      onSecondaryContainer: AppColors.forest,
      surface:            AppColors.surface,
      onSurface:          AppColors.ink,
      surfaceContainerHighest: AppColors.canvas,
      outline:            AppColors.border,
      error:              AppColors.danger,
      onError:            Colors.white,
    );

    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  AppColors.forest,
        foregroundColor:  Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Cards ─────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Navigation Rail ───────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:   AppColors.surface,
        selectedIconTheme: const IconThemeData(color: AppColors.forest, size: 22),
        unselectedIconTheme: IconThemeData(color: AppColors.muted, size: 22),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: AppColors.forest,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: AppColors.muted,
          fontSize: 12,
        ),
        indicatorColor: AppColors.pale,
        minWidth: 64,
      ),

      // ── Navigation Bar (mobile) ───────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor:  AppColors.pale,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: selected ? AppColors.forest : AppColors.muted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.forest : AppColors.muted,
            size: 22,
          );
        }),
      ),

      // ── Buttons ───────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:   AppColors.forest,
          foregroundColor:   Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.forest, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // ── Input ─────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.slate, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
        prefixIconColor: AppColors.muted,
      ),

      // ── Chips ─────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:     AppColors.canvas,
        selectedColor:       AppColors.pale,
        checkmarkColor:      AppColors.forest,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Divider ───────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── FAB ──────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Tab bar ───────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:         AppColors.forest,
        unselectedLabelColor: AppColors.muted,
        indicatorColor:     AppColors.forest,
        indicatorSize:      TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

// ─── Text helpers ──────────────────────────────────────────────────────────────

TextStyle khmerStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.normal,
  Color color = AppColors.ink,
}) =>
    GoogleFonts.battambang(
        fontSize: fontSize, fontWeight: fontWeight, color: color);

// ─── Status helpers ───────────────────────────────────────────────────────────

Color statusColor(String status) => switch (status) {
      'paid'                => AppColors.success,
      'delivered'           => AppColors.success,
      'partial'             => AppColors.forest,
      'confirmed'           => AppColors.forest,
      'partially_delivered' => AppColors.forest,
      'loading'             => AppColors.forest,
      'on_route'            => AppColors.forest,
      'unpaid'              => AppColors.warning,
      'pending'             => AppColors.warning,
      'planned'             => AppColors.neutral,
      'draft'               => AppColors.neutral,
      'cancelled'           => AppColors.danger,
      _                     => AppColors.neutral,
    };

Color statusBg(String status) => switch (status) {
      'paid'                => const Color(0xFFECFDF5),
      'delivered'           => const Color(0xFFECFDF5),
      'partial'             => const Color(0xFFD8F3DC),
      'confirmed'           => const Color(0xFFD8F3DC),
      'partially_delivered' => const Color(0xFFD8F3DC),
      'loading'             => const Color(0xFFD8F3DC),
      'on_route'            => const Color(0xFFD8F3DC),
      'unpaid'              => const Color(0xFFFFFBEB),
      'pending'             => const Color(0xFFFFFBEB),
      'cancelled'           => const Color(0xFFFEE2E2),
      _                     => const Color(0xFFF3F4F6),
    };
