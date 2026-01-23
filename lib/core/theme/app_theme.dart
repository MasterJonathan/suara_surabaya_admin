import 'package:suara_surabaya_admin/core/theme/app_colors.dart'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.surface,
      dividerTheme: const DividerThemeData(thickness: 0, color: Colors.transparent),
      textTheme: TextTheme(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.foreground,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.foreground,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surface, 
        onSurface: AppColors.foreground, 
        error: AppColors.error,
        onPrimary: AppColors.surface, 
        
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            AppColors
                .surface, 
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.foreground),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          
          color: AppColors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: AppColors.surface, 
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      dataTableTheme: DataTableThemeData(
        dataTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.foreground,
          fontSize: 14,
        ), 
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            
            return AppColors.primary.withValues(
              alpha: 0.08,
            ); 
          }
          return null;
        }),
        headingRowColor: WidgetStateProperty.all(AppColors.primary),
        headingTextStyle: GoogleFonts.plusJakartaSans(
          
          fontWeight: FontWeight.bold,
          color: AppColors.surface,
        ),
        dividerThickness: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.foreground.withValues(alpha: 0.7),
        ), 
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.foreground.withValues(alpha: 0.5),
        ), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: AppColors.foreground.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(8, 24, 12, 24),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1, 
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(
            
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.foreground),
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          color: AppColors.foreground,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: AppColors.foreground,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
