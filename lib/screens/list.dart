import 'package:flutter/material.dart' hide Colors, IconButton, Checkbox, ListTile, FilledButton;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../models/timer.dart';
import '../features/list.dart';
import '../utils/logger.dart';
import '../widgets/slide_pane.dart';

VoidCallback? switchToFoucsScreen;

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _activityList = [];
  List<Map<String, dynamic>> _focusList = [];
  late TabController _tabController;
  bool _isLoading = true;
  bool _showEditPanel = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLists();
  }

  Future<void> _loadLists() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final todoList = await TaskListManager.syncAndLoadList();
      if (mounted) {
        setState(() {
          _activityList =
              List<Map<String, dynamic>>.from(todoList.activityList);
          _focusList = List<Map<String, dynamic>>.from(todoList.focusList);
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.logger.e('Error loading lists in ListScreen: $e');
      // TODO Show error message in a dialog
      if (mounted) {
        setState(() {
          _activityList = [
            {'name': '活动列表加载失败', 'id': 'error', 'done': false}
          ];
          _focusList = [
            {'name': '今日待办加载失败', 'id': 'error', 'done': false}
          ];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveLists() async {
    try {
      final taskList = TaskList()
        ..activityList = _activityList
        ..focusList = _focusList;
      await TaskListManager.saveAndSyncList(taskList);
    } catch (e) {
      AppLogger.logger.e('Error saving lists in ListScreen: $e');
      if (mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('错误'),
            content: Text('保存列表失败: $e'),
            severity: InfoBarSeverity.error,
          );
        });
      }
    }
  }

  void _toggleItemDone(Map<String, dynamic> item) {
    if (!mounted) return;
    setState(() {
      item['status'] = 'completed';
      item['updatedAt'] = DateTime.now().toIso8601String();
    });
    _saveLists();
  }

  void _deleteActivityItem(Map<String, dynamic> item) {
    if (!mounted) return;
    setState(() {
      _activityList.removeWhere((element) => element['id'] == item['id']);
    });
    _saveLists();
  }



  void _deleteFocusItem(Map<String, dynamic> item) {
    if (!mounted) return;
    setState(() {
      _focusList.removeWhere((element) => element['id'] == item['id']);
    });
    _saveLists();
  }

  void _deleteItem(Map<String, dynamic> item, bool isActivityList) {
    if (isActivityList) {
      _deleteActivityItem(item);
    } else {
      _deleteFocusItem(item);
    }
  }



  void _showEditItemPanel(
      BuildContext context, bool isActivityList, Map<String, dynamic> item) {
    setState(() {
      _showEditPanel = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideLayout(
      config: const SlidePaneConfig(
        headerTitle: '编辑任务',
        headerIcon: FluentIcons.edit,
      ),
      isVisible: _showEditPanel,
      onVisibilityChanged: (visible) {
        setState(() {
          _showEditPanel = visible;
        });
      },
      contentBuilder: (context, closePane) => _buildEditPanel(closePane),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleSwitch(
              checked: _tabController.index == 1,
              onChanged: (value) {
                setState(() {
                  _tabController.index = value ? 1 : 0;
                });
              },
              content: Text(_tabController.index == 0 ? '活动清单' : '专注清单'),
            ),
          ),
          Expanded(
            child: _tabController.index == 0
                ? _buildTodoListTab(true)
                : _buildTodoListTab(false),
          ),
        ],
      ),
    );
  }


  Widget _buildEditPanel(VoidCallback closePane) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('编辑任务', style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 16),
          TextBox(
            placeholder: '任务名称',
          ),
          const SizedBox(height: 16),
          TextBox(
            placeholder: '任务描述',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  closePane();
                },
                child: const Text('保存'),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: closePane,
                child: const Text('取消'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, bool isActivityList) {
    final bool isDone = item['done'] as bool? ?? false;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          _showItemContextMenu(
              context,
              details.globalPosition,
              item,
              isActivityList,
              isDone);
        },
        child: ListTile(
          leading: Checkbox(
            checked: isDone,
            onChanged: (value) => _toggleItemDone(item),
          ),
          title: Text(
            item['name'] as String? ?? '!!!未知任务',
            style: TextStyle(
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          onPressed: () => _showEditItemPanel(context, isActivityList, item),
          trailing: isActivityList || isDone
              ? null
              : IconButton(
                  icon: const Icon(FluentIcons.play),
                  onPressed: () {
                    Provider.of<TimerModel>(context, listen: false)
                        .setCurrentTaskName(item['name']);
                    Provider.of<TimerModel>(context, listen: false).start();
                    switchToFoucsScreen?.call();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildTodoListTab(bool isActivityList) {
    var todoList = isActivityList ? _activityList : _focusList;
    if (_isLoading) return const Center(child: ProgressRing());
    if (todoList.isEmpty) {
      return Column(
        children: [
          const Center(child: Text('没有专注事项')),
          _buildAddItemInput(false),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: todoList.length,
            itemBuilder: (context, index) =>
                _buildListItem(todoList[index], isActivityList),
          ),
        ),
        _buildAddItemInput(isActivityList),
      ],
    );
  }

  void _showItemContextMenu(BuildContext context, Offset position,
      Map<String, dynamic> item, bool isActivityList, bool isDone) {
    final FlyoutController controller = FlyoutController();

    controller.showFlyout(
      barrierColor: Colors.transparent,
      builder: (context) {
        return MenuFlyout(
          items: [
            MenuFlyoutItem(
              text: Text(isDone ? '标记为未完成' : '标记为完成'),
              onPressed: () {
                _toggleItemDone(item);
                controller.close();
              },
            ),
            MenuFlyoutItem(
              text: const Text('编辑'),
              onPressed: () {
                _showEditItemPanel(context, isActivityList, item);
                controller.close();
              },
            ),
            MenuFlyoutItem(
              text: const Text('删除'),
              onPressed: () {
                _deleteItem(item, isActivityList);
                controller.close();
              },
            ),
          ],
        );
      },
      position: position,
    );
  }

  Widget _buildAddItemInput(bool isActivityList) {
    final TextEditingController controller = TextEditingController();

    void addItem() {
      if (controller.text.isNotEmpty) {
        final newItem = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': controller.text,
          'desc': '',
          'done': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'plannedFocusCount': 0,
          'completedFocusCount': 0,
        };
        setState(() {
          if (isActivityList) {
            _activityList.add(newItem);
          } else {
            _focusList.add(newItem);
          }
        });
        _saveLists();
        controller.clear();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(FluentIcons.add),
              onPressed: addItem,
            ),
            Expanded(
              child: TextBox(
                controller: controller,
                placeholder: isActivityList ? '添加活动事项' : '添加专注事项',
                onSubmitted: (_) => addItem(),
              ),
            ),
            IconButton(
              icon: const Icon(FluentIcons.send),
              onPressed: addItem,
            ),
          ],
        ),
      ),
    );
  }
}
