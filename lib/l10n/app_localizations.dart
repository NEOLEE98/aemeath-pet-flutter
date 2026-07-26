import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitlePet.
  ///
  /// In en, this message translates to:
  /// **'Aemeath Pet'**
  String get appTitlePet;

  /// No description provided for @appTitleOverlay.
  ///
  /// In en, this message translates to:
  /// **'Aemeath Pet Overlay'**
  String get appTitleOverlay;

  /// No description provided for @appTitleSettings.
  ///
  /// In en, this message translates to:
  /// **'Aemeath Settings'**
  String get appTitleSettings;

  /// No description provided for @sectionAemeathSize.
  ///
  /// In en, this message translates to:
  /// **'Aemeath Size'**
  String get sectionAemeathSize;

  /// No description provided for @sectionRoamSpeed.
  ///
  /// In en, this message translates to:
  /// **'Roam Speed'**
  String get sectionRoamSpeed;

  /// No description provided for @sectionAndroidOverlay.
  ///
  /// In en, this message translates to:
  /// **'Android Overlay'**
  String get sectionAndroidOverlay;

  /// No description provided for @sectionStartup.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get sectionStartup;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @labelSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get labelSize;

  /// No description provided for @labelDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get labelDesktop;

  /// No description provided for @labelMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get labelMobile;

  /// No description provided for @labelOverlaySize.
  ///
  /// In en, this message translates to:
  /// **'Overlay Size'**
  String get labelOverlaySize;

  /// No description provided for @showOverlayDebug.
  ///
  /// In en, this message translates to:
  /// **'Show overlay debug'**
  String get showOverlayDebug;

  /// No description provided for @sectionInteraction.
  ///
  /// In en, this message translates to:
  /// **'Interaction'**
  String get sectionInteraction;

  /// No description provided for @clickThrough.
  ///
  /// In en, this message translates to:
  /// **'Click/tap through'**
  String get clickThrough;

  /// No description provided for @clickThroughDescription.
  ///
  /// In en, this message translates to:
  /// **'Pass pointer input through the pet to apps behind it'**
  String get clickThroughDescription;

  /// No description provided for @launchAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Launch at startup'**
  String get launchAtStartup;

  /// No description provided for @statusOverlayPermissionNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Overlay permission not granted.'**
  String get statusOverlayPermissionNotGranted;

  /// No description provided for @statusOverlayRunning.
  ///
  /// In en, this message translates to:
  /// **'Overlay running. You can leave the app.'**
  String get statusOverlayRunning;

  /// No description provided for @statusOverlayStopped.
  ///
  /// In en, this message translates to:
  /// **'Overlay stopped.'**
  String get statusOverlayStopped;

  /// No description provided for @startOverlay.
  ///
  /// In en, this message translates to:
  /// **'Start Overlay'**
  String get startOverlay;

  /// No description provided for @stopOverlay.
  ///
  /// In en, this message translates to:
  /// **'Stop Overlay'**
  String get stopOverlay;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request Permission'**
  String get requestPermission;

  /// No description provided for @trayShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get trayShow;

  /// No description provided for @trayHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get trayHide;

  /// No description provided for @traySettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get traySettings;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @trayLaunchAtStartupOn.
  ///
  /// In en, this message translates to:
  /// **'Launch at startup: On'**
  String get trayLaunchAtStartupOn;

  /// No description provided for @trayLaunchAtStartupOff.
  ///
  /// In en, this message translates to:
  /// **'Launch at startup: Off'**
  String get trayLaunchAtStartupOff;

  /// No description provided for @overlayNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Aemeath Pet'**
  String get overlayNotificationTitle;

  /// No description provided for @overlayNotificationContent.
  ///
  /// In en, this message translates to:
  /// **'Aemeath Pet is running'**
  String get overlayNotificationContent;

  /// No description provided for @noScreenInfo.
  ///
  /// In en, this message translates to:
  /// **'no screen info'**
  String get noScreenInfo;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// No description provided for @pxPerSecond.
  ///
  /// In en, this message translates to:
  /// **'{value} px/s'**
  String pxPerSecond(int value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
