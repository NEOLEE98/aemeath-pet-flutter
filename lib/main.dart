import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'app_settings.dart';
import 'settings_page.dart';
import 'tray_controller.dart';
import 'window_args.dart';

final SettingsController settingsController = SettingsController();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await settingsController.load();
  await settingsController.setupLaunchAtStartup();

  WindowArgs windowArgs = WindowArgs.main;
  WindowController? windowController;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    windowController = await WindowController.fromCurrentEngine();
    windowArgs = WindowArgs.fromJsonString(windowController.arguments);
    final windowId = int.tryParse(windowController.windowId) ?? 0;
    await WindowManagerPlus.ensureInitialized(windowId);
    if (windowArgs.type == WindowArgs.typeSettings) {
      await _configureSettingsWindow();
      await _registerSettingsWindowHandlers(windowController);
    } else {
      await _configurePetWindow();
      await _registerMainWindowHandlers(windowController);
    }
  }

  if (windowArgs.type == WindowArgs.typeSettings) {
    runApp(const SettingsWindowApp());
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

Future<void> _configurePetWindow() async {
  final windowSize = settingsController.value.desktopWindowSize;
  final windowOptions = WindowOptions(
    size: Size(windowSize, windowSize),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: true,
  );

  WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.setAsFrameless();
    await WindowManagerPlus.current.setResizable(false);
    await WindowManagerPlus.current
        .setMinimumSize(Size(windowSize, windowSize));
    await WindowManagerPlus.current
        .setMaximumSize(Size(windowSize, windowSize));
    await WindowManagerPlus.current.setHasShadow(false);
    await WindowManagerPlus.current.setOpacity(1);
    await WindowManagerPlus.current.setVisibleOnAllWorkspaces(true);
    await WindowManagerPlus.current.setAlwaysOnTop(true);
    await WindowManagerPlus.current.setBackgroundColor(Colors.transparent);
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });
}

Future<void> _configureSettingsWindow() async {
  const settingsSize = Size(720, 720);
  const minSize = Size(520, 640);
  const maxSize = Size(1400, 1200);
  final windowOptions = WindowOptions(
    size: settingsSize,
    center: true,
    backgroundColor: const Color(0xFFF5F3EF),
    title: 'Aemeath Settings',
    titleBarStyle: TitleBarStyle.normal,
    skipTaskbar: false,
  );

  WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.setResizable(true);
    await WindowManagerPlus.current.setMinimumSize(minSize);
    await WindowManagerPlus.current.setMaximumSize(maxSize);
    await WindowManagerPlus.current.setHasShadow(true);
    await WindowManagerPlus.current.setAlwaysOnTop(false);
    await WindowManagerPlus.current.setVisibleOnAllWorkspaces(false);
    await WindowManagerPlus.current.setBackgroundColor(
      const Color(0xFFF5F3EF),
    );
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });
}

Future<void> _registerMainWindowHandlers(
  WindowController windowController,
) async {
  await windowController.setWindowMethodHandler((call) async {
    switch (call.method) {
      case 'reloadSettings':
        await settingsController.load();
        return true;
      case 'applySettings':
        final args = call.arguments;
        if (args is Map) {
          settingsController.value = AppSettings(
            petScale: (args['petScale'] as num?)?.toDouble() ??
                settingsController.value.petScale,
            desktopRoamSpeed:
                (args['desktopRoamSpeed'] as num?)?.toDouble() ??
                    settingsController.value.desktopRoamSpeed,
            mobileRoamSpeed:
                (args['mobileRoamSpeed'] as num?)?.toDouble() ??
                    settingsController.value.mobileRoamSpeed,
            androidOverlayScale:
                (args['androidOverlayScale'] as num?)?.toDouble() ??
                    settingsController.value.androidOverlayScale,
            showOverlayDebug: args['showOverlayDebug'] as bool? ??
                settingsController.value.showOverlayDebug,
            launchAtStartup: args['launchAtStartup'] as bool? ??
                settingsController.value.launchAtStartup,
          );
          return true;
        }
        return false;
      case 'focus':
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
        return true;
    }
    return null;
  });
}

