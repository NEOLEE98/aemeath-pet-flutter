import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'app_settings.dart';
import 'window_args.dart';

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
      final settings = controller.value;
      final isShown = await _getWindowShown();
      final showDisabled = isShown == true;
      final hideDisabled = isShown == false;
      final menu = Menu(items: [
        MenuItem(key: 'show', label: 'Show', disabled: showDisabled),
        MenuItem(key: 'hide', label: 'Hide', disabled: hideDisabled),
        MenuItem.separator(),
        MenuItem(key: 'settings', label: 'Settings'),
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
        ? 'assets/aemeath.ico'
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
          await _openSettingsWindow();
          await refresh();
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

  Future<void> _openSettingsWindow() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      onOpenSettings();
      return;
    }
    try {
      final controllers = await WindowController.getAll();
      for (final controller in controllers) {
        final args = WindowArgs.fromJsonString(controller.arguments);
        if (args.type == WindowArgs.typeSettings) {
          await controller.show();
          await controller.invokeMethod('focus');
          return;
        }
      }
      final controller = await WindowController.create(
        WindowConfiguration(
          arguments: WindowArgs.settings.toJsonString(),
          hiddenAtLaunch: true,
        ),
      );
      await controller.show();
      await controller.invokeMethod('focus');
    } catch (_) {
      // Fall back to in-app settings if window creation fails.
      onOpenSettings();
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
