import 'package:flutter/material.dart';

class ThemeController {
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  void updateThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }
}
