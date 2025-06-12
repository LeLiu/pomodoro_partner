import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

class HoverCheckbox extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  final bool value;
  final double iconSize;

  const HoverCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.iconSize = 18,
  });

  @override
  State<HoverCheckbox> createState() => _HoverCheckboxState();
}

class _HoverCheckboxState extends State<HoverCheckbox> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true), // 鼠标进入
      onExit: (_) => setState(() => _isHovering = false), // 鼠标离开
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        child: Icon(
          _getIcon(),
          size: widget.iconSize,
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (widget.value) {
      return fluent.FluentIcons.completed_solid; // 选中时
    } else if (_isHovering) {
      return fluent.FluentIcons.completed; // 划过时
    } else {
      return fluent.FluentIcons.circle_ring; // 未选中
    }
  }
}