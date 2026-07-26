import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:multi_window_manager/multi_window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_utils.dart';
import '../models/app_settings.dart';
import '../platform/desktop_window_service.dart';

class TrayController with TrayListener {
  TrayController({
    required this.controller,
    required this.onOpenSettings,
  });

  final SettingsController controller;
  final VoidCallback onOpenSettings;
  bool? _windowShownOverride;

  Future<void> init() async {
    trayManager.addListener(this);
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _windowShownOverride = true;
    }
    await _setIcon();
    await refresh();
    Future.delayed(const Duration(milliseconds: 300), refresh);
  }

  Future<void> refresh() async {
    try {
      final locale = effectiveAppLocale(
        languageCode: controller.value.languageCode,
        systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
      );
      final strings = lookupAppLocalizations(locale);
      final settings = controller.value;
      final isShown = await _getWindowShown();
      final showDisabled = isShown == true;
      final hideDisabled = isShown == false;
      final menu = Menu(items: [
        MenuItem(key: 'show', label: strings.trayShow, disabled: showDisabled),
        MenuItem(key: 'hide', label: strings.trayHide, disabled: hideDisabled),
        MenuItem.separator(),
        MenuItem(key: 'settings', label: strings.traySettings),
        MenuItem.separator(),
        MenuItem(
          key: 'autostart',
          label: settings.launchAtStartup
              ? strings.trayLaunchAtStartupOn
              : strings.trayLaunchAtStartupOff,
        ),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: strings.trayQuit),
      ]);
      await trayManager.setContextMenu(menu);
    } catch (_) {
      // Avoid crashing if the menu is refreshed while closing.
    }
  }

  Future<void> _setIcon() async {
    final iconPath =
        Platform.isWindows ? 'assets/aemeath.ico' : 'assets/tray_icon.png';
    await trayManager.setIcon(iconPath);
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    try {
      final key = menuItem.key;
      if (key == null || key.isEmpty) return;
      switch (key) {
        case 'show':
          await _showWindow();
          await refresh();
          break;
        case 'hide':
          await _hideWindow();
          await refresh();
          break;
        case 'settings':
          await _openSettingsWindow();
          await refresh();
          break;
        case 'autostart':
          await controller
              .setLaunchAtStartup(!controller.value.launchAtStartup);
          break;
        case 'quit':
          await MultiWindowManager.current.close();
          break;
      }
    } catch (_) {
      // Prevent tray click exceptions from terminating the app.
    }
  }

  Future<void> _openSettingsWindow() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      onOpenSettings();
      return;
    }
    try {
      await openOrFocusSettingsWindow();
    } catch (_) {
      // Fall back to in-app settings if window creation fails.
      onOpenSettings();
    }
  }

  Future<void> _showWindow() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;
    await MultiWindowManager.current.show();
    await MultiWindowManager.current.focus();
    _windowShownOverride = true;
  }

  Future<void> _hideWindow() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;
    await MultiWindowManager.current.hide();
    _windowShownOverride = false;
  }

  Future<bool?> _getWindowShown() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return null;
    }
    if (_windowShownOverride != null) {
      return _windowShownOverride;
    }
    try {
      final visible = await MultiWindowManager.current.isVisible();
      final minimized = await MultiWindowManager.current.isMinimized();
      return visible && !minimized;
    } catch (_) {
      return null;
    }
  }
}
