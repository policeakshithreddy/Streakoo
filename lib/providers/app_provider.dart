import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:streakoo/models/app_settings.dart';
import 'package:streakoo/utils/constants.dart';

class AppProvider extends ChangeNotifier {
  final Box<AppSettings> _settingsBox = Hive.box<AppSettings>(
    kAppSettingsBoxName,
  );
  late AppSettings _settings;

  AppProvider() {
    _loadSettings();
  }

  // --- Appearance (not persisted yet) ---
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void _loadSettings() {
    // Try to get settings at key 0, if not, create default settings
    if (_settingsBox.isEmpty) {
      _settings = AppSettings();
      _settingsBox.put(0, _settings);
    } else {
      _settings = _settingsBox.get(0)!;
    }
    notifyListeners();
  }

  // --- Getters ---
  String get userName => _settings.userName;
  bool get hasOnboarded => _settings.hasOnboarded;
  int get challengeLength => _settings.challengeLength;
  bool get challengeCompleted => _settings.challengeCompleted;

  // --- Setters ---
  Future<void> setUserName(String name) async {
    _settings.userName = name;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setChallengeLength(int days) async {
    _settings.challengeLength = days;
    await _settings.save();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _settings.hasOnboarded = true;
    await _settings.save();
    notifyListeners();
  }

  Future<void> completeChallenge() async {
    _settings.challengeCompleted = true;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setChallengeCompleted(bool completed) async {
    _settings.challengeCompleted = completed;
    await _settings.save();
    notifyListeners();
  }
}
