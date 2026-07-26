// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitlePet => '飞行雪绒';

  @override
  String get appTitleOverlay => '飞行雪绒悬浮窗';

  @override
  String get appTitleSettings => '飞行雪绒设置';

  @override
  String get sectionAemeathSize => '飞行雪绒大小';

  @override
  String get sectionRoamSpeed => '移动速度';

  @override
  String get sectionAndroidOverlay => 'Android 悬浮窗';

  @override
  String get sectionStartup => '启动项';

  @override
  String get sectionLanguage => '语言';

  @override
  String get labelSize => '大小';

  @override
  String get labelDesktop => '桌面端';

  @override
  String get labelMobile => '移动端';

  @override
  String get labelOverlaySize => '悬浮窗大小';

  @override
  String get showOverlayDebug => '显示悬浮窗调试信息';

  @override
  String get sectionInteraction => '交互';

  @override
  String get clickThrough => '点击/触摸穿透';

  @override
  String get clickThroughDescription => '让指针输入穿过宠物并传递到后方应用';

  @override
  String get launchAtStartup => '开机启动';

  @override
  String get statusOverlayPermissionNotGranted => '未授予悬浮窗权限。';

  @override
  String get statusOverlayRunning => '悬浮窗正在运行。你可以离开应用。';

  @override
  String get statusOverlayStopped => '悬浮窗已停止。';

  @override
  String get startOverlay => '启动悬浮窗';

  @override
  String get stopOverlay => '停止悬浮窗';

  @override
  String get requestPermission => '请求权限';

  @override
  String get trayShow => '显示';

  @override
  String get trayHide => '隐藏';

  @override
  String get traySettings => '设置';

  @override
  String get trayQuit => '退出';

  @override
  String get trayLaunchAtStartupOn => '开机启动: 开';

  @override
  String get trayLaunchAtStartupOff => '开机启动: 关';

  @override
  String get overlayNotificationTitle => '飞行雪绒';

  @override
  String get overlayNotificationContent => '飞行雪绒正在运行';

  @override
  String get noScreenInfo => '无屏幕信息';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageChinese => '中文';

  @override
  String pxPerSecond(int value) {
    return '$value 像素/秒';
  }
}
