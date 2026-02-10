import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

const Color windowsChromaKey = Color(0xFFFF00FF);

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS) {
    final windowId = args.isEmpty ? 0 : int.tryParse(args.first) ?? 0;
    await WindowManagerPlus.ensureInitialized(windowId);

    final windowOptions = WindowOptions(
      size: Size(180, 180),
      center: true,
      backgroundColor: Platform.isWindows ? windowsChromaKey : Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      skipTaskbar: true,
    );

    WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
      await WindowManagerPlus.current.setAsFrameless();
      await WindowManagerPlus.current.setResizable(false);
      await WindowManagerPlus.current.setHasShadow(false);
      await WindowManagerPlus.current.setOpacity(1);
      await WindowManagerPlus.current.setVisibleOnAllWorkspaces(true);
      await WindowManagerPlus.current.setAlwaysOnTop(true);
      await WindowManagerPlus.current.setBackgroundColor(
        Platform.isWindows ? windowsChromaKey : Colors.transparent,
      );
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  runApp(const AmeathPetApp());
}

class AmeathPetApp extends StatelessWidget {
  const AmeathPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ameath Pet',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E23)),
        scaffoldBackgroundColor:
            isWindows ? windowsChromaKey : Colors.transparent,
        canvasColor: isWindows ? windowsChromaKey : Colors.transparent,
      ),
      home: const PetStage(),
    );
  }
}

class PetStage extends StatefulWidget {
  const PetStage({super.key});

  @override
  State<PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<PetStage> {
  static const double petSize = 160;
  static const double desktopWindowSize = 180;
  static const double desktopRoamSpeed = 100.0; // px/sec

  final List<String> idleGifs = const [
    'gifs/idle1.gif',
    'gifs/idle2.gif',
    'gifs/idle3.gif',
    'gifs/idle4.gif',
  ];

  String currentGif = 'gifs/idle1.gif';
  Offset position = const Offset(120, 220);
  Timer? idleTimer;
  Timer? roamTimer;
  bool isDragging = false;
  bool isMoving = false;
  bool faceLeft = false;
  Offset? screenOrigin;
  Size? screenSize;

  @override
  void initState() {
    super.initState();
    _startIdleLoop();
    _initRoamLoop();
  }

  @override
  void dispose() {
    idleTimer?.cancel();
    roamTimer?.cancel();
    super.dispose();
  }

  Future<void> _initRoamLoop() async {
    if (!(Platform.isWindows || Platform.isMacOS)) return;

    final display = await screenRetriever.getPrimaryDisplay();
    final size = display.visibleSize ?? display.size;
    setState(() {
      screenOrigin = Offset.zero;
      screenSize = Size(size.width.toDouble(), size.height.toDouble());
    });

    roamTimer?.cancel();
    roamTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (isDragging || isMoving) return;
      _roamDesktop();
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
    _setGif('gifs/drag.gif');
    if (Platform.isWindows || Platform.isMacOS) {
      WindowManagerPlus.current.startDragging();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (Platform.isWindows || Platform.isMacOS) return;
    setState(() {
      if (details.delta.dx.abs() > 0.1) {
        faceLeft = details.delta.dx < 0;
      }
      position += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    isDragging = false;
    _setGif('gifs/idle1.gif');
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
    final next = Offset(
      origin.dx + Random().nextDouble() * (size.width - desktopWindowSize),
      origin.dy + Random().nextDouble() * (size.height - desktopWindowSize),
    );
    final start = await WindowManagerPlus.current.getPosition();

    setState(() {
      isMoving = true;
      currentGif = 'gifs/move.gif';
      faceLeft = next.dx < start.dx;
    });
    await _animateWindowTo(next, speedPxPerSec: desktopRoamSpeed);
    setState(() {
      isMoving = false;
      currentGif = 'gifs/idle1.gif';
    });
  }

  Future<void> _animateWindowTo(
    Offset target, {
    required double speedPxPerSec,
  }) async {
    final start = await WindowManagerPlus.current.getPosition();
    final distance = (target - start).distance;
    final durationMs = max(200, (distance / speedPxPerSec * 1000).round());
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
    isMoving = true;
    _setGif('gifs/move.gif');
    final size = MediaQuery.sizeOf(context);
    final next = Offset(
      Random().nextDouble() * (size.width - petSize),
      Random().nextDouble() * (size.height - petSize),
    );

    final start = position;
    faceLeft = next.dx < start.dx;
    const steps = 30;
    var tick = 0;
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      tick += 1;
      final t = tick / steps;
      if (t >= 1) {
        timer.cancel();
        setState(() {
          position = next;
          isMoving = false;
          currentGif = 'gifs/idle1.gif';
        });
        return;
      }
      final lerp = Offset(
        start.dx + (next.dx - start.dx) * t,
        start.dy + (next.dy - start.dy) * t,
      );
      setState(() {
        position = lerp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final clamped = Offset(
      position.dx.clamp(0.0, max(0.0, size.width - petSize)),
      position.dy.clamp(0.0, max(0.0, size.height - petSize)),
    );

    if (clamped != position) {
      position = clamped;
    }

    final isDesktop = Platform.isWindows || Platform.isMacOS;
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
      backgroundColor: Platform.isWindows ? windowsChromaKey : Colors.transparent,
      body: isDesktop
          ? Center(child: pet)
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