Future<void> _registerSettingsWindowHandlers(
  WindowController windowController,
) async {
  await windowController.setWindowMethodHandler((call) async {
    switch (call.method) {
      case 'focus':
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
        return true;
    }
    return null;
  });
}

class SettingsWindowApp extends StatefulWidget {
  const SettingsWindowApp({super.key});

  @override
  State<SettingsWindowApp> createState() => _SettingsWindowAppState();
}

class _SettingsWindowAppState extends State<SettingsWindowApp> {
  Timer? _notifyTimer;

  @override
  void initState() {
    super.initState();
    settingsController.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    settingsController.removeListener(_onSettingsChanged);
    _notifyTimer?.cancel();
    super.dispose();
  }

  void _onSettingsChanged() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final current = settingsController.value;
        final payload = <String, dynamic>{
          'petScale': current.petScale,
          'desktopRoamSpeed': current.desktopRoamSpeed,
          'mobileRoamSpeed': current.mobileRoamSpeed,
          'androidOverlayScale': current.androidOverlayScale,
          'showOverlayDebug': current.showOverlayDebug,
          'launchAtStartup': current.launchAtStartup,
        };
        final controllers = await WindowController.getAll();
        for (final controller in controllers) {
          final args = WindowArgs.fromJsonString(controller.arguments);
          if (args.type == WindowArgs.typeMain) {
            await controller.invokeMethod('applySettings', payload);
            break;
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aemeath Settings',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F3EF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F3EF),
          foregroundColor: Colors.black,
        ),
      ),
      home: SettingsPage(controller: settingsController),
    );
  }
}

class AemeathPetApp extends StatefulWidget {
  const AemeathPetApp({super.key});

  @override
  State<AemeathPetApp> createState() => _AemeathPetAppState();
}

class _AemeathPetAppState extends State<AemeathPetApp> {
  TrayController? trayController;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      trayController = TrayController(
        controller: settingsController,
        onOpenSettings: _openSettings,
      );
      trayController!.init();
      settingsController.addListener(() {
        trayController?.refresh();
      });
    }
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aemeath Pet',
      navigatorKey: rootNavigatorKey,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E23)),
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      home: Platform.isAndroid
          ? AndroidOverlayLauncher(controller: settingsController)
          : PetStage(controller: settingsController),
    );
  }
}

class AemeathOverlayApp extends StatelessWidget {
  const AemeathOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aemeath Pet Overlay',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      home: PetStage(controller: settingsController),
    );
  }
}

class AndroidOverlayLauncher extends StatefulWidget {
  const AndroidOverlayLauncher({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<AndroidOverlayLauncher> createState() => _AndroidOverlayLauncherState();
}

class _AndroidOverlayLauncherState extends State<AndroidOverlayLauncher>
    with WidgetsBindingObserver {
  String status = 'Overlay permission not granted.';
  bool overlayActive = false;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOverlayState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // no-op: user starts overlay manually
      _refreshOverlayState();
    }
  }

  Future<void> _startOverlay() async {
    if (!Platform.isAndroid) return;
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      await FlutterOverlayWindow.requestPermission();
    }
    final allowed = await FlutterOverlayWindow.isPermissionGranted();
    if (!allowed) {
      setState(() {
        hasPermission = false;
        status = 'Overlay permission not granted.';
      });
      return;
    }
    hasPermission = true;

    final mq = MediaQuery.of(context);
    await FlutterOverlayWindow.showOverlay(
      alignment: OverlayAlignment.topLeft,
      height: widget.controller.value.androidOverlaySize.toInt(),
      width: widget.controller.value.androidOverlaySize.toInt(),
      enableDrag: true,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'Aemeath Pet',
      overlayContent: 'Aemeath Pet is running',
      startPosition: OverlayPosition(mq.padding.left, mq.padding.top),
    );
    overlayActive = true;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final fullWidth =
        mq.size.width + mq.padding.left + mq.padding.right;
    final fullHeight =
        mq.size.height + mq.padding.top + mq.padding.bottom;
    final current = widget.controller.value;
    await FlutterOverlayWindow.shareData({
      'type': 'apply',
      'petScale': current.petScale,
      'mobileRoamSpeed': current.mobileRoamSpeed,
      'androidOverlayScale': current.androidOverlayScale,
      'showOverlayDebug': current.showOverlayDebug,
      'screenWidth': fullWidth,
      'screenHeight': fullHeight,
      'padLeft': mq.padding.left,
      'padTop': mq.padding.top,
      'padRight': mq.padding.right,
      'padBottom': mq.padding.bottom,
    });

