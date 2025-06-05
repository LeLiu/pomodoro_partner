import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

final defaultSettingsContent = '''
{
  "webdav": {
    "on": false,
    "host": "",
    "user": "",
    "passwd": "",
    "path": ""
  }
}
''';

class AppSettings {
  static final Logger _logger =  AppLogger.forClass(AppSettings);

  static Future<String> _getSettingsPath() async {
    final dir = await getApplicationSupportDirectory();
    return path.join(dir.path, 'settings.json');
  }

  static Future<void> ensureSettingsFileExists() async {
    try {
      final String filePath = await _getSettingsPath();
      final settingsFile = File(filePath);

      if (!await settingsFile.exists()) {
        _logger.w('Settings file not found at $settingsFile. Creating a default one.');
        await settingsFile.create(recursive: true); 
        await settingsFile.writeAsString(defaultSettingsContent);
        _logger.i('Default settings file created at $filePath.');
      } else {
        _logger.i('Settings file already exists at $filePath.');
      }
    } catch (e) {
      _logger.e('Error ensuring config file exists: $e');
    }
  }

  static Future<void> initialize() async {
    await ensureSettingsFileExists();
  }

  static Future<void> saveSettings(Map<String, dynamic> config) async {

    final String filePath = await _getSettingsPath();
    final settingsFile = File(filePath);
    await settingsFile.writeAsString(json.encode(config));
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      final String filePath = await _getSettingsPath();
      final settingsFile = File(filePath);
      final content = await settingsFile.readAsString();
      return json.decode(content);
    } catch (e) {
      _logger.e('Error load settings file: $e. Returning default settings.');
      return json.decode(defaultSettingsContent);
    }
  }
}