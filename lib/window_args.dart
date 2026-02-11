import 'dart:convert';

class WindowArgs {
  const WindowArgs(this.type);

  final String type;

  static const String typeMain = 'main';
  static const String typeSettings = 'settings';

  static const WindowArgs main = WindowArgs(typeMain);
  static const WindowArgs settings = WindowArgs(typeSettings);

  static WindowArgs fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return WindowArgs.main;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['type'] is String) {
        return WindowArgs(decoded['type'] as String);
      }
    } catch (_) {}
    return WindowArgs.main;
  }

  String toJsonString() => jsonEncode({'type': type});
}