    setState(() {
      status = 'Overlay running. You can leave the app.';
    });
  }

  Future<void> _stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    overlayActive = false;
    if (mounted) {
      setState(() {
        status = 'Overlay stopped.';
      });
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
      status = !allowed
          ? 'Overlay permission not granted.'
          : active
              ? 'Overlay running. You can leave the app.'
              : 'Overlay stopped.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        title: const Text('Aemeath Pet'),
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
                      ? (overlayActive ? _stopOverlay : _startOverlay)
                      : _startOverlay,
                  child: Text(
                    hasPermission
                        ? (overlayActive ? 'Stop Overlay' : 'Start Overlay')
                        : 'Request Permission',
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

class PetStage extends StatefulWidget {
  const PetStage({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage> {
  AppSettings get settings => widget.controller.value;
  static const int _minMoveDurationMs = 60;

  final List<String> idleGifs = const [
    'assets/idle1.gif',
    'assets/idle2.gif',
    'assets/idle3.gif',
    'assets/idle4.gif',
  ];

  String currentGif = 'assets/idle1.gif';
  Offset position = const Offset(120, 220);
  Timer? idleTimer;
  Timer? roamTimer;
  StreamSubscription<dynamic>? overlaySubscription;
  Timer? overlayPosTimer;
  Size? overlayScreenSize;
  EdgeInsets? overlayPadding;
  bool isDragging = false;
  bool isMoving = false;
  bool faceLeft = false;
  Offset? screenOrigin;
  Size? screenSize;
  Size? stageSize;
  EdgeInsets? stagePadding;
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
      final petScale = (message['petScale'] as num?)?.toDouble();
      final mobileSpeed = (message['mobileRoamSpeed'] as num?)?.toDouble();
      final overlayScale = (message['androidOverlayScale'] as num?)?.toDouble();
      final showDebug = _parseBool(message['showOverlayDebug']);
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

      final next = current.copyWith(
        petScale: petScale ?? current.petScale,
        mobileRoamSpeed: mobileSpeed ?? current.mobileRoamSpeed,
        androidOverlayScale: overlayScale ?? current.androidOverlayScale,
        showOverlayDebug: showDebug ?? current.showOverlayDebug,
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
      await WindowManagerPlus.current.setSize(size);
      await WindowManagerPlus.current.setMinimumSize(size);
      await WindowManagerPlus.current.setMaximumSize(size);
    }

    // Android overlay size is applied from the overlay process on Apply.

    setState(() {});
    lastSettings = current;
  }

  Future<void> _initRoamLoop() async {
    if (Platform.isWindows || Platform.isMacOS) {
      final display = await screenRetriever.getPrimaryDisplay();
      final size = display.visibleSize ?? display.size;
      final origin = display.visiblePosition ?? const Offset(0, 0);
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
      } else {
        _roamMobile();
      }
    });
  }

  void _startIdleLoop() {
    idleTimer?.cancel();
    idleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (isDragging || isMoving) return;
      final next = idleGifs[Random().nextInt(idleGifs.length)];
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
    isDragging = true;
    _setGif('assets/drag.gif');
    if (Platform.isWindows || Platform.isMacOS) {
      WindowManagerPlus.current.startDragging();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (Platform.isWindows || Platform.isMacOS) return;
    if (Platform.isAndroid && isOverlayApp) return;
    setState(() {
      if (details.delta.dx.abs() > 0.1) {
        faceLeft = details.delta.dx < 0;
      }
      position += details.delta;
    });
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
    _roamMobile();
  }

  Future<void> _roamDesktop() async {
    final origin = screenOrigin ?? Offset.zero;
    final size = screenSize ?? const Size(1280, 720);
    final windowSize = settings.desktopWindowSize;
    final next = Offset(
      origin.dx + Random().nextDouble() * (size.width - windowSize),
      origin.dy + Random().nextDouble() * (size.height - windowSize),
    );
    final start = await WindowManagerPlus.current.getPosition();

    setState(() {
      isMoving = true;
      currentGif = 'assets/move.gif';
      faceLeft = next.dx < start.dx;
    });
    await _animateWindowTo(next, speedPxPerSec: settings.desktopRoamSpeed);
    setState(() {
      isMoving = false;
      currentGif = 'assets/idle1.gif';
    });
  }

  Future<void> _animateWindowTo(
    Offset target, {
    required double speedPxPerSec,
  }) async {
    final start = await WindowManagerPlus.current.getPosition();
    final distance = (target - start).distance;
    final durationMs =
        max(_minMoveDurationMs, (distance / speedPxPerSec * 1000).round());
    final duration = Duration(milliseconds: durationMs);
    const frame = Duration(milliseconds: 16);
    final steps = max(1, duration.inMilliseconds ~/ frame.inMilliseconds);
    var tick = 0;

    final completer = Completer<void>();
    Timer.periodic(frame, (timer) async {
      tick += 1;
      final t = tick / steps;
      if (t >= 1) {
        timer.cancel();
        await WindowManagerPlus.current.setPosition(target);
        completer.complete();
        return;
      }
      final eased = Curves.easeInOut.transform(t);
      final lerp = Offset(
        start.dx + (target.dx - start.dx) * eased,
        start.dy + (target.dy - start.dy) * eased,
      );
      await WindowManagerPlus.current.setPosition(lerp);
    });

    return completer.future;
  }

  void _roamMobile() {
    if (Platform.isAndroid && isOverlayApp) {
      _roamAndroidOverlay();
      return;
    }
    isMoving = true;
    _setGif('assets/move.gif');
    final padding =
        isOverlayApp ? EdgeInsets.zero : (stagePadding ?? EdgeInsets.zero);
    final size = stageSize ?? MediaQuery.sizeOf(context);
    final petSize = (Platform.isAndroid && isOverlayApp)
        ? settings.androidOverlaySize
        : settings.petSize;
    final usableHeight = max(0.0, size.height - padding.vertical);
    final next = Offset(
      Random().nextDouble() * (size.width - petSize),
      padding.top + Random().nextDouble() * (usableHeight - petSize),
    );

    final start = position;
    faceLeft = next.dx < start.dx;
    _animateMobileTo(start, next, speedPxPerSec: settings.mobileRoamSpeed);
  }

  Future<void> _roamAndroidOverlay() async {
    final overlaySize = settings.androidOverlaySize;
    final screenSize = _getAndroidScreenSize() ??
        (WidgetsBinding.instance.platformDispatcher.views.first.physicalSize /
            WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio);
    final usable = _getAndroidUsableArea(screenSize, overlaySize);
    var next = Offset(
      usable.left + Random().nextDouble() * usable.width,
      usable.top + Random().nextDouble() * usable.height,
    );

    final current = await FlutterOverlayWindow.getOverlayPosition();
    final start = Offset(current.x, current.y);
    setState(() {
      isMoving = true;
      currentGif = 'assets/move.gif';
      faceLeft = next.dx < start.dx;
      overlayPosition = start;
    });

    await _animateOverlayTo(start, next, speedPxPerSec: settings.mobileRoamSpeed);
    setState(() {
      isMoving = false;
      currentGif = 'assets/idle1.gif';
      overlayPosition = next;
    });
  }

  Size? _getAndroidScreenSize() {
    if (Platform.isAndroid && isOverlayApp && overlayScreenSize != null) {
      return overlayScreenSize;
    }
    return stageSize;
  }

  Rect _getAndroidUsableArea(Size screenSize, double overlaySize) {
    final padding = (Platform.isAndroid && isOverlayApp)
        ? (overlayPadding ?? EdgeInsets.zero)
        : (stagePadding ?? EdgeInsets.zero);
    final left = padding.left;
    final top = padding.top;
    final right = padding.right;
    final bottom = padding.bottom;
    final maxWidth = max(0.0, screenSize.width - left - right - overlaySize);
    final maxHeight = max(0.0, screenSize.height - top - bottom - overlaySize);
    return Rect.fromLTWH(left, top, maxWidth, maxHeight);
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
    final distance = (target - start).distance;
    final durationMs =
        max(_minMoveDurationMs, (distance / speedPxPerSec * 1000).round());
    final duration = Duration(milliseconds: durationMs);
    const frame = Duration(milliseconds: 16);
    final steps = max(1, duration.inMilliseconds ~/ frame.inMilliseconds);
    var tick = 0;

    final completer = Completer<void>();
    Timer.periodic(frame, (timer) async {
      tick += 1;
      final t = tick / steps;
      if (t >= 1) {
        timer.cancel();
        await FlutterOverlayWindow.moveOverlay(
          OverlayPosition(target.dx, target.dy),
        );
        if (settings.showOverlayDebug) {
          setState(() {
            overlayPosition = target;
          });
        }
        completer.complete();
        return;
      }
      final eased = Curves.easeInOut.transform(t);
      final lerp = Offset(
        start.dx + (target.dx - start.dx) * eased,
        start.dy + (target.dy - start.dy) * eased,
      );
      await FlutterOverlayWindow.moveOverlay(
        OverlayPosition(lerp.dx, lerp.dy),
      );
      if (settings.showOverlayDebug) {
        setState(() {
          overlayPosition = lerp;
        });
      }
    });

    return completer.future;
  }

  void _animateMobileTo(
    Offset start,
    Offset target, {
    required double speedPxPerSec,
  }) {
    final distance = (target - start).distance;
    final durationMs =
        max(_minMoveDurationMs, (distance / speedPxPerSec * 1000).round());
    final duration = Duration(milliseconds: durationMs);
    const frame = Duration(milliseconds: 16);
    final steps = max(1, duration.inMilliseconds ~/ frame.inMilliseconds);
    var tick = 0;

    Timer.periodic(frame, (timer) {
      tick += 1;
      final t = tick / steps;
      if (t >= 1) {
        timer.cancel();
        setState(() {
          position = target;
          isMoving = false;
          currentGif = 'assets/idle1.gif';
        });
        return;
      }
      final eased = Curves.easeInOut.transform(t);
      final lerp = Offset(
        start.dx + (target.dx - start.dx) * eased,
        start.dy + (target.dy - start.dy) * eased,
      );
      setState(() {
        position = lerp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final rawPadding = EdgeInsets.fromViewPadding(
      view.padding,
      view.devicePixelRatio,
    );
    final padding = rawPadding;
    stageSize = size;
    stagePadding = padding;
    final petSize = settings.petSize;
    final usableHeight = max(0.0, size.height - padding.vertical);
    final clamped = Offset(
      position.dx.clamp(0.0, max(0.0, size.width - petSize)),
      position.dy.clamp(
        padding.top,
        max(padding.top, padding.top + usableHeight - petSize),
      ),
    );

    if (clamped != position) {
      position = clamped;
    }

    final isDesktop = Platform.isWindows || Platform.isMacOS;
    final isAndroidOverlay = Platform.isAndroid && isOverlayApp;
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
      body: (isDesktop || isAndroidOverlay)
          ? Stack(
              children: [
                Center(child: pet),
                if (isAndroidOverlay && settings.showOverlayDebug)
                  Align(
                    alignment: Alignment.topLeft,
                    child: _OverlayDebugText(
                      position: overlayPosition,
                      usable: _getAndroidUsableArea(
                        _getAndroidScreenSize() ?? size,
                        settings.androidOverlaySize,
                      ),
                      screenSize: _getAndroidScreenSize() ?? size,
                      overlaySize: settings.androidOverlaySize,
                      hasScreenInfo: overlayScreenSize != null,
                    ),
                  ),
              ],
            )
          : Stack(
              children: [
                Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: pet,
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
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
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
              'pos ${position.dx.toStringAsFixed(1)},'
              '${position.dy.toStringAsFixed(1)}',
            ),
            Text(
              'usable ${usable.width.toStringAsFixed(1)}x'
              '${usable.height.toStringAsFixed(1)}',
            ),
            if (!hasScreenInfo)
              const Text(
                'no screen info',
              ),
          ],
        ),
      ),
    );
  }
}
