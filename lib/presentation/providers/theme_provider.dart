import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/preferences_service.dart';

/// Theme notifier to manage app theme
class ThemeNotifier extends StateNotifier<ThemeData> {
  final PreferencesService _preferencesService;

  ThemeNotifier(this._preferencesService) : super(_getDefaultTheme()) {
    _loadTheme();
  }

  static ThemeData _getDefaultTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB71C1C), // Red default
        brightness: Brightness.light,
      ),
    );
  }

  Future<void> _loadTheme() async {
    try {
      final isDark = await _preferencesService.getDarkMode();
      state = _createTheme(isDark, const Color(0xFFB71C1C));
    } catch (e) {
      print('❌ Error loading theme: $e');
    }
  }

  ThemeData _createTheme(bool isDark, Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  Future<void> updateTheme(bool isDark, Color primaryColor) async {
    try {
      // Save to local storage only
      await _preferencesService.setDarkMode(isDark);
      // Update state immediately
      state = _createTheme(isDark, primaryColor);
      print('✅ Theme updated successfully (isDark: $isDark)');
    } catch (e) {
      print('❌ Error updating theme: $e');
      // Don't rethrow, just log the error
      // User can still use the app even if theme save fails
    }
  }

  bool get isDarkMode => state.brightness == Brightness.dark;
  Color get primaryColor => state.colorScheme.primary;
}

/// Provider for theme
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier(PreferencesService());
});
