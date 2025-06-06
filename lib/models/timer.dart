import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerModel extends ChangeNotifier {
  static const _workDuration = 25;
  static const _longBreak = 15;
  static const _shortBreak = 5;
  
  // 确保私有变量声明
  int _remainingSeconds = _workDuration * 60;
  bool _isRunning = false;
  bool _isStarted = false;
  int _completedTasks = 0;
  int _completedSessions = 0;
  String? _currentTaskName; // 新增：当前专注任务的名称

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isStarted => _isStarted;
  int get completedTasks => _completedTasks;
  int get completedSessions => _completedSessions;
  String? get currentTaskName => _currentTaskName; // 新增：获取当前任务名称

  TimerModel() {
    _loadPersistedData();
  }

  void setCurrentTaskName(String? taskName) {
    _currentTaskName = taskName;
    notifyListeners();
  }

  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    _completedTasks = prefs.getInt('completedTasks') ?? 0;
    _completedSessions = prefs.getInt('completedSessions') ?? 0;
    notifyListeners();
  }

  void _persistSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('completedSessions', _completedSessions);
  }

  void start() {
    _isRunning = true;
    _isStarted = true;
    _tick();
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _isStarted = false;
    _remainingSeconds = _workDuration * 60;
    notifyListeners();
  }

  void _handleSessionComplete() {
    _completedSessions++;
    _persistSessionData();
    
    if (_completedSessions % 4 == 0) {
      _remainingSeconds = _longBreak * 60;
    } else {
      _remainingSeconds = _shortBreak * 60;
    }
    notifyListeners();
  }

  void _tick() async {
    while (_isRunning && _remainingSeconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRunning) {
        _remainingSeconds--;
        notifyListeners();
      }
    }
    if (_remainingSeconds == 0) {
      _isRunning = false;
      notifyListeners();
      _handleSessionComplete();
    }
  }

  void completeTask() {
    _completedTasks++;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('completedTasks', _completedTasks);
    });
    notifyListeners();
  }
}