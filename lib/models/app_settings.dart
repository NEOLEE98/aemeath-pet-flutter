import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
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
    required this.clickThrough,
    required this.launchAtStartup,
    required this.languageCode,
  });

  final double petScale;
  final double desktopRoamSpeed;
  final double mobileRoamSpeed;
  final double androidOverlayScale;
  final bool showOverlayDebug;
  final bool clickThrough;
  final bool launchAtStartup;
  final String languageCode;

  double get petSize => basePetSize * petScale;
  double get desktopWindowSize => petSize + 40.0;
  double get androidOverlaySize => baseAndroidOverlaySize * androidOverlayScale;

  factory AppSettings.fromMap(
    Map<dynamic, dynamic> map, {
    AppSettings fallback = defaults,
  }) {
    final languageCode = map['languageCode'];
    return AppSettings(
      petScale: _positiveDoubleOr(map['petScale'], fallback.petScale),
      desktopRoamSpeed:
          _positiveDoubleOr(map['desktopRoamSpeed'], fallback.desktopRoamSpeed),
      mobileRoamSpeed:
          _positiveDoubleOr(map['mobileRoamSpeed'], fallback.mobileRoamSpeed),
      androidOverlayScale: _positiveDoubleOr(
          map['androidOverlayScale'], fallback.androidOverlayScale),
      showOverlayDebug:
          _boolOr(map['showOverlayDebug'], fallback.showOverlayDebug),
      clickThrough: _boolOr(map['clickThrough'], fallback.clickThrough),
      launchAtStartup:
          _boolOr(map['launchAtStartup'], fallback.launchAtStartup),
      languageCode:
          languageCode == '' || languageCode == 'en' || languageCode == 'zh'
              ? languageCode as String
              : fallback.languageCode,
    );
  }

  static double _positiveDoubleOr(dynamic value, double fallback) =>
      value is num && value.isFinite && value > 0 ? value.toDouble() : fallback;

  static bool _boolOr(dynamic value, bool fallback) =>
      value is bool ? value : fallback;

  Map<String, dynamic> toMap() => {
        'petScale': petScale,
        'desktopRoamSpeed': desktopRoamSpeed,
        'mobileRoamSpeed': mobileRoamSpeed,
        'androidOverlayScale': androidOverlayScale,
        'showOverlayDebug': showOverlayDebug,
        'clickThrough': clickThrough,
        'launchAtStartup': launchAtStartup,
        'languageCode': languageCode,
      };

  AppSettings copyWith({
    double? petScale,
    double? desktopRoamSpeed,
    double? mobileRoamSpeed,
    double? androidOverlayScale,
    bool? showOverlayDebug,
    bool? clickThrough,
    bool? launchAtStartup,
    String? languageCode,
  }) {
    return AppSettings(
      petScale: petScale ?? this.petScale,
      desktopRoamSpeed: desktopRoamSpeed ?? this.desktopRoamSpeed,
      mobileRoamSpeed: mobileRoamSpeed ?? this.mobileRoamSpeed,
      androidOverlayScale: androidOverlayScale ?? this.androidOverlayScale,
      showOverlayDebug: showOverlayDebug ?? this.showOverlayDebug,
      clickThrough: clickThrough ?? this.clickThrough,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  static const defaults = AppSettings(
    petScale: 1.0,
    desktopRoamSpeed: 120.0,
    mobileRoamSpeed: 180.0,
    androidOverlayScale: 1.0,
    showOverlayDebug: false,
    clickThrough: false,
    launchAtStartup: false,
    languageCode: '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          petScale == other.petScale &&
          desktopRoamSpeed == other.desktopRoamSpeed &&
          mobileRoamSpeed == other.mobileRoamSpeed &&
          androidOverlayScale == other.androidOverlayScale &&
          showOverlayDebug == other.showOverlayDebug &&
          clickThrough == other.clickThrough &&
          launchAtStartup == other.launchAtStartup &&
          languageCode == other.languageCode;

  @override
  int get hashCode => Object.hash(
        petScale,
        desktopRoamSpeed,
        mobileRoamSpeed,
        androidOverlayScale,
        showOverlayDebug,
        clickThrough,
        launchAtStartup,
        languageCode,
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
  static const _keyClickThrough = 'clickThrough';
  static const _keyLaunchAtStartup = 'launchAtStartup';
  static const _keyLanguageCode = 'languageCode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = AppSettings(
      petScale: prefs.getDouble(_keyPetScale) ?? AppSettings.defaults.petScale,
      desktopRoamSpeed: prefs.getDouble(_keyDesktopSpeed) ??
          AppSettings.defaults.desktopRoamSpeed,
      mobileRoamSpeed: prefs.getDouble(_keyMobileSpeed) ??
          AppSettings.defaults.mobileRoamSpeed,
      androidOverlayScale: _loadOverlayScale(prefs),
      showOverlayDebug: prefs.getBool(_keyShowOverlayDebug) ??
          AppSettings.defaults.showOverlayDebug,
      clickThrough:
          prefs.getBool(_keyClickThrough) ?? AppSettings.defaults.clickThrough,
      launchAtStartup: prefs.getBool(_keyLaunchAtStartup) ??
          AppSettings.defaults.launchAtStartup,
      languageCode: _loadLanguageCode(prefs),
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

  String _loadLanguageCode(SharedPreferences prefs) {
    final code = prefs.getString(_keyLanguageCode);
    if (code == 'en' || code == 'zh') return code!;
    return '';
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
    await FlutterOverlayWindow.shareData(
        {'type': 'apply', 'mobileRoamSpeed': speed});
  }

  Future<void> setAndroidOverlayScale(double scale) async {
    value = value.copyWith(androidOverlayScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyOverlayScale, scale);
    await FlutterOverlayWindow.shareData(
        {'type': 'apply', 'androidOverlayScale': scale});
  }

  Future<void> setShowOverlayDebug(bool enabled) async {
    value = value.copyWith(showOverlayDebug: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowOverlayDebug, enabled);
  }

  Future<void> setClickThrough(bool enabled) async {
    value = value.copyWith(clickThrough: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyClickThrough, enabled);
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

  Future<void> setLanguageCode(String code) async {
    value = value.copyWith(languageCode: code);
    final prefs = await SharedPreferences.getInstance();
    if (code.isEmpty) {
      await prefs.remove(_keyLanguageCode);
    } else {
      await prefs.setString(_keyLanguageCode, code);
    }
  }
}
