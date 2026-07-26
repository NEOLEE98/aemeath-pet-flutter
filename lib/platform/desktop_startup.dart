import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_window_manager/multi_window_manager.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_utils.dart';
import '../models/app_settings.dart';
import '../models/window_args.dart';

Future<void> initializeDesktopWindow({
  required int windowId,
  required WindowArgs windowArgs,
  required SettingsController settingsController,
}) async {
  final ready = await _ensureWindowManagerReady(windowId);
  if (ready) {
    MultiWindowManager.current.addListener(
      _DesktopWindowListener(
        windowArgs: windowArgs,
        settingsController: settingsController,
      ),
    );
    if (windowArgs.type == WindowArgs.typeSettings) {
      await _configureSettingsWindow(settingsController);
    } else {
      await _configurePetWindow(settingsController);
    }
  }
}

Future<bool> _ensureWindowManagerReady(int windowId) async {
  const retries = 5;
  for (var attempt = 0; attempt < retries; attempt += 1) {
    try {
      if (windowId == 0) {
        await MultiWindowManager.ensureInitialized(windowId);
      } else {
        await MultiWindowManager.ensureInitializedSecondary(windowId);
      }
      return true;
    } on MissingPluginException {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }
  return false;
}

Future<void> _configurePetWindow(SettingsController settingsController) async {
  final windowSize = settingsController.value.desktopWindowSize;
  final windowOptions = WindowOptions(
    size: Size(windowSize, windowSize),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: true,
  );

  MultiWindowManager.current.waitUntilReadyToShow(windowOptions, () async {
    await MultiWindowManager.current.setAsFrameless();
    await MultiWindowManager.current.setResizable(false);
    await MultiWindowManager.current
        .setMinimumSize(Size(windowSize, windowSize));
    await MultiWindowManager.current
        .setMaximumSize(Size(windowSize, windowSize));
    await MultiWindowManager.current.setHasShadow(false);
    await MultiWindowManager.current.setOpacity(1);
    await MultiWindowManager.current.setVisibleOnAllWorkspaces(true);
    await MultiWindowManager.current.setAlwaysOnTop(true);
    await MultiWindowManager.current.setBackgroundColor(Colors.transparent);
    await MultiWindowManager.current.show();
    await MultiWindowManager.current.focus();
  });
}

Future<void> _configureSettingsWindow(
    SettingsController settingsController) async {
  final locale = effectiveAppLocale(
    languageCode: settingsController.value.languageCode,
    systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
  final strings = lookupAppLocalizations(locale);
  const settingsSize = Size(720, 720);
  const minSize = Size(520, 640);
  const maxSize = Size(1400, 1200);
  final windowOptions = WindowOptions(
    size: settingsSize,
    center: true,
    backgroundColor: const Color(0xFFF5F3EF),
    title: strings.appTitleSettings,
    titleBarStyle: TitleBarStyle.normal,
    skipTaskbar: false,
  );

  MultiWindowManager.current.waitUntilReadyToShow(windowOptions, () async {
    await MultiWindowManager.current.setResizable(true);
    await MultiWindowManager.current.setMinimumSize(minSize);
    await MultiWindowManager.current.setMaximumSize(maxSize);
    await MultiWindowManager.current.setHasShadow(true);
    await MultiWindowManager.current.setAlwaysOnTop(false);
    await MultiWindowManager.current.setVisibleOnAllWorkspaces(false);
    await MultiWindowManager.current.setBackgroundColor(
      const Color(0xFFF5F3EF),
    );
    await MultiWindowManager.current.show();
    await MultiWindowManager.current.focus();
  });
}

class _DesktopWindowListener with WindowListener {
  _DesktopWindowListener({
    required this.windowArgs,
    required this.settingsController,
  });

  final WindowArgs windowArgs;
  final SettingsController settingsController;

  @override
  void onWindowClose([int? windowId]) {
    if (windowArgs.type == WindowArgs.typeMain) {
      exit(0);
    }
  }

  @override
  Future<dynamic> onEventFromWindow(
    String eventName,
    int fromWindowId,
    dynamic arguments,
  ) async {
    switch (eventName) {
      case 'getWindowType':
        return windowArgs.type;
      case 'reloadSettings':
        await settingsController.load();
        return true;
      case 'applySettings':
        final args = arguments;
        if (args is Map) {
          settingsController.value = AppSettings(
            petScale: (args['petScale'] as num?)?.toDouble() ??
                settingsController.value.petScale,
            desktopRoamSpeed: (args['desktopRoamSpeed'] as num?)?.toDouble() ??
                settingsController.value.desktopRoamSpeed,
            mobileRoamSpeed: (args['mobileRoamSpeed'] as num?)?.toDouble() ??
                settingsController.value.mobileRoamSpeed,
            androidOverlayScale:
                (args['androidOverlayScale'] as num?)?.toDouble() ??
                    settingsController.value.androidOverlayScale,
            showOverlayDebug: args['showOverlayDebug'] as bool? ??
                settingsController.value.showOverlayDebug,
            launchAtStartup: args['launchAtStartup'] as bool? ??
                settingsController.value.launchAtStartup,
            languageCode: args['languageCode'] as String? ??
                settingsController.value.languageCode,
          );
          return true;
        }
        return false;
      case 'focus':
        await MultiWindowManager.current.show();
        await MultiWindowManager.current.focus();
        return true;
    }
    return null;
  }
}
