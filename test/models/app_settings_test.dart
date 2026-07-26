import 'package:flutter_test/flutter_test.dart';
import 'package:aemeath_pet/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('round-trips through a map', () {
      const settings = AppSettings(
        petScale: 1.25,
        desktopRoamSpeed: 140,
        mobileRoamSpeed: 210,
        androidOverlayScale: 1.5,
        showOverlayDebug: true,
        clickThrough: true,
        launchAtStartup: true,
        languageCode: 'zh',
      );

      expect(AppSettings.fromMap(settings.toMap()), settings);
      expect(settings.hashCode, AppSettings.fromMap(settings.toMap()).hashCode);
    });

    test('uses the supplied fallback for missing or invalid values', () {
      const fallback = AppSettings(
        petScale: 1.1,
        desktopRoamSpeed: 130,
        mobileRoamSpeed: 190,
        androidOverlayScale: 0.9,
        showOverlayDebug: true,
        clickThrough: false,
        launchAtStartup: true,
        languageCode: 'en',
      );

      final settings = AppSettings.fromMap(
        <String, dynamic>{
          'petScale': 2,
          'clickThrough': true,
          'mobileRoamSpeed': 'fast',
          'androidOverlayScale': -1,
          'showOverlayDebug': 1,
          'languageCode': 'unsupported',
        },
        fallback: fallback,
      );

      expect(settings.petScale, 2);
      expect(settings.clickThrough, isTrue);
      expect(settings.desktopRoamSpeed, fallback.desktopRoamSpeed);
      expect(settings.mobileRoamSpeed, fallback.mobileRoamSpeed);
      expect(settings.androidOverlayScale, fallback.androidOverlayScale);
      expect(settings.showOverlayDebug, fallback.showOverlayDebug);
      expect(settings.languageCode, fallback.languageCode);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = AppSettings.defaults.copyWith(petScale: 1.75);

      expect(updated.petScale, 1.75);
      expect(updated.desktopRoamSpeed, AppSettings.defaults.desktopRoamSpeed);
      expect(updated.languageCode, AppSettings.defaults.languageCode);
    });
  });
}
