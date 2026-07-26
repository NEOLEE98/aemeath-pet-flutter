import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:multi_window_manager/multi_window_manager.dart'
    hide screenRetriever;
import 'package:screen_retriever/screen_retriever.dart';
import 'l10n/app_localizations.dart';

import 'l10n/locale_utils.dart';
import 'models/app_settings.dart';
import 'platform/android_overlay_launcher.dart';
import 'platform/desktop_startup.dart';
import 'platform/desktop_window_service.dart';
import 'controllers/tray_controller.dart';
import 'services/desktop_update_notice.dart';
import 'services/update_checker.dart';
import 'services/update_prompt.dart';
import 'widgets/settings_page.dart';
import 'widgets/settings_window_app.dart';
import 'models/window_args.dart';

final SettingsController settingsController = SettingsController();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await settingsController.load();
  await settingsController.setupLaunchAtStartup();

  final windowId = _parseWindowId(args);
  final windowArgs = _parseWindowArgs(args, windowId);
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await initializeDesktopWindow(
      windowId: windowId,
      windowArgs: windowArgs,
      settingsController: settingsController,
    );
  }

  if (windowArgs.type == WindowArgs.typeSettings) {
    runApp(SettingsWindowApp(controller: settingsController));
  } else {
    runApp(const AemeathPetApp());
  }
}

bool isOverlayApp = false;

@pragma('vm:entry-point')
Future<void> overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  isOverlayApp = true;
  await settingsController.load();
  runApp(const AemeathOverlayApp());
}

int _parseWindowId(List<String> args) =>
    args.isEmpty ? 0 : int.tryParse(args.first) ?? 0;

WindowArgs _parseWindowArgs(List<String> args, int windowId) {
  if (windowId > 0 && args.length > 1) {
    return WindowArgs.fromJsonString(args[1]);
  }
  return WindowArgs.main;
}

class AemeathPetApp extends StatefulWidget {
  const AemeathPetApp({super.key});

  @override
  State<AemeathPetApp> createState() => _AemeathPetAppState();
}

class _AemeathPetAppState extends State<AemeathPetApp> {
  TrayController? _trayController;
  final GitHubUpdateChecker _updateChecker = GitHubUpdateChecker();

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _trayController = TrayController(
        controller: settingsController,
        onOpenSettings: _openSettings,
      );
      _trayController!.init();
      settingsController.addListener(_refreshTray);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesOnLaunch();
    });
  }

  void _refreshTray() {
    _trayController?.refresh();
  }

  @override
  void dispose() {
    settingsController.removeListener(_refreshTray);
    _trayController?.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdatesOnLaunch() async {
    final result = await _updateChecker.checkForUpdates();
    if (!mounted || result == null || !result.hasUpdate) {
      return;
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await _showDesktopUpdatePrompt(result);
      return;
    }

    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      return;
    }
    await showUpdateAvailableDialog(dialogContext, result);
  }

  Future<void> _showDesktopUpdatePrompt(UpdateCheckResult result) async {
    try {
      await DesktopUpdateNoticeStore.save(result);
      await openOrFocusSettingsWindow();
    } catch (_) {}
  }

  void _openSettings() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return;
    }
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(controller: settingsController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: settingsController,
      builder: (context, settings, _) {
        final locale = effectiveAppLocale(
          languageCode: settings.languageCode,
          systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
        );
        final l10n = lookupAppLocalizations(locale);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: l10n.appTitlePet,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: rootNavigatorKey,
          themeMode: ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
          ),
          home: Platform.isAndroid
              ? AndroidOverlayLauncher(controller: settingsController)
              : PetStage(controller: settingsController),
        );
      },
    );
  }
}

class AemeathOverlayApp extends StatelessWidget {
  const AemeathOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: settingsController,
      builder: (context, settings, _) {
        final locale = effectiveAppLocale(
          languageCode: settings.languageCode,
          systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
        );
        final l10n = lookupAppLocalizations(locale);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: l10n.appTitleOverlay,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
          ),
          home: PetStage(controller: settingsController),
        );
      },
    );
  }
}

