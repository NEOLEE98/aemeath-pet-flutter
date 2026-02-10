import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double basePetSize = 100.0;
const double baseAndroidOverlaySize = 50.0;

class AppSettings {
  const AppSettings({
    required this.petScale,
    required this.desktopRoamSpeed,
    required this.mobileRoamSpeed,
    required this.androidOverlayScale,
    required this.showOverlayDebug,
    required this.launchAtStartup,
  });

  final double petScale;
  final double desktopRoamSpeed;
  final double mobileRoamSpeed;
  final double androidOverlayScale;
  final bool showOverlayDebug;
  final bool launchAtStartup;

  double get petSize => basePetSize * petScale;
  double get desktopWindowSize => petSize + 40.0;
  double get androidOverlaySize => baseAndroidOverlaySize * androidOverlayScale;

  AppSettings copyWith({
    double? petScale,
    double? desktopRoamSpeed,
    double? mobileRoamSpeed,
    double? androidOverlayScale,
    bool? showOverlayDebug,
    bool? launchAtStartup,
  }) {
    return AppSettings(
      petScale: petScale ?? this.petScale,
      desktopRoamSpeed: desktopRoamSpeed ?? this.desktopRoamSpeed,
      mobileRoamSpeed: mobileRoamSpeed ?? this.mobileRoamSpeed,
      androidOverlayScale: androidOverlayScale ?? this.androidOverlayScale,
      showOverlayDebug: showOverlayDebug ?? this.showOverlayDebug,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
    );
  }

  static const defaults = AppSettings(
    petScale: 1.0,
    desktopRoamSpeed: 120.0,
    mobileRoamSpeed: 180.0,
    androidOverlayScale: 1.0,
    showOverlayDebug: false,
    launchAtStartup: false,
  );
}

class SettingsController extends ValueNotifier<AppSettings> {
  SettingsController() : super(AppSettings.defaults);

  static const _keyPetScale = 'petScale';
  static const _keyDesktopSpeed = 'desktopRoamSpeed';
  static const _keyMobileSpeed = 'mobileRoamSpeed';
  static const _keyOverlayScale = 'androidOverlayScale';
  static const _keyOverlaySizeLegacy = 'androidOverlaySize';
  static const _keyShowOverlayDebug = 'showOverlayDebug';
  static const _keyLaunchAtStartup = 'launchAtStartup';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = AppSettings(
      petScale: prefs.getDouble(_keyPetScale) ?? AppSettings.defaults.petScale,
      desktopRoamSpeed:
          prefs.getDouble(_keyDesktopSpeed) ?? AppSettings.defaults.desktopRoamSpeed,
      mobileRoamSpeed:
          prefs.getDouble(_keyMobileSpeed) ?? AppSettings.defaults.mobileRoamSpeed,
      androidOverlayScale: _loadOverlayScale(prefs),
      showOverlayDebug:
          prefs.getBool(_keyShowOverlayDebug) ??
              AppSettings.defaults.showOverlayDebug,
      launchAtStartup:
          prefs.getBool(_keyLaunchAtStartup) ?? AppSettings.defaults.launchAtStartup,
    );
  }

  double _loadOverlayScale(SharedPreferences prefs) {
    final storedScale = prefs.getDouble(_keyOverlayScale);
    if (storedScale != null) {
      return storedScale;
    }
    final legacySize = prefs.getDouble(_keyOverlaySizeLegacy);
    if (legacySize != null && legacySize > 0) {
      return legacySize / baseAndroidOverlaySize;
    }
    return AppSettings.defaults.androidOverlayScale;
  }

  Future<void> setupLaunchAtStartup() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;
    final info = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: info.appName,
      appPath: Platform.resolvedExecutable,
      packageName: info.packageName,
    );
  }

  Future<void> setPetScale(double scale) async {
    value = value.copyWith(petScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPetScale, scale);
  }

  Future<void> setDesktopRoamSpeed(double speed) async {
    value = value.copyWith(desktopRoamSpeed: speed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDesktopSpeed, speed);
  }

  Future<void> setMobileRoamSpeed(double speed) async {
    value = value.copyWith(mobileRoamSpeed: speed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMobileSpeed, speed);
  }

  Future<void> setAndroidOverlayScale(double scale) async {
    value = value.copyWith(androidOverlayScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyOverlayScale, scale);
  }

  Future<void> setShowOverlayDebug(bool enabled) async {
    value = value.copyWith(showOverlayDebug: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowOverlayDebug, enabled);
  }

  Future<void> setLaunchAtStartup(bool enabled) async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    }
    value = value.copyWith(launchAtStartup: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLaunchAtStartup, enabled);
  }
}
