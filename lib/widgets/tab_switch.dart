import 'package:flutter/material.dart' hide Colors;
import 'package:fluent_ui/fluent_ui.dart';

class TabSwitch extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<TabSwitchItem> items;

  const TabSwitch({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  State<TabSwitch> createState() => _TabSwitchState();
}

class _TabSwitchState extends State<TabSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TabSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: theme.menuColor.withAlpha(0xEE),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: theme.menuColor.withAlpha(0xFF),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            // 滑动背景
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: widget.selectedIndex * (240 / widget.items.length) + 2,
              top: 2,
              bottom: 2,
              width: (240 / widget.items.length) - 6,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? FluentTheme.of(context).accentColor.dark
                      : FluentTheme.of(context).accentColor.light,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
            // 按钮行
            Row(
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == widget.selectedIndex;

                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onChanged(index),
                      borderRadius: BorderRadius.circular(2.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 16.0,
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode
                                      ? const Color(0xFFB0B0B0)
                                      : const Color(0xFF666666)),
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDarkMode
                                        ? const Color(0xFFB0B0B0)
                                        : const Color(0xFF666666)),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class TabSwitchItem {
  final String label;
  final IconData icon;

  const TabSwitchItem({
    required this.label,
    required this.icon,
  });
}