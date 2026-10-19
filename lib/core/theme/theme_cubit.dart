import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's light / dark / system theme choice.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_read(_prefs));

  static const _key = 'theme_mode';
  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) =>
      ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_key),
        orElse: () => ThemeMode.system,
      );

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_key, mode.name);
  }
}
