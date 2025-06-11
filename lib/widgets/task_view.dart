import 'package:fluent_ui/fluent_ui.dart';
import '../widgets/hover_checkbox.dart';
import '../widgets/expander.dart';

/// 任务编辑组件
class TaskView extends StatefulWidget {
  /// 任务项数据
  final Map<String, dynamic> taskItem;

  /// 是否为活动列表中的任务
  final bool isActivityItem;

  /// 移动任务到其他列表的回调
  final VoidCallback? onMoveToOtherList;

  /// 删除任务的回调
  final VoidCallback? onDelete;

  /// 关闭面板的回调
  final VoidCallback? onClose;

  /// 任务更新回调
  final Function(Map<String, dynamic>)? onTaskUpdate;

  const TaskView({
    super.key,
    required this.taskItem,
    required this.isActivityItem,
    this.onMoveToOtherList,
    this.onDelete,
    this.onClose,
    this.onTaskUpdate,
  });

  @override
  State<TaskView> createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late FocusNode _nameFocusNode;
  late FocusNode _descFocusNode;
  late String _originalDesc;
  late String _originalName;
  late bool _isCompleted;
  late int _plannedFocusCount;
  late int _completedFocusCount;
  late String _status;

  final _menuFoucsSelectController = FlyoutController();
  final _menuFoucsSelectAttachKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _originalName = widget.taskItem['name'] ?? '未知任务';
    _nameController = TextEditingController(text: _originalName);
    _nameFocusNode = FocusNode();

    _originalDesc = widget.taskItem['desc'] ?? '';
    _descController = TextEditingController(text: _originalDesc);
    _descFocusNode = FocusNode();

    _isCompleted = widget.taskItem['status'] == 'completed';
    _plannedFocusCount = widget.taskItem['plannedFocusCount'] ?? 0;
    _completedFocusCount = widget.taskItem['completedFocusCount'] ?? 0;
    _status = widget.taskItem['status'] ?? 'pending';

    _nameFocusNode.addListener(_onNameFocusChanged);
    _descFocusNode.addListener(_onDescriptionFocusChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.removeListener(_onNameFocusChanged);
    _nameFocusNode.dispose();

    _descController.dispose();
    _descFocusNode.removeListener(_onDescriptionFocusChanged);
    _descFocusNode.dispose();
    super.dispose();
  }

