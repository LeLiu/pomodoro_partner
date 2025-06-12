import 'package:flutter/material.dart'
    hide Colors, IconButton, Checkbox, ListTile, FilledButton;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
//import '../models/timer_model.dart';
import '../features/list.dart';
import '../utils/logger.dart';
import '../widgets/slide_pane.dart';
import '../widgets/task_view.dart';
import '../widgets/tab_switch.dart';
import '../widgets/hover_checkbox.dart';

VoidCallback? switchToFoucsScreen;

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen>
    with SingleTickerProviderStateMixin {
  List<TaskListItem> _activityList = [];
  List<TaskListItem> _focusList = [];
  late TabController _tabController;
  bool _isLoading = true;
  bool _showEditPanel = false;
  TaskListItem? _currentEditItem;
  bool _isEditingActivityItem = false;

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
      final taskList = await TaskListManager.syncAndLoadList();
      if (mounted) {
        setState(() {
          _activityList = taskList.activityList;
          _focusList = taskList.focusList;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.logger.e('Error loading lists in ListScreen: $e');
      // TODO Show error message in a dialog
      if (mounted) {
        setState(() {
          _activityList = [
            TaskListItem.fromMap({'name': '活动加载失败', 'id': 'error', 'status': 'pending'}),
          ];
          _focusList = 
          [
            TaskListItem.fromMap({'name': '专注列表加载失败', 'id': 'error', 'status': 'pending'}),
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
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('错误'),
              content: Text('保存列表失败: $e'),
              severity: InfoBarSeverity.error,
            );
          },
        );
      }
    }
  }

  void _toggleItemDone(TaskListItem item) {
    if (!mounted) return;
    setState(() {
      final bool currentDone = item.status == 'completed';
      item.status = !currentDone ? 'completed' : 'pending';
      item.updatedAt = DateTime.now();
      if (!currentDone) {
        item.completedAt = DateTime.now();
      } else {
        item.completedAt = null;
      }

      // 如果当前编辑的是同一个项目，同步更新编辑面板中的数据
      if (_currentEditItem != null && _currentEditItem!.id == item.id) {
        _currentEditItem!.status = item.status;
        _currentEditItem!.updatedAt = item.updatedAt;
        _currentEditItem!.completedAt = item.completedAt;
      }
    });
    _saveLists();
  }

  void _deleteActivityItem(TaskListItem item) {
    if (!mounted) return;
    setState(() {
      _activityList.removeWhere((element) => element.id == item.id);
    });
    _saveLists();
  }

  void _deleteFocusItem(TaskListItem item) {
    if (!mounted) return;
    setState(() {
      _focusList.removeWhere((element) => element.id == item.id);
    });
    _saveLists();
  }

  void _deleteItem(TaskListItem item, bool isActivityList) {
    if (isActivityList) {
      _deleteActivityItem(item);
    } else {
      _deleteFocusItem(item);
    }
  }

  void _showEditItemPanel(
    BuildContext context,
    bool isActivityList,
    TaskListItem item,
  ) {
    setState(() {
      _currentEditItem = item;
      _isEditingActivityItem = isActivityList;
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
    final theme = FluentTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SlideLayout(
      config: SlidePaneConfig(
        backgroundColor: isDarkMode
            ? theme.scaffoldBackgroundColor
            : const Color(0xFFFAFAFA),
        headerBackgroundColor: isDarkMode
            ? theme.scaffoldBackgroundColor
            : const Color(0xFFFFFFFF),
        headerTextColor: isDarkMode
            ? (theme.typography.body?.color ?? theme.inactiveColor)
            : const Color(0xFF1F2937),
        footerBackgroundColor: isDarkMode
            ? theme.scaffoldBackgroundColor
            : const Color(0xFFFFFFFF),
        borderColor: isDarkMode
            ? theme.resources.dividerStrokeColorDefault
            : const Color(0xFFE5E7EB),
        shadowColor: isDarkMode ? theme.shadowColor : const Color(0x0F000000),
        overlayColor: isDarkMode
            ? theme.resources.layerOnMicaBaseAltFillColorDefault
            : const Color(0x40000000),
      ),
      isVisible: _showEditPanel,
      onVisibilityChanged: (visible) {
        setState(() {
          _showEditPanel = visible;
        });
      },
      paneBuilder: (context, closePane) => _buildEditPanel(closePane),
      mainContent: Container(
        decoration: BoxDecoration(color: theme.accentColor.lightest),
        child: Column(
          children: <Widget>[
            AppBar(title: const Text('清单')),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TabSwitch(
                selectedIndex: _tabController.index,
                onChanged: (index) {
                  setState(() {
                    _tabController.index = index;
                  });
                },
                items: const [
                  TabSwitchItem(label: '活动清单', icon: FluentIcons.group_list),
                  TabSwitchItem(label: '专注清单', icon: FluentIcons.favorite_list),
                ],
              ),
            ),
            Expanded(
              child: _tabController.index == 0
                  ? _buildTodoListTab(true)
                  : _buildTodoListTab(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditPanel(VoidCallback closePane) {
    if (_currentEditItem == null) {
      return const Center(child: Text('没有选中的任务'));
    }

    return TaskView(
      taskItem: _currentEditItem!,
      isActivityItem: _isEditingActivityItem,
      onMoveToOtherList: _moveItemToOtherList,
      onDelete: () {
        _deleteCurrentItem();
        closePane();
      },
      onClose: closePane,
      onTaskUpdate: (updatedTask) {
        setState(() {
          _currentEditItem = updatedTask;
          // 同步更新列表中的对应项目
          final targetList = _isEditingActivityItem
              ? _activityList
              : _focusList;
          final index = targetList.indexWhere(
            (item) => item.id == updatedTask.id,
          );
          if (index != -1) {
            targetList[index] = updatedTask;
          }
        });
        _saveLists();
      },
    );
  }

  Widget _buildListItem(
    TaskListItem item,
    bool isActivityList,
    bool isDone,
  ) {
    final FlyoutController controller = FlyoutController();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: FlyoutTarget(
        controller: controller,
        child: GestureDetector(
          onSecondaryTapUp: (details) {
            _showItemContextMenu(
              context,
              details.globalPosition,
              item,
              isActivityList,
              isDone,
              controller,
            );
          },
          child: ListTile(
            leading: HoverCheckbox(
              value: isDone,
              onChanged: (value) => _toggleItemDone(item),
            ),
            title: Text(
              item.name,
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
                      // Provider.of<TimerModel>(
                      //   context,
                      //   listen: false,
                      // ).setCurrentTaskName(item.name);
                      // Provider.of<TimerModel>(context, listen: false).start();
                      // switchToFoucsScreen?.call();
                    },
                  ),
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
            itemBuilder: (context, index) {
              final item = todoList[index];
              final bool isDone = item.status == 'completed';
              return _buildListItem(item, isActivityList, isDone);
            },
          ),
        ),
        _buildAddItemInput(isActivityList),
      ],
    );
  }

  void _showItemContextMenu(
    BuildContext context,
    Offset position,
    TaskListItem item,
    bool isActivityList,
    bool isDone,
    FlyoutController controller,
  ) {
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

  // 移动项目到其他列表
  void _moveItemToOtherList() {
    if (_currentEditItem == null) return;

    setState(() {
      if (_isEditingActivityItem) {
        // 从活动列表移动到专注列表
        _activityList.removeWhere(
          (item) => item.id == _currentEditItem!.id,
        );
        _focusList.add(_currentEditItem!);
      } else {
        // 从专注列表移动到活动列表
        _focusList.removeWhere((item) => item.id == _currentEditItem!.id);
        _activityList.add(_currentEditItem!);
      }
      _currentEditItem!.updatedAt = DateTime.now();
      _showEditPanel = false;
    });
    _saveLists();
  }

  // 删除当前项目
  void _deleteCurrentItem() {
    if (_currentEditItem == null) return;

    setState(() {
      if (_isEditingActivityItem) {
        _activityList.removeWhere(
          (item) => item.id == _currentEditItem!.id,
        );
      } else {
        _focusList.removeWhere((item) => item.id == _currentEditItem!.id);
      }
      _currentEditItem = null;
      _showEditPanel = false;
    });
    _saveLists();
  }

  Widget _buildAddItemInput(bool isActivityList) {
    final TextEditingController controller = TextEditingController();

    void addItem() {
      if (controller.text.isNotEmpty) {
        final newItem = TaskListItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: controller.text,
          desc: '',
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          plannedFocusCount: 0,
          completedFocusCount: 0,
        );
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
            IconButton(icon: const Icon(FluentIcons.add), onPressed: addItem),
            Expanded(
              child: TextBox(
                controller: controller,
                placeholder: isActivityList ? '添加活动事项' : '添加专注事项',
                onSubmitted: (_) => addItem(),
              ),
            ),
            IconButton(icon: const Icon(FluentIcons.send), onPressed: addItem),
          ],
        ),
      ),
    );
  }
}
