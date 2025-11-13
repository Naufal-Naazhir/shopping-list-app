import 'package:flutter/material.dart';
import 'package:belanja_praktis/services/local_storage_service.dart';

class ThemeService {
  final LocalStorageService _localStorageService;
  final ValueNotifier<ThemeMode> _themeModeNotifier;

  ThemeService(this._localStorageService)
    : _themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system) {
    _loadInitialTheme();
  }

  ValueNotifier<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  ThemeMode get themeMode => _themeModeNotifier.value;

  Future<void> _loadInitialTheme() async {
    _themeModeNotifier.value = _localStorageService.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeModeNotifier.value != mode) {
      _themeModeNotifier.value = mode;
      await _localStorageService.saveThemeMode(mode);
    }
  }
}