  void _onNameFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      _saveNameChanges();
    }
  }

  void _onDescriptionFocusChanged() {
    if (!_descFocusNode.hasFocus) {
      _saveDescriptionChanges();
    }
  }

  void _saveDescriptionChanges() {
    final newDescription = _descController.text.trim();
    if (newDescription != _originalDesc) {
      _originalDesc = newDescription;
      _updateTask({'desc': newDescription});
    }
  }

  void _saveNameChanges() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _nameController.text = _originalName;
      return;
    }
    if (newName != _originalName) {
      _originalName = newName;
      _updateTask({'name': newName});
    }
  }

  void _updateTask(Map<String, dynamic> updates) {
    final updatedTask = Map<String, dynamic>.from(widget.taskItem);
    updatedTask.addAll(updates);
    updatedTask['updatedAt'] = DateTime.now().toIso8601String();
    widget.onTaskUpdate?.call(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildBody(context),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(FluentIcons.cancel),
            onPressed: widget.onClose,
          ),
          SizedBox(width: 16.0),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final scrollController = ScrollController();
    return Expanded(
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameSection(context),
              
              widget.isActivityItem ? Container() :  SizedBox(height: 24),
              widget.isActivityItem ? Container() : _buildStartActionSection(context),

               const SizedBox(height: 24),
              _buildMoveActionSection(context),
             

              // 专注数组（计划专注数 + 完成专注数）
              const SizedBox(height: 24),
              _buildFocusSection(context),
              

              // 任务详情（使用Expander）
              const SizedBox(height: 24),
              _buildDescSection(context),
              

              // 时间组（修改时间 + 完成时间）
              const SizedBox(height: 24),
              _buildTimeSection(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatusArea(context),
          const Spacer(),
          if (widget.onDelete != null)
            IconButton(
              onPressed: () => _showDeleteConfirmDialog(context),
              icon: Icon(FluentIcons.delete, size: 16),
            ),
        ],
      ),
    );
  }

  // 构建任务名称组
  Widget _buildNameSection(BuildContext context) {
    final taskNameRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Column(
            children: [
              SizedBox(height: 6.0),
              HoverCheckbox(
                value: _isCompleted,
                onChanged: (value) {
                  setState(() {
                    _isCompleted = value ?? false;
                    _status = _isCompleted
                        ? 'completed'
                        : (_completedFocusCount > 0 ? 'active' : 'pending');
                  });
                  _updateTask({
                    'status': _status,
                    if (_isCompleted)
                      'completedAt': DateTime.now().toIso8601String(),
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextBox(
            padding: EdgeInsets.all(0),
            controller: _nameController,
            focusNode: _nameFocusNode,
            maxLines: null,
            textInputAction: TextInputAction.done,
            onEditingComplete: () {
              final value = _nameController.text;
              _nameFocusNode.unfocus();
              if (value.trim() != _originalName) {
                _updateTask({'name': value.trim()});
                _originalName = value.trim();
              }
            },
            style: TextStyle(
              decoration: _isCompleted ? TextDecoration.lineThrough : null,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
            decoration: WidgetStateProperty.all(
              const BoxDecoration(
                color: Colors.transparent,
                border: Border.fromBorderSide(BorderSide.none),
              ),
            ),
            unfocusedColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ),
      ],
    );

    final taskTypeRow = Row(
      children: [
        const SizedBox(width: 2.0),
        Icon(
          widget.isActivityItem
              ? FluentIcons.group_list
              : FluentIcons.favorite_list,
          size: 14,
          color: FluentTheme.of(context).inactiveColor,
        ),
        const SizedBox(width: 10.0),
        Text(
          widget.isActivityItem ? '活动清单任务' : '专注清单任务',
          style: TextStyle(
            fontSize: 14,
            color: FluentTheme.of(context).inactiveColor,
          ),
        ),
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [taskNameRow, const SizedBox(height: 16.0), taskTypeRow],
    );

    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setSectionState) {
        return MouseRegion(
          onEnter: (_) => setSectionState(() {
            isHovered = true;
          }),
          onExit: (_) => setSectionState(() {
            isHovered = false;
          }),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHovered
                  ? FluentTheme.of(context).cardColor.withValues(alpha: 0.1)
                  : FluentTheme.of(context).cardColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: FluentTheme.of(
                  context,
                ).resources.dividerStrokeColorDefault,
                width: 1,
              ),
            ),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buidPlannedFocusFlyout(BuildContext context) {
    // 获取触发器的宽度
    final RenderBox? renderBox =
        _menuFoucsSelectAttachKey.currentContext?.findRenderObject()
            as RenderBox?;
    final double targetWidth = renderBox?.size.width ?? 200;

    return MenuFlyout(
      constraints: BoxConstraints(minWidth: targetWidth, maxWidth: targetWidth),
      items: [
        ...List.generate(
          5,
          (index) => MenuFlyoutItem(
            text: Text(_getFocusCountText(index + 1, false)),
            onPressed: () {
              setState(() {
                _plannedFocusCount = index + 1;
              });
              _updateTask({'plannedFocusCount': _plannedFocusCount});
            },
          ),
        ),
        const MenuFlyoutSeparator(),
        MenuFlyoutItem(
          //leading: const Icon(FluentIcons.undo),
          text: const Text('不设置'),
          onPressed: () {
            setState(() {
              _plannedFocusCount = 0;
            });
            _updateTask({'plannedFocusCount': _plannedFocusCount});
            //Flyout.of(context).close();
          },
        ),
      ],
    );
  }

  Widget _buildFocusSection(BuildContext context) {
    int hoverStatus = 0; // 0: 未划过，1: 划过计划专注数，2: 划过已完成专注数。
    bool plannedFoucsAreaTapped = false;

    final plannedFoucsAreaBuider = StatefulBuilder(
      builder: (context, setAreaState) {
        return MouseRegion(
          onEnter: (_) => setAreaState(() {
            hoverStatus = 1;
          }),
          onExit: (_) => setAreaState(() {
            hoverStatus = 0;
          }),
          child: GestureDetector(
            onTap: () {
              setAreaState(() {
                plannedFoucsAreaTapped = true;
              });
              _menuFoucsSelectController
                  .showFlyout(
                    autoModeConfiguration: FlyoutAutoConfiguration(
                      preferredMode: FlyoutPlacementMode.bottomCenter,
                    ),
                    barrierColor: Colors.transparent,
                    builder: _buidPlannedFocusFlyout,
                  )
                  .then((_) {
                    // Flyout关闭后恢复按钮状态
                    setAreaState(() {
                      plannedFoucsAreaTapped = false;
                    });
                  });
            },
            child: FlyoutTarget(
              key: _menuFoucsSelectAttachKey,
              controller: _menuFoucsSelectController,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hoverStatus == 1 || plannedFoucsAreaTapped
                      ? FluentTheme.of(context).cardColor.withValues(alpha: 0.1)
                      : FluentTheme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(4),
                ),

                child: Row(
                  children: [
                    Icon(
                      FluentIcons.bullseye,
                      size: 18,
                      color: hoverStatus == 1 || plannedFoucsAreaTapped
                          ? FluentTheme.of(context).accentColor.normal
                          : FluentTheme.of(context).inactiveColor,
                    ),
                    const SizedBox(width: 10),
                    hoverStatus == 1 || plannedFoucsAreaTapped
                        ? Text(
                            '设置计划的专注数',
                            style: TextStyle(
                              fontSize: 14,
                              color: FluentTheme.of(context).accentColor.normal,
                            ),
                          )
                        : Text(
                            '计划专注数',
                            style: TextStyle(
                              fontSize: 14,
                              color: FluentTheme.of(context).inactiveColor,
                            ),
                          ),
                    hoverStatus == 1 || plannedFoucsAreaTapped
                        ? SizedBox.shrink()
                        : Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _getFocusCountText(_plannedFocusCount, false),
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                    SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final completedFoucsAreaBuider = StatefulBuilder(
      builder: (context, setAreaState) {
        return MouseRegion(
          onEnter: (_) => setAreaState(() {
            hoverStatus = 2;
          }),
          onExit: (_) => setAreaState(() {
            hoverStatus = 0;
          }),

          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hoverStatus == 2
                  ? FluentTheme.of(context).cardColor.withValues(alpha: 0.1)
                  : FluentTheme.of(context).cardColor,
              borderRadius: BorderRadius.circular(4),
            ),

            child: Row(
              children: [
                Icon(
                  FluentIcons.completed12,
                  size: 18,
                  color: FluentTheme.of(context).inactiveColor,
                ),
                const SizedBox(width: 10),
                Text('完成专注数'),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _getFocusCountText(_completedFocusCount, true),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [plannedFoucsAreaBuider, Divider(), completedFoucsAreaBuider],
      ),
    );
  }

  // 构建任务详情组
  Widget _buildDescSection(BuildContext context) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        // Header widget
        Widget headerWidget = MouseRegion(
          onEnter: (_) => setState(() {
            isHovered = true;
          }),
          onExit: (_) => setState(() {
            isHovered = false;
          }),
          child: Container(
            padding: EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: isHovered
                  ? FluentTheme.of(context).cardColor.withValues(alpha: 0.1)
                  : FluentTheme.of(context).cardColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                SizedBox(width: 12),
                Icon(
                  FluentIcons.info,
                  size: 18,
                  color: isHovered
                      ? FluentTheme.of(context).accentColor.normal
                      : FluentTheme.of(context).inactiveColor,
                ),
                const SizedBox(width: 10),
                Text(
                  '任务详情',
                  style: TextStyle(
                    fontSize: 14,
                    color: isHovered
                        ? FluentTheme.of(context).accentColor.normal
                        : FluentTheme.of(context).inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        );

        // Content widget
        Widget contentWidget = Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextBox(
            padding: EdgeInsets.all(0),
            placeholder: '输入任务描述...',
            controller: _descController,
            focusNode: _descFocusNode,
            maxLines: null,
            textInputAction: TextInputAction.done,
            onEditingComplete: () {
              final value = _descController.text;
              _descFocusNode.unfocus();
              if (value.trim() != _originalDesc) {
                _updateTask({'desc': value.trim()});
                _originalDesc = value.trim();
              }
            },
            style: TextStyle(fontSize: 14),
            decoration: WidgetStateProperty.all(
              const BoxDecoration(
                color: Colors.transparent,
                border: Border.fromBorderSide(BorderSide.none),
              ),
            ),
            unfocusedColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        );

        return PpExpander(
          contentPadding: EdgeInsets.all(0),
          header: headerWidget,
          content: contentWidget,
          onStateChanged: (value) {
            if (value == true) {
              // 延迟一帧确保TextBox已经渲染完成
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _descFocusNode.requestFocus();
              });
            }
          },
        );
      },
    );
  }

  Widget _buildTimeArea(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: FluentTheme.of(context).inactiveColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: FluentTheme.of(context).inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  // 构建时间组
  Widget _buildTimeSection(BuildContext context) {
    final createdAt =
        DateTime.tryParse(widget.taskItem['createdAt'] ?? '') ?? DateTime.now();
    final updatedAt = DateTime.tryParse(widget.taskItem['updatedAt'] ?? '');
    final completedAt = DateTime.tryParse(widget.taskItem['completedAt'] ?? '');
    final hasBeenModified =
        updatedAt != null &&
        updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeArea(
            context,
            FluentIcons.add_event,
            '创建于 ${_formatDateTime(createdAt)}',
          ),
          hasBeenModified ? Divider() : Container(),
          hasBeenModified
              ? _buildTimeArea(
                  context,
                  FluentIcons.edit_event,
                  '更新于 ${_formatDateTime(updatedAt)}',
                )
              : Container(),
          completedAt != null ? Divider() : Container(),
          completedAt != null
              ? _buildTimeArea(
                  context,
                  FluentIcons.confirm_event,
                  '完成于 ${_formatDateTime(completedAt)}',
                )
              : Container(),
        ],
      ),
    );
  }

  // 构建状态组
  Widget _buildStatusArea(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 16,
          width: 4,
          decoration: BoxDecoration(
            color: switch (_status) {
              'pending' => Colors.yellow.lighter,
              'active' => Colors.blue.lighter,
              'completed' => Colors.green.lighter,
              _ => Colors.red.normal,
            },
          ),
        ),
        const SizedBox(width: 6),
        Text(
          switch (_status) {
            'pending' => '待处理',
            'active' => '进行中',
            'completed' => '已完成',
            _ => '出错',
          },
          style: TextStyle(
            fontSize: 14,
            color: FluentTheme.of(context).inactiveColor,
          ),
        ),
      ],
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('删除任务'),
        content: Text('将永久删除"${widget.taskItem['name'] ?? '未知任务'}"。'),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 获取专注数文本
  String _getFocusCountText(int count, bool isCompleted) {
    if (count == 0 && !isCompleted) {
      return '未设置';
    }
    return '🍅 × $count';
    //return '🍅' * count;
  }

  // 格式化日期时间
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 构建操作行
  Widget _buildMoveActionSection(BuildContext context) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setSectionState) {
        return MouseRegion(
          onEnter: (_) => setSectionState(() {
            isHovered = true;
          }),
          onExit: (_) => setSectionState(() {
            isHovered = false;
          }),
          child: GestureDetector(
            onTap: widget.onMoveToOtherList!,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHovered
                    ? FluentTheme.of(context).cardColor.withValues(alpha: 0.1)
                    : FluentTheme.of(context).cardColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: FluentTheme.of(
                    context,
                  ).resources.dividerStrokeColorDefault,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isActivityItem
                        ? FluentIcons.navigate_forward
                        : FluentIcons.navigate_back,
                    size: 18,
                    color: isHovered
                        ? FluentTheme.of(context).accentColor
                        : FluentTheme.of(
                            context,
                          ).inactiveColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.isActivityItem ? '移动至专注列表' : '移回至活动列表',
                    style: TextStyle(
                      color: isHovered
                          ? FluentTheme.of(context).accentColor
                          : FluentTheme.of(
                            context,
                          ).inactiveColor,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartActionSection(BuildContext context) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setSectionState) {
        return MouseRegion(
          onEnter: (_) => setSectionState(() {
            isHovered = true;
          }),
          onExit: (_) => setSectionState(() {
            isHovered = false;
          }),
          child: GestureDetector(
            //onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHovered
                    ? FluentTheme.of(context).cardColor.withValues(alpha: 0.1)
                    : FluentTheme.of(context).cardColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: FluentTheme.of(
                    context,
                  ).resources.dividerStrokeColorDefault,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.m_s_n_videos,
                    size: 18,
                    color: isHovered
                        ? FluentTheme.of(context).accentColor
                        : FluentTheme.of(
                            context,
                          ).inactiveColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '开始执行专注',
                    style: TextStyle(
                      color: isHovered
                          ? FluentTheme.of(context).accentColor
                          : FluentTheme.of(
                            context,
                          ).inactiveColor,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}