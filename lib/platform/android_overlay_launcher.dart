import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../widgets/settings_page.dart';

enum _OverlayStatus {
  permissionNotGranted,
  running,
  stopped,
}

class AndroidOverlayLauncher extends StatefulWidget {
  const AndroidOverlayLauncher({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<AndroidOverlayLauncher> createState() => _AndroidOverlayLauncherState();
}

class _AndroidOverlayLauncherState extends State<AndroidOverlayLauncher>
    with WidgetsBindingObserver {
  _OverlayStatus overlayStatus = _OverlayStatus.permissionNotGranted;
  bool overlayActive = false;
  bool hasPermission = false;
  bool _isChangingOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onSettingsChanged);
    _refreshOverlayState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // no-op: user starts overlay manually
      _refreshOverlayState();
      _shareOverlayApplyData();
    }
  }

  @override
  void didChangeMetrics() {
    _shareOverlayApplyData();
  }

  void _onSettingsChanged() {
    _shareOverlayApplyData();
  }

  Future<void> _startOverlay() async {
    if (!Platform.isAndroid || _isChangingOverlay) return;
    setState(() => _isChangingOverlay = true);
    try {
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      if (!granted) {
        await FlutterOverlayWindow.requestPermission();
      }
      final allowed = await FlutterOverlayWindow.isPermissionGranted();
      if (!mounted) return;
      if (!allowed) {
        setState(() {
          hasPermission = false;
          overlayStatus = _OverlayStatus.permissionNotGranted;
        });
        return;
      }
      hasPermission = true;

      final l10n = AppLocalizations.of(context)!;
      final mq = MediaQuery.of(context);
      await FlutterOverlayWindow.showOverlay(
        alignment: OverlayAlignment.topLeft,
        height: widget.controller.value.androidOverlaySize.toInt(),
        width: widget.controller.value.androidOverlaySize.toInt(),
        enableDrag: true,
        flag: widget.controller.value.clickThrough
            ? OverlayFlag.clickThrough
            : OverlayFlag.defaultFlag,
        overlayTitle: l10n.overlayNotificationTitle,
        overlayContent: l10n.overlayNotificationContent,
        startPosition: OverlayPosition(mq.padding.left, mq.padding.top),
      );
      overlayActive = true;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _shareOverlayApplyData();

      if (!mounted) return;
      setState(() {
        overlayStatus = _OverlayStatus.running;
      });
    } finally {
      if (mounted) {
        setState(() => _isChangingOverlay = false);
      }
    }
  }

  Future<void> _stopOverlay() async {
    if (_isChangingOverlay) return;
    setState(() => _isChangingOverlay = true);
    try {
      await FlutterOverlayWindow.closeOverlay();
      overlayActive = false;
      if (mounted) {
        setState(() {
          overlayStatus = _OverlayStatus.stopped;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingOverlay = false);
      }
    }
  }

  Future<void> _refreshOverlayState() async {
    if (!Platform.isAndroid) return;
    final allowed = await FlutterOverlayWindow.isPermissionGranted();
    final active = await FlutterOverlayWindow.isActive();
    if (!mounted) return;
    setState(() {
      hasPermission = allowed;
      overlayActive = active;
      overlayStatus = !allowed
          ? _OverlayStatus.permissionNotGranted
          : active
              ? _OverlayStatus.running
              : _OverlayStatus.stopped;
    });
  }

  Future<void> _shareOverlayApplyData() async {
    if (!Platform.isAndroid) return;
    final active = overlayActive || await FlutterOverlayWindow.isActive();
    if (!active || !mounted) return;
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final padding = EdgeInsets.fromViewPadding(
      view.padding,
      view.devicePixelRatio,
    );
    final fullWidth = size.width + padding.left + padding.right;
    final fullHeight = size.height + padding.top + padding.bottom;
    final current = widget.controller.value;
    await FlutterOverlayWindow.shareData({
      'type': 'apply',
      'mobileRoamSpeed': current.mobileRoamSpeed,
      'androidOverlayScale': current.androidOverlayScale,
      'showOverlayDebug': current.showOverlayDebug,
      'clickThrough': current.clickThrough,
      'screenWidth': fullWidth,
      'screenHeight': fullHeight,
      'padLeft': padding.left,
      'padTop': padding.top,
      'padRight': padding.right,
      'padBottom': padding.bottom,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = switch (overlayStatus) {
      _OverlayStatus.permissionNotGranted =>
        l10n.statusOverlayPermissionNotGranted,
      _OverlayStatus.running => l10n.statusOverlayRunning,
      _OverlayStatus.stopped => l10n.statusOverlayStopped,
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        title: Text(l10n.appTitlePet),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    controller: widget.controller,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasPermission
                      ? (_isChangingOverlay
                          ? null
                          : (overlayActive ? _stopOverlay : _startOverlay))
                      : (_isChangingOverlay ? null : _startOverlay),
                  child: Text(
                    hasPermission
                        ? (overlayActive ? l10n.stopOverlay : l10n.startOverlay)
                        : l10n.requestPermission,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
