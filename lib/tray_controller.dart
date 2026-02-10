import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'app_settings.dart';

class TrayController with TrayListener {
  TrayController({
    required this.controller,
    required this.onOpenSettings,
  });

  static const double _sizeSmall = 0.8;
  static const double _sizeMedium = 1.0;
  static const double _sizeLarge = 1.4;
  static const double _speedSlow = 80;
  static const double _speedNormal = 120;
  static const double _speedFast = 200;

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
      final settings = controller.value;
      final isShown = await _getWindowShown();
      final showDisabled = isShown == true;
      final hideDisabled = isShown == false;
      final isSmall = _isClose(settings.petScale, _sizeSmall);
      final isMedium = _isClose(settings.petScale, _sizeMedium);
      final isLarge = _isClose(settings.petScale, _sizeLarge);
      final isSlow = _isClose(settings.desktopRoamSpeed, _speedSlow);
      final isNormal = _isClose(settings.desktopRoamSpeed, _speedNormal);
      final isFast = _isClose(settings.desktopRoamSpeed, _speedFast);
      final menu = Menu(items: [
        MenuItem(key: 'show', label: 'Show', disabled: showDisabled),
        MenuItem(key: 'hide', label: 'Hide', disabled: hideDisabled),
        MenuItem.separator(),
        MenuItem(key: 'settings', label: 'Settings'),
        MenuItem.separator(),
      MenuItem.checkbox(
        key: 'size_small',
        label: 'Size: Small',
        checked: isSmall,
      ),
      MenuItem.checkbox(
        key: 'size_medium',
        label: 'Size: Medium',
        checked: isMedium,
      ),
      MenuItem.checkbox(
        key: 'size_large',
        label: 'Size: Large',
        checked: isLarge,
      ),
        MenuItem.separator(),
      MenuItem.checkbox(
        key: 'speed_slow',
        label: 'Speed: Slow',
        checked: isSlow,
      ),
      MenuItem.checkbox(
        key: 'speed_normal',
        label: 'Speed: Normal',
        checked: isNormal,
      ),
      MenuItem.checkbox(
        key: 'speed_fast',
        label: 'Speed: Fast',
        checked: isFast,
      ),
        MenuItem.separator(),
        MenuItem(
          key: 'autostart',
          label: settings.launchAtStartup
              ? 'Launch at startup: On'
              : 'Launch at startup: Off',
        ),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ]);
      await trayManager.setContextMenu(menu);
    } catch (_) {
      // Avoid crashing if the menu is refreshed while closing.
    }
  }

  Future<void> _setIcon() async {
    final iconPath = Platform.isWindows
        ? 'assets/ameath.ico'
        : 'assets/tray_icon.png';
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
          await _showWindow();
          onOpenSettings();
          await refresh();
          break;
        case 'size_small':
          await controller.setPetScale(_sizeSmall);
          break;
        case 'size_medium':
          await controller.setPetScale(_sizeMedium);
          break;
        case 'size_large':
          await controller.setPetScale(_sizeLarge);
          break;
        case 'speed_slow':
          await controller.setDesktopRoamSpeed(_speedSlow);
          break;
        case 'speed_normal':
          await controller.setDesktopRoamSpeed(_speedNormal);
          break;
        case 'speed_fast':
          await controller.setDesktopRoamSpeed(_speedFast);
          break;
        case 'autostart':
          await controller.setLaunchAtStartup(!controller.value.launchAtStartup);
          break;
        case 'quit':
          await WindowManagerPlus.current.close();
          break;
      }
    } catch (_) {
      // Prevent tray click exceptions from terminating the app.
    }
  }

  Future<void> _showWindow() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
    _windowShownOverride = true;
  }

  Future<void> _hideWindow() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;
    await WindowManagerPlus.current.hide();
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
      final visible = await WindowManagerPlus.current.isVisible();
      final minimized = await WindowManagerPlus.current.isMinimized();
      return visible && !minimized;
    } catch (_) {
      return null;
    }
  }

  bool _isClose(double value, double target) {
    return (value - target).abs() < 0.001;
  }
}
