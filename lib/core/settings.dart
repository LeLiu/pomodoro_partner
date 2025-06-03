import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import './logger.dart';

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
        console.log('Settings file not found at $settingsFile. Creating a default one.');
        await configFile.create(recursive: true); 
        await configFile.writeAsString(defaultConfigContent);
        print('Default config file created at $filePath.');
      } else {
        print('Config file already exists at $filePath.');
      }
    } catch (e) {
      print('Error ensuring config file exists: $e');
    }
  }

  static Future<void> initialize() async {
    await ensureConfigFileExists();
  }

  static Future<void> saveConfig(Map<String, dynamic> config) async {

    final String filePath = await _getConfigPath();
    final configFile = File(filePath);
    await configFile.writeAsString(json.encode(config));
  }

  static Future<Map<String, dynamic>> loadConfig() async {
    try {
      final String filePath = await _getConfigPath();
      final configFile = File(filePath);
      final content = await configFile.readAsString();
      return json.decode(content);
    } catch (e) {
      print('Error load config file: $e. Returning default config.');
      return json.decode(defaultConfigContent);
    }
  }
}