class PetStage extends StatefulWidget {
  const PetStage({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage> {
  AppSettings get settings => widget.controller.value;
  static const int _minMoveDurationMs = 60;
  final Random _random = Random();

  final List<String> idleGifs = const [
    'assets/idle1.gif',
    'assets/idle2.gif',
    'assets/idle3.gif',
    'assets/idle4.gif',
  ];

  String currentGif = 'assets/idle1.gif';
  Timer? idleTimer;
  Timer? roamTimer;
  int _moveGeneration = 0;
  StreamSubscription<dynamic>? overlaySubscription;
  Timer? overlayPosTimer;
  Size? overlayScreenSize;
  EdgeInsets? overlayPadding;
  bool isDragging = false;
  bool isMoving = false;
  bool faceLeft = false;
  Offset? screenOrigin;
  Size? screenSize;
  AppSettings? lastSettings;
  Offset overlayPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _startIdleLoop();
    _initRoamLoop();
    _startOverlayListener();
    if (Platform.isAndroid && isOverlayApp) {
      _updateOverlayPosTimer(settings.showOverlayDebug);
    }
    lastSettings = settings;
    widget.controller.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    idleTimer?.cancel();
    roamTimer?.cancel();
    _moveGeneration += 1;
    overlaySubscription?.cancel();
    overlayPosTimer?.cancel();
    widget.controller.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _startOverlayListener() {
    if (!(Platform.isAndroid && isOverlayApp)) return;
    overlaySubscription?.cancel();
    overlaySubscription =
        FlutterOverlayWindow.overlayListener.listen((dynamic message) async {
      if (message is! Map) return;
      if (message['type'] != 'apply') return;
      final current = widget.controller.value;
      final mobileSpeed = (message['mobileRoamSpeed'] as num?)?.toDouble();
      final overlayScale = (message['androidOverlayScale'] as num?)?.toDouble();
      final showDebug = _parseBool(message['showOverlayDebug']);
      final clickThrough = _parseBool(message['clickThrough']);
      final screenWidth = (message['screenWidth'] as num?)?.toDouble();
      final screenHeight = (message['screenHeight'] as num?)?.toDouble();
      final padLeft = (message['padLeft'] as num?)?.toDouble();
      final padTop = (message['padTop'] as num?)?.toDouble();
      final padRight = (message['padRight'] as num?)?.toDouble();
      final padBottom = (message['padBottom'] as num?)?.toDouble();

      if (overlayScale != null) {
        final overlaySize = baseAndroidOverlaySize * overlayScale;
        await FlutterOverlayWindow.resizeOverlay(
          overlaySize.toInt(),
          overlaySize.toInt(),
          true,
        );
      }
      if (!mounted) return;
      if (clickThrough != null && clickThrough != current.clickThrough) {
        await FlutterOverlayWindow.updateFlag(
          clickThrough ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag,
        );
      }
      if (!mounted) return;

      final next = current.copyWith(
        mobileRoamSpeed: mobileSpeed ?? current.mobileRoamSpeed,
        androidOverlayScale: overlayScale ?? current.androidOverlayScale,
        showOverlayDebug: showDebug ?? current.showOverlayDebug,
        clickThrough: clickThrough ?? current.clickThrough,
      );
      if (screenWidth != null && screenHeight != null) {
        overlayScreenSize = Size(screenWidth, screenHeight);
      }
      if (padLeft != null &&
          padTop != null &&
          padRight != null &&
          padBottom != null) {
        overlayPadding = EdgeInsets.fromLTRB(
          padLeft,
          padTop,
          padRight,
          padBottom,
        );
      }
      if (next != current) {
        widget.controller.value = next;
      }
      await _ensureOverlayWithinBounds();
      _updateOverlayPosTimer(next.showOverlayDebug);
      if (next.showOverlayDebug) {
        setState(() {});
      }
    });
  }

  Future<void> _onSettingsChanged() async {
    final previous = lastSettings;
    final current = settings;
    if (previous == null) return;

    if ((Platform.isWindows || Platform.isMacOS) &&
        previous.petScale != current.petScale) {
      final size = Size(current.desktopWindowSize, current.desktopWindowSize);
      await MultiWindowManager.current.setSize(size);
      await MultiWindowManager.current.setMinimumSize(size);
      await MultiWindowManager.current.setMaximumSize(size);
    }

    // Android overlay size is applied from the overlay process on Apply.

    if (!mounted) return;
    setState(() {});
    lastSettings = current;
  }

  Future<void> _initRoamLoop() async {
    if (Platform.isWindows || Platform.isMacOS) {
      final display = await screenRetriever.getPrimaryDisplay();
      final size = display.visibleSize ?? display.size;
      final origin = display.visiblePosition ?? const Offset(0, 0);
      if (!mounted) return;
      setState(() {
        screenOrigin = Offset(origin.dx.toDouble(), origin.dy.toDouble());
        screenSize = Size(size.width.toDouble(), size.height.toDouble());
      });
    }

    roamTimer?.cancel();
    roamTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (isDragging || isMoving) return;
      if (Platform.isWindows || Platform.isMacOS) {
        _roamDesktop();
      } else if (Platform.isAndroid && isOverlayApp) {
        _roamAndroidOverlay();
      }
    });
  }

  void _startIdleLoop() {
    idleTimer?.cancel();
    idleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (isDragging || isMoving) return;
      if (!mounted) return;
      final next = idleGifs[_random.nextInt(idleGifs.length)];
      setState(() {
        currentGif = next;
      });
    });
  }

  void _setGif(String gif) {
    if (currentGif == gif) return;
    setState(() {
      currentGif = gif;
    });
  }

  void _onPanStart(DragStartDetails details) {
    _stopRoam(resetGif: false);
    isDragging = true;
    _setGif('assets/drag.gif');
    if (Platform.isWindows || Platform.isMacOS) {
      MultiWindowManager.current.startDragging();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (details.delta.dx.abs() > 0.1) {
      setState(() {
        faceLeft = details.delta.dx < 0;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    isDragging = false;
    _setGif('assets/idle1.gif');
  }

  void _onMoveTap() {
    if (isMoving || isDragging) return;
    if (Platform.isWindows || Platform.isMacOS) {
      _roamDesktop();
      return;
    }
    if (Platform.isAndroid && isOverlayApp) {
      _roamAndroidOverlay();
    }
  }

  Future<void> _roamDesktop() async {
    if (isDragging) return;
    final origin = screenOrigin ?? Offset.zero;
    final size = screenSize ?? const Size(1280, 720);
    final windowSize = settings.desktopWindowSize;
    final availableWidth = max(0.0, size.width - windowSize);
    final availableHeight = max(0.0, size.height - windowSize);
    final next = Offset(
      origin.dx + _random.nextDouble() * availableWidth,
      origin.dy + _random.nextDouble() * availableHeight,
    );
    final start = await MultiWindowManager.current.getPosition();

    if (!mounted || isDragging) return;
    setState(() {
      isMoving = true;
      currentGif = 'assets/move.gif';
      faceLeft = next.dx < start.dx;
    });
    await _animateWindowTo(next, speedPxPerSec: settings.desktopRoamSpeed);
    if (!mounted || isDragging) return;
    setState(() {
      isMoving = false;
      currentGif = 'assets/idle1.gif';
    });
  }

  Future<void> _animateWindowTo(
    Offset target, {
    required double speedPxPerSec,
  }) async {
    final start = await MultiWindowManager.current.getPosition();
    await _animateTo(
      start,
      target,
      speedPxPerSec: speedPxPerSec,
      move: MultiWindowManager.current.setPosition,
    );
  }

  Future<void> _roamAndroidOverlay() async {
    if (isDragging) return;
    final overlaySize = settings.androidOverlaySize;
    final screenSize = overlayScreenSize ??
        (WidgetsBinding.instance.platformDispatcher.views.first.physicalSize /
            WidgetsBinding
                .instance.platformDispatcher.views.first.devicePixelRatio);
    final usable = _getAndroidUsableArea(screenSize, overlaySize);
    var next = Offset(
      usable.left + _random.nextDouble() * usable.width,
      usable.top + _random.nextDouble() * usable.height,
    );

    final current = await FlutterOverlayWindow.getOverlayPosition();
    if (!mounted || isDragging) return;
    final start = Offset(current.x, current.y);
    setState(() {
      isMoving = true;
      currentGif = 'assets/move.gif';
      faceLeft = next.dx < start.dx;
      overlayPosition = start;
    });

    await _animateOverlayTo(start, next,
        speedPxPerSec: settings.mobileRoamSpeed);
    if (!mounted || isDragging) return;
    setState(() {
      isMoving = false;
      currentGif = 'assets/idle1.gif';
      overlayPosition = next;
    });
  }

  Rect _getAndroidUsableArea(Size screenSize, double overlaySize) {
    final padding = overlayPadding ?? EdgeInsets.zero;
    final left = padding.left;
    final top = padding.top;
    final right = padding.right;
    final bottom = padding.bottom;
    final maxWidth = max(0.0, screenSize.width - left - right - overlaySize);
    final maxHeight = max(0.0, screenSize.height - top - bottom - overlaySize);
    return Rect.fromLTWH(left, top, maxWidth, maxHeight);
  }

  Future<void> _ensureOverlayWithinBounds() async {
    if (!(Platform.isAndroid && isOverlayApp)) return;
    final overlaySize = settings.androidOverlaySize;
    final screen = overlayScreenSize ??
        (WidgetsBinding.instance.platformDispatcher.views.first.physicalSize /
            WidgetsBinding
                .instance.platformDispatcher.views.first.devicePixelRatio);
    final usable = _getAndroidUsableArea(screen, overlaySize);
    final current = await FlutterOverlayWindow.getOverlayPosition();
    final clamped = Offset(
      current.x.toDouble().clamp(usable.left, usable.left + usable.width),
      current.y.toDouble().clamp(usable.top, usable.top + usable.height),
    );
    if (clamped.dx == current.x && clamped.dy == current.y) return;
    await FlutterOverlayWindow.moveOverlay(
      OverlayPosition(clamped.dx, clamped.dy),
    );
    if (settings.showOverlayDebug && mounted) {
      setState(() {
        overlayPosition = clamped;
      });
    }
  }

  Future<void> _syncOverlayPosition() async {
    try {
      final currentPos = await FlutterOverlayWindow.getOverlayPosition();
      if (!mounted) return;
      setState(() {
        overlayPosition = Offset(currentPos.x, currentPos.y);
      });
    } catch (_) {}
  }

  void _updateOverlayPosTimer(bool enabled) {
    if (!enabled) {
      overlayPosTimer?.cancel();
      overlayPosTimer = null;
      return;
    }
    overlayPosTimer?.cancel();
    overlayPosTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _syncOverlayPosition();
    });
    _syncOverlayPosition();
  }

  bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return null;
  }

  Future<void> _animateOverlayTo(
    Offset start,
    Offset target, {
    required double speedPxPerSec,
  }) async {
    await _animateTo(
      start,
      target,
      speedPxPerSec: speedPxPerSec,
      move: (position) => FlutterOverlayWindow.moveOverlay(
        OverlayPosition(position.dx, position.dy),
      ),
      onMoved: (position) {
        if (mounted && settings.showOverlayDebug) {
          setState(() {
            overlayPosition = position;
          });
        }
      },
    );
  }

  Future<void> _animateTo(
    Offset start,
    Offset target, {
    required double speedPxPerSec,
    required Future<void> Function(Offset position) move,
    void Function(Offset position)? onMoved,
  }) async {
    final generation = ++_moveGeneration;
    final distance = (target - start).distance;
    final safeSpeed = max(1.0, speedPxPerSec);
    final durationMs =
        max(_minMoveDurationMs, (distance / safeSpeed * 1000).round());
    final duration = Duration(milliseconds: durationMs);
    const frame = Duration(milliseconds: 16);
    final steps = max(1, duration.inMilliseconds ~/ frame.inMilliseconds);

    for (var tick = 1; tick <= steps; tick += 1) {
      await Future<void>.delayed(frame);
      if (!mounted || isDragging || generation != _moveGeneration) return;
      final t = tick / steps;
      final eased = Curves.easeInOut.transform(t);
      final position = Offset(
        start.dx + (target.dx - start.dx) * eased,
        start.dy + (target.dy - start.dy) * eased,
      );
      await move(position);
      if (!mounted || generation != _moveGeneration) return;
      onMoved?.call(position);
    }
  }

  void _stopRoam({bool resetGif = true}) {
    _moveGeneration += 1;
    if (isMoving) {
      setState(() {
        isMoving = false;
        if (resetGif) {
          currentGif = 'assets/idle1.gif';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final petSize = (Platform.isAndroid && isOverlayApp)
        ? settings.androidOverlaySize
        : settings.petSize;
    final pet = GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onDoubleTap: _onMoveTap,
      child: SizedBox(
        width: petSize,
        height: petSize,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(faceLeft ? -1 : 1, 1, 1),
          child: Image.asset(
            currentGif,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(child: pet),
          if (Platform.isAndroid && isOverlayApp && settings.showOverlayDebug)
            IgnorePointer(
              child: Align(
                alignment: Alignment.topLeft,
                child: _OverlayDebugText(
                  position: overlayPosition,
                  usable: _getAndroidUsableArea(
                    overlayScreenSize ?? size,
                    settings.androidOverlaySize,
                  ),
                  screenSize: overlayScreenSize ?? size,
                  overlaySize: settings.androidOverlaySize,
                  hasScreenInfo: overlayScreenSize != null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayDebugText extends StatelessWidget {
  const _OverlayDebugText({
    required this.position,
    required this.usable,
    required this.screenSize,
    required this.overlaySize,
    required this.hasScreenInfo,
  });

  final Offset position;
  final Rect usable;
  final Size screenSize;
  final double overlaySize;
  final bool hasScreenInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          height: 1.1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'p ${position.dx.toStringAsFixed(1)},'
              '${position.dy.toStringAsFixed(1)}',
            ),
            Text(
              'u ${usable.width.toStringAsFixed(1)}x'
              '${usable.height.toStringAsFixed(1)}',
            ),
            if (!hasScreenInfo) Text(l10n.noScreenInfo),
          ],
        ),
      ),
    );
  }
}
