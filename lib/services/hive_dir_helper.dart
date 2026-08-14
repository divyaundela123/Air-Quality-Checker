// ============================================================
// HiveDirHelper — isolates dart:io usage so main.dart
// compiles cleanly on Web (where dart:io is unavailable).
// Called ONLY on non-web platforms.
// ============================================================

import 'dart:io';

class HiveDirHelper {
  /// Returns %LOCALAPPDATA%\AeroSense\hive on Windows.
  /// Returns '' on all other platforms so Hive uses its default path.
  static Future<String> getDir() async {
    if (!Platform.isWindows) return '';
    try {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (localAppData.isEmpty) return '';
      final sep     = Platform.pathSeparator;
      final hiveDir = Directory('$localAppData${sep}AeroSense${sep}hive');
      if (!hiveDir.existsSync()) hiveDir.createSync(recursive: true);
      return hiveDir.path;
    } catch (_) {
      return '';
    }
  }
}
