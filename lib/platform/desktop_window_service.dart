import 'package:multi_window_manager/multi_window_manager.dart';

import '../models/window_args.dart';

Future<MultiWindowManager?> findDesktopWindow(String type) async {
  final current = MultiWindowManager.current;
  final windowIds = await MultiWindowManager.getAllAliveEngineIds();
  for (final windowId in windowIds) {
    if (windowId == current.id) continue;
    try {
      final result = await current.invokeMethodToWindow(
        windowId,
        'getWindowType',
      );
      if (result == type) {
        return MultiWindowManager.fromWindowId(windowId);
      }
    } catch (_) {
      // The window may have closed while the registry was being inspected.
    }
  }
  return null;
}

Future<MultiWindowManager> openOrFocusSettingsWindow() async {
  var window = await findDesktopWindow(WindowArgs.typeSettings);
  window ??= await MultiWindowManager.createWindow([
    WindowArgs.settings.toJsonString(),
  ]);
  if (window == null) {
    throw StateError('Unable to create the settings window.');
  }
  await window.show();
  await window.focus();
  return window;
}

Future<dynamic> invokeMainWindow(
  String method, [
  dynamic arguments,
]) {
  return MultiWindowManager.current.invokeMethodToWindow(
    0,
    method,
    arguments,
  );
}
