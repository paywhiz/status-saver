import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/status_item.dart';

enum SaveDestination { gallery, inApp }

enum RecentViewMode { combined, separate }

/// User-tweakable preferences. Backed by SharedPreferences; loaded once at
/// startup and mutated through this controller so the UI rebuilds on change.
class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs);

  static const _kSaveDestination = 'settings.saveDestination';
  static const _kPersonalEnabled = 'settings.personalEnabled';
  static const _kBusinessEnabled = 'settings.businessEnabled';
  static const _kRecentViewMode = 'settings.recentViewMode';
  static const _kThemeMode = 'settings.themeMode';
  static const _kOnboardingCompleted = 'onboarding.completed';

  final SharedPreferences _prefs;

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController._(prefs);
  }

  // --- Save destination ---------------------------------------------------

  SaveDestination get saveDestination {
    final raw = _prefs.getString(_kSaveDestination);
    return raw == 'inApp' ? SaveDestination.inApp : SaveDestination.gallery;
  }

  Future<void> setSaveDestination(SaveDestination value) async {
    await _prefs.setString(_kSaveDestination, value.name);
    notifyListeners();
  }

  // --- Per-instance enable toggles ----------------------------------------
  // Default: both enabled. Onboarding may flip these before completion.

  bool get personalEnabled => _prefs.getBool(_kPersonalEnabled) ?? true;
  bool get businessEnabled => _prefs.getBool(_kBusinessEnabled) ?? false;

  Future<void> setPersonalEnabled(bool value) async {
    await _prefs.setBool(_kPersonalEnabled, value);
    if (!value && viewMode == RecentViewMode.separate) {
      // Falling back to a single instance — separate view no longer applies.
      await _prefs.setString(_kRecentViewMode, RecentViewMode.combined.name);
    }
    notifyListeners();
  }

  Future<void> setBusinessEnabled(bool value) async {
    await _prefs.setBool(_kBusinessEnabled, value);
    if (!value && viewMode == RecentViewMode.separate) {
      await _prefs.setString(_kRecentViewMode, RecentViewMode.combined.name);
    }
    notifyListeners();
  }

  bool isOriginEnabled(StatusOrigin origin) {
    switch (origin) {
      case StatusOrigin.whatsapp:
        return personalEnabled;
      case StatusOrigin.whatsappBusiness:
        return businessEnabled;
      case StatusOrigin.imported:
        return true;
    }
  }

  bool get bothInstancesEnabled => personalEnabled && businessEnabled;

  // --- Recent view mode ---------------------------------------------------

  RecentViewMode get viewMode {
    if (!bothInstancesEnabled) return RecentViewMode.combined;
    final raw = _prefs.getString(_kRecentViewMode);
    return raw == 'separate'
        ? RecentViewMode.separate
        : RecentViewMode.combined;
  }

  Future<void> setViewMode(RecentViewMode value) async {
    await _prefs.setString(_kRecentViewMode, value.name);
    notifyListeners();
  }

  // --- Theme --------------------------------------------------------------

  ThemeMode get themeMode {
    switch (_prefs.getString(_kThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  // --- Onboarding ---------------------------------------------------------

  bool get onboardingCompleted => _prefs.getBool(_kOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_kOnboardingCompleted, value);
    notifyListeners();
  }
}
