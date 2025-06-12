import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../utils/logger.dart';
import '../services/webdav.dart';
import './settings.dart';

// status: pending, active, completed

class TaskListItem {
  String id;
  String name;
  String desc;
  String status; // 'pending', 'active', 'completed'
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? completedAt;
  int plannedFocusCount;
  int completedFocusCount;

  TaskListItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.plannedFocusCount = 0,
    this.completedFocusCount = 0,
  });

  factory TaskListItem.fromMap(Map<String, dynamic> map) {
    return TaskListItem(
      id: map['id'] as String,
      name: map['name'] as String,
      desc: map['desc'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.parse(map['completedAt'] as String),
      plannedFocusCount: map['plannedFocusCount'] as int? ?? 0,
      completedFocusCount: map['completedFocusCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'plannedFocusCount': plannedFocusCount,
      'completedFocusCount': completedFocusCount,
    };
  }
}

final String defaultTaskListContent =
    '''
{
  "activityList": [
    {
      "id": "0001",
      "name": "活动-示例01",
      "desc": "活动-示例01的描述",
      "status": "pending",
      "createdAt": "${DateTime.now().toIso8601String()}",
      "updatedAt": "${DateTime.now().toIso8601String()}",
      "completedAt": null,
      "plannedFocusCount": 0,
      "completedFocusCount": 0
    },
    {
      "id": "0002",
      "name": "活动-示例02",
      "desc": "活动-示例02的描述",
      "status": "pending",
      "createdAt": "${DateTime.now().toIso8601String()}",
      "updatedAt": "${DateTime.now().toIso8601String()}",
      "completedAt": null,
      "plannedFocusCount": 0,
      "completedFocusCount": 0
    }
  ],
  "focusList": [
    {
      "id": "0003",
      "name": "专注-示例03",
      "desc": "专注-示例03的描述",
      "status": "pending",
      "createdAt": "${DateTime.now().toIso8601String()}",
      "updatedAt": "${DateTime.now().toIso8601String()}",
      "completedAt": null,
      "plannedFocusCount": 0,
      "completedFocusCount": 0
    },
    {
      "id": "0004",
      "name": "专注-示例04",
      "desc": "专注-示例04的描述",
      "status": "pending",
      "createdAt": "${DateTime.now().toIso8601String()}",
      "updatedAt": "${DateTime.now().toIso8601String()}",
      "completedAt": null,
      "plannedFocusCount": 0,
      "completedFocusCount": 0
    }
  ]
}
''';

class TaskList {
  late List<TaskListItem> activityList;
  late List<TaskListItem> focusList;

  get allLists {
    return {
      'activityList': activityList.map((item) => item.toMap()).toList(),
      'focusList': focusList.map((item) => item.toMap()).toList(),
    };
  }

  TaskList() {
    activityList = [];
    focusList = [];
  }

  TaskList.fromMap(Map<String, dynamic> map) {
    activityList = (map['activityList'] as List)
        .map((item) => TaskListItem.fromMap(item as Map<String, dynamic>))
        .toList();
    focusList = (map['focusList'] as List)
        .map((item) => TaskListItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}

class TaskListManager {
  static final _logger = AppLogger.forClass(TaskListManager);
  static get listName => 'task_list.json';

  static Future<String> _getListPath() async {
    final dir = await getApplicationSupportDirectory();
    return path.join(dir.path, listName);
  }

  static Future<void> _ensureRemoteFileExists() async {
    final Map<String, dynamic> settingsMap = await AppSettings.loadSettings();
    if (settingsMap['webdav']['on'] == true) {
      final webdavService = WebdavService.fromMap(settingsMap['webdav']);
      final localFilePath = await _getListPath();
      final remoteFilePath = listName;
      try {
          if (!await webdavService.fileExists(remoteFilePath)) {
          await webdavService.pushFile(localFilePath, remoteFilePath);
      }
      }
      catch (e, s) {
        _logger.e('Error pulling file from WebDAV: $e \nStack trace: $s');
      }

    }
  }

  static Future<void> _ensureLocalFileExists() async {
    try {
      final String filePath = await _getListPath();
      final configFile = File(filePath);

      if (!await configFile.exists()) {
        _logger.w(
          'Config file not found at $filePath. Creating a default one.',
        );
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

  static Future<void> ensureListFileExists() async {
    await _ensureLocalFileExists();
    await _ensureRemoteFileExists();
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
        _logger.e(
          'List file not found at $filePath during loadList. Returning empty list.',
        );
        return TaskList();
      }

      final String listContent = await listFile.readAsString();
      final allLists = json.decode(listContent);
      return TaskList.fromMap(allLists);
    } catch (e) {
      _logger.e(
        'Error loading or parsing list file: $e. Returning empty list.',
      );
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
