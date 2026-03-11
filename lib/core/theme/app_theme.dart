import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';
import 'package:yurt_yoklama/core/theme/app_theme_extension.dart';
import 'package:yurt_yoklama/core/theme/text_styles.dart';

class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // 🌙 DARK THEME ONLY
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,
      extensions: const <ThemeExtension<dynamic>>[AppThemeExtension.dark],

      // Renk Şeması — Material 3 Navy/Blue
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Color(0xFF001D36), // Darker navy for text on primary
        secondary: AppColors.secondary,
        onSecondary: Color(0xFF1D3140),
        tertiary: AppColors.tertiary,
        onTertiary: Color(0xFF1E313E),
        error: AppColors.error,
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerLow: AppColors.darkSurface,
      ),

      // Yazı Teması
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
      ),

      // Arka Plan
      scaffoldBackgroundColor: AppColors.darkBackground,

      // App Bar Teması
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Buton Teması (Dolu)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF381E72),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // Outlined Button Teması
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // Input (TextField) Teması
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        labelStyle: AppTextStyles.inputLabel,
        hintStyle: TextStyle(color: AppColors.darkTextSecondary.withAlpha(150)),
      ),

      // Checkbox Teması
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.darkTextSecondary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Dropdown Menü Teması
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceContainer,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            AppColors.darkSurfaceContainer,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          elevation: const WidgetStatePropertyAll(8),
        ),
      ),

      // Popup Menü Teması
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
      ),

      // Card Teması
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Dialog Teması
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // BottomSheet Teması
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
