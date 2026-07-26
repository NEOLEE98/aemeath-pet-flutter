// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitlePet => 'Aemeath Pet';

  @override
  String get appTitleOverlay => 'Aemeath Pet Overlay';

  @override
  String get appTitleSettings => 'Aemeath Settings';

  @override
  String get sectionAemeathSize => 'Aemeath Size';

  @override
  String get sectionRoamSpeed => 'Roam Speed';

  @override
  String get sectionAndroidOverlay => 'Android Overlay';

  @override
  String get sectionStartup => 'Startup';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get labelSize => 'Size';

  @override
  String get labelDesktop => 'Desktop';

  @override
  String get labelMobile => 'Mobile';

  @override
  String get labelOverlaySize => 'Overlay Size';

  @override
  String get showOverlayDebug => 'Show overlay debug';

  @override
  String get sectionInteraction => 'Interaction';

  @override
  String get clickThrough => 'Click/tap through';

  @override
  String get clickThroughDescription =>
      'Pass pointer input through the pet to apps behind it';

  @override
  String get launchAtStartup => 'Launch at startup';

  @override
  String get statusOverlayPermissionNotGranted =>
      'Overlay permission not granted.';

  @override
  String get statusOverlayRunning => 'Overlay running. You can leave the app.';

  @override
  String get statusOverlayStopped => 'Overlay stopped.';

  @override
  String get startOverlay => 'Start Overlay';

  @override
  String get stopOverlay => 'Stop Overlay';

  @override
  String get requestPermission => 'Request Permission';

  @override
  String get trayShow => 'Show';

  @override
  String get trayHide => 'Hide';

  @override
  String get traySettings => 'Settings';

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayLaunchAtStartupOn => 'Launch at startup: On';

  @override
  String get trayLaunchAtStartupOff => 'Launch at startup: Off';

  @override
  String get overlayNotificationTitle => 'Aemeath Pet';

  @override
  String get overlayNotificationContent => 'Aemeath Pet is running';

  @override
  String get noScreenInfo => 'no screen info';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => 'Chinese';

  @override
  String pxPerSecond(int value) {
    return '$value px/s';
  }
}
