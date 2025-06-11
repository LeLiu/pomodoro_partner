import 'package:flutter/material.dart' hide Colors;
import 'package:fluent_ui/fluent_ui.dart';

class TabSwitcher extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<TabSwitcherItem> items;

  const TabSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(TabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 240, // 固定宽度，参考上一版大小
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF2D2D30) // 稍微浅一点的暗色背景
              : const Color(0xFFF8F9FA), // 稍微浅一点的亮色背景
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF404040)
                : const Color(0xFFE1E5E9),
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
              width: (240 / widget.items.length) - 4,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF0078D4) // 蓝色主题色
                      : const Color(0xFF0078D4),
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0078D4).withOpacity(0.2),
                      blurRadius: 3.0,
                      offset: const Offset(0, 1),
                    ),
                  ],
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

class TabSwitcherItem {
  final String label;
  final IconData icon;

  const TabSwitcherItem({
    required this.label,
    required this.icon,
  });
}