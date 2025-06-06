import 'package:flutter/foundation.dart';

class TodoList extends ChangeNotifier {
  List<Map<String, dynamic>> _activityList = [];
  List<Map<String, dynamic>> _focusList = [];

  List<Map<String, dynamic>> get activityList => _activityList;
  List<Map<String, dynamic>> get focusList => _focusList;

  set activityList(List<Map<String, dynamic>> value) {
    _activityList = value;
    notifyListeners();
  }

  set focusList(List<Map<String, dynamic>> value) {
    _focusList = value;
    notifyListeners();
  }

  void addActivityItem(Map<String, dynamic> item) {
    _activityList.add(item);
    notifyListeners();
  }

  void addFocusItem(Map<String, dynamic> item) {
    _focusList.add(item);
    notifyListeners();
  }

  void removeActivityItem(String id) {
    _activityList.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  void removeFocusItem(String id) {
    _focusList.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  void updateActivityItem(String id, Map<String, dynamic> updatedItem) {
    final index = _activityList.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      _activityList[index] = updatedItem;
      notifyListeners();
    }
  }

  void updateFocusItem(String id, Map<String, dynamic> updatedItem) {
    final index = _focusList.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      _focusList[index] = updatedItem;
      notifyListeners();
    }
  }

  void clear() {
    _activityList.clear();
    _focusList.clear();
    notifyListeners();
  }
}