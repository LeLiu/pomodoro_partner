import 'package:fluent_ui/fluent_ui.dart';
import '../widgets/hover_checkbox.dart';

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
  late FocusNode _nameFocusNode;
  late String _originalName;
  late bool _isCompleted;
  late int _plannedFocusCount;
  late int _completedFocusCount;
  late String _status;

  @override
  void initState() {
    super.initState();
    _originalName = widget.taskItem['name'] ?? '未知任务';
    _nameController = TextEditingController(text: _originalName);
    _nameFocusNode = FocusNode();
    _isCompleted = widget.taskItem['status'] == 'completed';
    _plannedFocusCount = widget.taskItem['plannedFocusCount'] ?? 0;
    _completedFocusCount = widget.taskItem['completedFocusCount']?? 0;
    _status = widget.taskItem['status'] ?? 'pending';
    
    _nameFocusNode.addListener(_onNameFocusChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.removeListener(_onNameFocusChanged);
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onNameFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      _saveNameChanges();
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
      decoration: BoxDecoration(
        //color: FluentTheme.of(context).scaffoldBackgroundColor,
        //color: Colors.red.lighter,
      ),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            //icon: const Icon(Icons.close_outlined, size :16),
            icon: const Icon(FluentIcons.cancel),
            onPressed: widget.onClose,
          ),
          SizedBox(width: 8,)
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final createdAt =
        DateTime.tryParse(widget.taskItem['createdAt'] ?? '') ?? DateTime.now();
    final updatedAt = DateTime.tryParse(widget.taskItem['updatedAt'] ?? '');
    final hasBeenModified =
        updatedAt != null &&
        updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));
    final completedAt = DateTime.tryParse(widget.taskItem['completedAt'] ?? '');

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务名称组（HoverCheckbox + 可编辑文本）
            _buildNameSection(context),
            const SizedBox(height: 24),

            // 专注数组（计划专注数 + 完成专注数）
            _buildFocusSection(context),
            const SizedBox(height: 24),

            // 任务详情（使用Expander）
            _buildDetailsSection(context),
            const SizedBox(height: 24),

            // 时间组（修改时间 + 完成时间）
            _buildTimeSection(context, createdAt, updatedAt, completedAt, hasBeenModified),
            const SizedBox(height: 24),

            // 状态
            _buildStatusSection(context),
            const SizedBox(height: 16),

            // 移动到其他列表
            if (widget.onMoveToOtherList != null)
              _buildActionRow(
                context,
                widget.isActivityItem ? FluentIcons.move_to_folder : FluentIcons.back,
                widget.isActivityItem ? '移动到专注列表' : '移回至活动列表',
                widget.onMoveToOtherList!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        border: Border(
          top: BorderSide(
            color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (widget.onDelete != null)
            Button(
              onPressed: () => _showDeleteConfirmDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.delete, size: 16),
                  const SizedBox(width: 8),
                  Text('删除'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 构建任务名称组
  Widget _buildNameSection(BuildContext context) {
    return Row(
      children: [
        HoverCheckbox(
          value: _isCompleted,
          onChanged: (value) {
            setState(() {
              _isCompleted = value ?? false;
              _status = _isCompleted ? 'completed' : (_completedFocusCount > 0 ? 'active' : 'pending');
            });
            _updateTask({
              'status': _status,
              if (_isCompleted) 'completedAt': DateTime.now().toIso8601String(),   
            });
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextBox(
            controller: _nameController,
            focusNode: _nameFocusNode,
            style: TextStyle(
              decoration: _isCompleted ? TextDecoration.lineThrough : null,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // 构建专注数组
  Widget _buildFocusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '专注数',
          style: FluentTheme.of(context).typography.bodyStrong,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '计划专注数',
                    style: FluentTheme.of(context).typography.body,
                  ),
                  const SizedBox(height: 8),
                  ComboBox<int>(
                    value: _plannedFocusCount,
                    items: List.generate(7, (index) => ComboBoxItem(
                      value: index,
                      child: Text(_getFocusCountText(index)),
                    )),
                    onChanged: (value) {
                      setState(() {
                        _plannedFocusCount = value ?? 0;
                      });
                      _updateTask({'plannedFocusCount': _plannedFocusCount});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '完成专注数',
                    style: FluentTheme.of(context).typography.body,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getCompletedFocusText(widget.taskItem['completedFocusCount'] ?? 0),
                      style: FluentTheme.of(context).typography.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 构建任务详情组
  Widget _buildDetailsSection(BuildContext context) {
    return Expander(
      header: Text('任务详情'),
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.taskItem['desc']?.isNotEmpty == true 
              ? widget.taskItem['desc'] 
              : '暂无详情',
          style: FluentTheme.of(context).typography.body,
        ),
      ),
      initiallyExpanded: true,
    );
  }

  // 构建时间组
  Widget _buildTimeSection(BuildContext context, DateTime createdAt, DateTime? updatedAt, DateTime? completedAt, bool hasBeenModified) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '时间信息',
          style: FluentTheme.of(context).typography.bodyStrong,
        ),
        const SizedBox(height: 12),
        // 创建时间
        Row(
          children: [
            Icon(
              FluentIcons.calendar,
              size: 16,
              color: FluentTheme.of(context).typography.caption?.color,
            ),
            const SizedBox(width: 8),
            Text(
              '创建于 ${_formatDateTime(createdAt)}',
              style: FluentTheme.of(context).typography.caption,
            ),
          ],
        ),
        // 修改时间
        if (hasBeenModified) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                FluentIcons.edit,
                size: 16,
                color: FluentTheme.of(context).typography.caption?.color,
              ),
              const SizedBox(width: 8),
              Text(
                '修改于 ${_formatDateTime(updatedAt!)}',
                style: FluentTheme.of(context).typography.caption,
              ),
            ],
          ),
        ],
        // 完成时间
        if (completedAt != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                FluentIcons.check_mark,
                size: 16,
                color: FluentTheme.of(context).typography.caption?.color,
              ),
              const SizedBox(width: 8),
              Text(
                '完成于 ${_formatDateTime(completedAt)}',
                style: FluentTheme.of(context).typography.caption,
              ),
            ],
          ),
        ],
      ],
    );
  }

  // 构建状态组
  Widget _buildStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '状态',
          style: FluentTheme.of(context).typography.bodyStrong,
        ),
        const SizedBox(height: 8),
        ComboBox<String>(
          value: _status,
          items: const [
            ComboBoxItem(value: 'pending', child: Text('未开始')),
            ComboBoxItem(value: 'active', child: Text('进行中')),
            ComboBoxItem(value: 'completed', child: Text('已完成')),
          ],
          onChanged: (value) {
            setState(() {
              _status = value ?? 'pending';
              _isCompleted = _status == 'completed';
            });
            final updates = {'status': _status};
            if (_status == 'completed' && widget.taskItem['completedAt'] == null) {
              updates['completedAt'] = DateTime.now().toIso8601String();
            }
            _updateTask(updates);
          },
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
  String _getFocusCountText(int count) {
    if (count == 0) {
      return '未选择';
    }
    return '🍅 × $count';
  }

  // 获取完成专注数文本
  String _getCompletedFocusText(int count) {
    return '🍅 × $count';
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 构建操作行
  Widget _buildActionRow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).cardColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: FluentTheme.of(context).accentColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: FluentTheme.of(context).accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              FluentIcons.chevron_right,
              size: 14,
              color: FluentTheme.of(context).typography.caption?.color,
            ),
          ],
        ),
      ),
    );
  }
}
