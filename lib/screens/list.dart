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
import '../services/bing_image.dart';
import 'dart:io';

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
  bool _showItemPane = false;
  TaskListItem? _currentItem;
  bool _isEditingActivityItem = false;
  File? _backgroundImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLists();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final bingService = BingImageService();
      final latestImage = await bingService.getLatestBackgroundImage();
      if (mounted) {
        setState(() {
          _backgroundImage = latestImage;
        });
      }
    } catch (e) {
      AppLogger.logger.e('加载背景图片失败: $e');
    }
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
            TaskListItem.fromMap({
              'name': '活动加载失败',
              'id': 'error',
              'status': 'pending',
            }),
          ];
          _focusList = [
            TaskListItem.fromMap({
              'name': '专注列表加载失败',
              'id': 'error',
              'status': 'pending',
            }),
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

  void _toggleItemDone(TaskListItem item, bool done) {
    if (!mounted) return;

    if (done) {
      item.status = 'completed';
      item.completedAt = DateTime.now();
    } else {
      item.status = item.completedFocusCount > 0 ? 'active' : 'pending';
      item.updatedAt = DateTime.now();
      item.completedAt = null;
    }

    setState(() {
      _currentItem = item;
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

  void _showTaskItemPane(
    BuildContext context,
    bool isActivityList,
    TaskListItem item,
  ) {
    setState(() {
      _currentItem = item;
      _isEditingActivityItem = isActivityList;
      _showItemPane = true;
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
      isVisible: _showItemPane,
      onVisibilityChanged: (visible) {
        setState(() {
          _showItemPane = visible;
        });
      },
      paneBuilder: (context, closePane) => _buildTaskItemPane(closePane),
      mainContent: Container(
        padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _backgroundImage != null
                ? FileImage(_backgroundImage!)
                : const AssetImage('assets/background/01.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.transparent),
          child: Column(
            children: <Widget>[
              AppBar(
                title: Row(
                  children: [
                    Icon(FluentIcons.task_list, color: Colors.white),
                    SizedBox(width: 10),
                    const Text('任务清单'),
                  ],
                ),
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.transparent,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical:4),
                child: TabSwitch(
                  selectedIndex: _tabController.index,
                  onChanged: (index) {
                    setState(() {
                      _tabController.index = index;
                    });
                  },
                  items: const [
                    TabSwitchItem(label: '活动清单', icon: FluentIcons.group_list),
                    TabSwitchItem(
                      label: '专注清单',
                      icon: FluentIcons.favorite_list,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _tabController.index == 0
                    ? _buildTabList(true)
                    : _buildTabList(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItemPane(VoidCallback closePane) {
    if (_currentItem == null) {
      return const Center(child: Text('没有选中的任务'));
    }

    return TaskView(
      key: UniqueKey(),
      taskItem: _currentItem!,
      isActivityItem: _isEditingActivityItem,
      onMoveToOtherList: _moveItemToOtherList,
      onDelete: () {
        _deleteCurrentItem();
        closePane();
      },
      onClose: closePane,
      onTaskUpdate: (updatedTask) {
        setState(() {
          _currentItem = updatedTask;
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

  Widget _buildListItem(TaskListItem item, bool isActivityList, bool isDone) {
    final FlyoutController controller = FlyoutController();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor.withAlpha(0xEE),
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
            contentPadding: EdgeInsets.all(0),
            leading: HoverCheckbox(
              value: isDone,
              onChanged: (value) => _toggleItemDone(item, value),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            onPressed: () => _showTaskItemPane(context, isActivityList, item),
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

  Widget _buildTabList(bool isActivityList) {
    var list = isActivityList ? _activityList : _focusList;
    if (_isLoading) return const Center(child: ProgressRing());
    if (list.isEmpty) {
      // TODO should return a empty page here
      return Column(
        children: [
          const Center(child: Text('没有任务')),
          _buildItemAdder(isActivityList),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final bool isDone = item.status == 'completed';
              return _buildListItem(item, isActivityList, isDone);
            },
          ),
        ),
        _buildItemAdder(isActivityList),
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
                _toggleItemDone(item, isDone);
                controller.close();
              },
            ),
            MenuFlyoutItem(
              text: const Text('编辑'),
              onPressed: () {
                _showTaskItemPane(context, isActivityList, item);
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
    if (_currentItem == null) return;

    setState(() {
      if (_isEditingActivityItem) {
        // 从活动列表移动到专注列表
        _activityList.removeWhere((item) => item.id == _currentItem!.id);
        _focusList.add(_currentItem!);
      } else {
        // 从专注列表移动到活动列表
        _focusList.removeWhere((item) => item.id == _currentItem!.id);
        _activityList.add(_currentItem!);
      }
      _currentItem!.updatedAt = DateTime.now();
      _showItemPane = false;
    });
    _saveLists();
  }

  // 删除当前项目
  void _deleteCurrentItem() {
    if (_currentItem == null) return;

    setState(() {
      if (_isEditingActivityItem) {
        _activityList.removeWhere((item) => item.id == _currentItem!.id);
      } else {
        _focusList.removeWhere((item) => item.id == _currentItem!.id);
      }
      _currentItem = null;
      _showItemPane = false;
    });
    _saveLists();
  }

  Widget _buildItemAdder(bool isActivityList) {
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
