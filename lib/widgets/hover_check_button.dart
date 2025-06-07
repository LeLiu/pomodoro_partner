import 'package:flutter/material.dart';

class HoverIconButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isSelected;
  final Icon normalIcon;
  final Icon hoverIcon;
  final Icon selectedIcon;

  const HoverIconButton(
      {super.key,
      required this.isSelected,
      required this.onPressed,
      required this.normalIcon,
      required this.hoverIcon,
      required this.selectedIcon});

  @override
  _HoverIconButtonState createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true), // 鼠标进入
      onExit: (_) => setState(() => _isHovering = false), // 鼠标离开
      child: IconButton(
        icon: _isHovering
            ? widget.hoverIcon 
            : (widget.isSelected
                ? widget.selectedIcon 
                : widget.normalIcon),
        onPressed: widget.onPressed,
      ),
    );
  }
}

            // ? const Icon(Icons.check_circle_outline) // 悬停图标
            // : (widget.isChecked
            //     ? Icon(Icons.check_circle) // 选中图标
            //     : Icon(Icons.circle_outlined)), // 未选中图标