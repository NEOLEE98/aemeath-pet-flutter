import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_utils.dart';
import '../models/app_settings.dart';
import '../platform/desktop_window_service.dart';
import '../services/desktop_update_notice.dart';
import '../services/update_prompt.dart';
import 'settings_page.dart';

class SettingsWindowApp extends StatefulWidget {
  const SettingsWindowApp({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SettingsWindowApp> createState() => _SettingsWindowAppState();
}

class _SettingsWindowAppState extends State<SettingsWindowApp> {
  Timer? _notifyTimer;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isShowingUpdatePrompt = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingUpdate();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSettingsChanged);
    _notifyTimer?.cancel();
    super.dispose();
  }

  Future<void> _consumePendingUpdate() async {
    if (_isShowingUpdatePrompt) {
      return;
    }
    if (!mounted) {
      return;
    }
    final result = await DesktopUpdateNoticeStore.peek();
    if (!mounted || result == null || !result.hasUpdate) {
      return;
    }
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _consumePendingUpdate();
      });
      return;
    }
    _isShowingUpdatePrompt = true;
    try {
      await showUpdateAvailableDialog(dialogContext, result);
      await DesktopUpdateNoticeStore.clear();
    } finally {
      _isShowingUpdatePrompt = false;
    }
  }

  void _onSettingsChanged() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final current = widget.controller.value;
        final payload = <String, dynamic>{
          'petScale': current.petScale,
          'desktopRoamSpeed': current.desktopRoamSpeed,
          'mobileRoamSpeed': current.mobileRoamSpeed,
          'androidOverlayScale': current.androidOverlayScale,
          'showOverlayDebug': current.showOverlayDebug,
          'launchAtStartup': current.launchAtStartup,
          'languageCode': current.languageCode,
        };
        await invokeMainWindow('applySettings', payload);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: widget.controller,
      builder: (context, settings, _) {
        final locale = effectiveAppLocale(
          languageCode: settings.languageCode,
          systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
        );
        final l10n = lookupAppLocalizations(locale);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: l10n.appTitleSettings,
          navigatorKey: _navigatorKey,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F3EF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F3EF),
              foregroundColor: Colors.black,
            ),
          ),
          home: SettingsPage(controller: widget.controller),
        );
      },
    );
  }
}
