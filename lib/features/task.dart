import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../utils/logger.dart';
import '../services/webdav.dart';
import './settings.dart';

// status: pending, active, completed
final String defaultTaskListContent = '''
{
  "activityList": [
    {
      "id": "0001",
      "name": "活动-示例01",
      "desc": "活动-示例01的描述",
      "status": 'pending',
      "createdAt": "${DateTime.now().toIso8601String()}",
      "updatedAt": "${DateTime.now().toIso8601String()}",
      "plannedFocusCount": 0,
      "completedFocusCount": 0
    },
    {
      "id": "0002",
      "name": "活动-示例02",
      "desc": "活动-示例02的描述",
      "status": 'pending',
      "createdAt": "${DateTime.now().toIso8601String()}",
      "updatedAt": "${DateTime.now().toIso8601String()}",
      "plannedFocusCount": 0,
      "completedFocusCount": 0
    }
  ],
  "focusList": [
    {
      "id": "0003",
      "name": "专注-示例03",
      "desc": "专注-示例03的描述",
      "status": 'pending',
      "createdAt": "${DateTime.now().toIso8601String()}",
      "updatedAt": "${DateTime.now().toIso8601String()}",
      "plannedFocusCount": 0,
      "completedFocusCount": 0
    },
    {
      "id": "0004",
      "name": "专注-示例04",
      "desc": "专注-示例04的描述",
      "status": 'pending',
      "createdAt": "${DateTime.now().toIso8601String()}",
      "updatedAt": "${DateTime.now().toIso8601String()}",
      "plannedFocusCount": 0,
      "completedFocusCount": 0
    }
  ]
}
''';

class TaskList {
  late List<Map<String, dynamic>> activityList;
  late List<Map<String, dynamic>> focusList;

  get allLists {
    return {
      'activityList': activityList,
      'focusList': focusList,
    };
  }

  TaskList() {
    activityList = [];
    focusList = [];
  }

  TaskList.fromMap(Map<String, dynamic> map) {
    activityList = List<Map<String, dynamic>>.from(map['activityList']);
    focusList = List<Map<String, dynamic>>.from(map['focusList']);
  }
}

class TaskListManager {
  static final _logger = AppLogger.forClass(TaskListManager);
  static get listName => 'todo_list.json';
  
  static Future<String> _getListPath() async {
    final dir = await getApplicationSupportDirectory();
    return path.join(dir.path, listName);
  }

  static Future<void> ensureListFileExists() async {
    try {
      final String filePath = await _getListPath();
      final configFile = File(filePath);

      if (!await configFile.exists()) {
        _logger.w('Config file not found at $filePath. Creating a default one.');
        await configFile.create(recursive: true); 
        await configFile.writeAsString(defaultTaskListContent);
        _logger.i('Default config file created at $filePath.');
      } else {
        _logger.i('List file already exists at $filePath.');
      }
    } catch (e) {
      _logger.e('Error ensuring list file exists: $e');
    }
  }

  static Future<void> saveList(TaskList list) async {
    final String filePath = await _getListPath();
    final listFile = File(filePath);
    await listFile.writeAsString(json.encode(list.allLists));
  }

  static Future<TaskList> loadList() async {
    try {
      final String filePath = await _getListPath();
      final listFile = File(filePath);

      if (!await listFile.exists()) {
        _logger.e('List file not found at $filePath during loadList. Returning empty list.');
        return TaskList();
      }

      final String listContent = await listFile.readAsString();
      final allLists = json.decode(listContent);
      return TaskList.fromMap(allLists);
    } catch (e) {
       _logger.e('Error loading or parsing list file: $e. Returning empty list.');
       return TaskList(); // Return an empty list as a last resort
    }
  }

  static Future<void> initialize() async {
    await ensureListFileExists();
  }

  static Future<void> syncList() async {
    final Map<String, dynamic> settingsMap = await AppSettings.loadSettings();
    if (settingsMap['webdav']['on'] == true) {
      final webdavService = WebdavService.fromMap(settingsMap['webdav']);
      final localFilePath = await _getListPath();
      final remoteFilePath = listName;
      await webdavService.syncFile(localFilePath, remoteFilePath);
    }
  }

  static Future<TaskList> syncAndLoadList() async {
    await syncList();
    return await loadList();
  }

  static Future<void> saveAndSyncList(TaskList list) async {
    await saveList(list);
    await syncList();
  }
  
}