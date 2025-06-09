import 'package:flutter/material.dart' hide Colors, IconButton, Checkbox, ListTile, FilledButton;
import 'package:fluent_ui/fluent_ui.dart';

/// 任务编辑组件
class TaskEditWidget extends StatelessWidget {
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
  
  const TaskEditWidget({
    super.key,
    required this.taskItem,
    required this.isActivityItem,
    this.onMoveToOtherList,
    this.onDelete,
    this.onClose,
  });
  
  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(taskItem['createdAt'] ?? '') ?? DateTime.now();
    final updatedAt = DateTime.tryParse(taskItem['updatedAt'] ?? '');
    final hasBeenModified = updatedAt != null && updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 任务名称
                Text(
                  taskItem['name'] ?? '未知任务',
                  style: FluentTheme.of(context).typography.title,
                ),
                const SizedBox(height: 8),
                // 创建时间
                Row(
                  children: [
                    Icon(
                      FluentIcons.calendar,
                      size: 14,
                      color: FluentTheme.of(context).typography.caption?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '创建于 ${_formatDateTime(createdAt)}',
                      style: FluentTheme.of(context).typography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 计划专注数
                _buildInfoRow(
                  context,
                  FluentIcons.bullseye,
                  '计划专注数',
                  '${taskItem['plannedFocusCount'] ?? 0} 次',
                ),
                const SizedBox(height: 16),
                
                // 完成专注数
                _buildInfoRow(
                  context,
                  FluentIcons.check_mark,
                  '完成专注数',
                  '${taskItem['completedFocusCount'] ?? 0} 次',
                ),
                const SizedBox(height: 16),
                
                // 任务详情
                _buildInfoRow(
                  context,
                  FluentIcons.info,
                  '任务详情',
                  taskItem['desc']?.isNotEmpty == true ? taskItem['desc'] : '暂无详情',
                ),
                const SizedBox(height: 16),
                
                // 移动到其他列表
                if (onMoveToOtherList != null)
                  _buildActionRow(
                    context,
                    isActivityItem ? FluentIcons.move_to_folder : FluentIcons.back,
                    isActivityItem ? '移动到专注列表' : '移回至活动列表',
                    onMoveToOtherList!,
                  ),
                
                // 修改时间（如果有修改）
                if (hasBeenModified) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        FluentIcons.edit,
                        size: 14,
                        color: FluentTheme.of(context).typography.caption?.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '修改于 ${_formatDateTime(updatedAt)}',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // 底部状态栏
        Container(
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
              Text(
                '状态: ${_getStatusText(taskItem['status'])}',
                style: FluentTheme.of(context).typography.body,
              ),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  icon: Icon(FluentIcons.delete, color: Colors.red.normal),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 获取状态文本
  String _getStatusText(dynamic status) {
    switch (status) {
      case 'pending':
        return '未开始';
      case 'active':
        return '进行中';
      case 'completed':
        return '已完成';
      default:
        return '未知状态';
    }
  }

  // 构建信息行
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: FluentTheme.of(context).typography.body?.color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: FluentTheme.of(context).typography.bodyStrong,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: FluentTheme.of(context).typography.body,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建操作行
  Widget _buildActionRow(BuildContext context, IconData icon, String label, VoidCallback onTap) {
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
            Icon(
              icon,
              size: 16,
              color: FluentTheme.of(context).accentColor,
            ),
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