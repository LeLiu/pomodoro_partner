import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart';

/// 侧边栏配置类
class SlidePaneConfig {
  /// 面板宽度
  final double width;
  
  /// 动画持续时间
  final Duration animationDuration;
  
  /// 动画曲线
  final Curve animationCurve;
  
  /// 面板背景色
  final Color backgroundColor;
  
  /// 头部背景色
  final Color headerBackgroundColor;
  
  /// 头部文字颜色
  final Color headerTextColor;
  
  /// 底部背景色
  final Color footerBackgroundColor;
  
  /// 边框颜色
  final Color borderColor;
  
  /// 阴影颜色
  final Color shadowColor;
  
  /// 遮罩层颜色
  final Color overlayColor;
  
  /// 遮罩层透明度
  final double overlayOpacity;
  
  /// 响应式断点（大于此宽度时为大屏幕）
  final double responsiveBreakpoint;
  
  /// 是否显示滚动条
  final bool showScrollbar;
  
  /// 头部图标
  final IconData? headerIcon;
  
  /// 头部标题
  final String headerTitle;
  
  /// 是否显示关闭按钮
  final bool showCloseButton;
  
  const SlidePaneConfig({
    this.width = 350.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.headerBackgroundColor = const Color(0xFF1E40AF),
    this.headerTextColor = const Color(0xFFFFFFFF),
    this.footerBackgroundColor = const Color(0xFFF8FAFC),
    this.borderColor = const Color(0xFFE2E8F0),
    this.shadowColor = const Color(0x1A1E293B),
    this.overlayColor = const Color(0x40000000),
    this.overlayOpacity = 0.3,
    this.responsiveBreakpoint = 1200.0,
    this.showScrollbar = true,
    this.headerIcon,
    this.headerTitle = '面板',
    this.showCloseButton = true,
  });
}

/// 可重复使用的滑出侧边栏控件
class SlidePane extends StatefulWidget {
  /// 是否显示面板
  final bool isVisible;
  
  /// 面板配置
  final SlidePaneConfig config;
  
  /// 面板内容
  final Widget content;
  
  /// 面板底部内容（可选）
  final Widget? footer;
  
  /// 关闭回调
  final VoidCallback? onClose;
  
  /// 遮罩层点击回调
  final VoidCallback? onOverlayTap;
  
  const SlidePane({
    super.key,
    required this.isVisible,
    required this.content,
    this.config = const SlidePaneConfig(),
    this.footer,
    this.onClose,
    this.onOverlayTap,
  });

  @override
  State<SlidePane> createState() => _SlidePaneState();
}

class _SlidePaneState extends State<SlidePane> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0, // 完全隐藏在右侧
      end: 0.0,   // 完全显示
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.config.animationCurve,
    ));
    
    // 根据初始状态设置动画
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SlidePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 当可见性改变时，播放动画
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > widget.config.responsiveBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = _isLargeScreen(context);
    
    return Stack(
      children: [
        // 右侧滑出面板
        if (widget.isVisible || (isLargeScreen && widget.isVisible))
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: isLargeScreen ? Offset.zero : Offset(_slideAnimation.value * widget.config.width, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: widget.config.width,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.config.backgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: widget.config.shadowColor,
                          blurRadius: 24,
                          offset: const Offset(-8, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 面板头部
                        _buildHeader(),
                        
                        // 面板内容
                        Expanded(
                          child: widget.config.showScrollbar
                              ? Scrollbar(
                                  thumbVisibility: true,
                                  child: widget.content,
                                )
                              : widget.content,
                        ),
                        
                        // 面板底部
                        if (widget.footer != null) _buildFooter(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        
        // 遮罩层（当面板打开时，仅在小屏幕显示）
        if (widget.isVisible && !isLargeScreen)
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: (1.0 - _slideAnimation.value) * widget.config.overlayOpacity,
                child: GestureDetector(
                  onTap: widget.onOverlayTap ?? widget.onClose,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: widget.config.overlayColor,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.config.headerBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.config.headerIcon != null) ...[
            Icon(
              widget.config.headerIcon!,
              color: widget.config.headerTextColor,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Text(
            widget.config.headerTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.config.headerTextColor,
            ),
          ),
          const Spacer(),
          if (widget.config.showCloseButton && widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: Icon(
                FluentIcons.chrome_close,
                color: widget.config.headerTextColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.config.footerBackgroundColor,
        border: Border(
          top: BorderSide(
            color: widget.config.borderColor,
            width: 1,
          ),
        ),
      ),
      child: widget.footer!,
    );
  }
}

/// 侧边栏管理器，用于在页面中集成侧边栏
class SlidePaneManager extends StatefulWidget {
  /// 主要内容
  final Widget child;
  
  /// 侧边栏配置
  final SlidePaneConfig config;
  
  /// 侧边栏内容构建器
  final Widget Function(BuildContext context, VoidCallback closePane) contentBuilder;
  
  /// 侧边栏底部内容构建器（可选）
  final Widget Function(BuildContext context, VoidCallback closePane)? footerBuilder;
  
  /// 初始是否显示侧边栏
  final bool initiallyVisible;
  
  /// 全局侧边栏管理器实例
  static _SlidePaneManagerState? _globalInstance;
  
  const SlidePaneManager({
    super.key,
    required this.child,
    required this.contentBuilder,
    this.config = const SlidePaneConfig(),
    this.footerBuilder,
    this.initiallyVisible = false,
  });

  @override
  State<SlidePaneManager> createState() => _SlidePaneManagerState();
  
  /// 切换侧边栏显示状态
  static void togglePane() {
    _globalInstance?._togglePane();
  }
  
  /// 显示侧边栏
  static void showPane() {
    if (_globalInstance != null && !_globalInstance!._showPane) {
      _globalInstance!._togglePane();
    }
  }
  
  /// 隐藏侧边栏
  static void hidePane() {
    if (_globalInstance != null && _globalInstance!._showPane) {
      _globalInstance!._closePane();
    }
  }
  
  /// 检查侧边栏是否可见
  static bool get isPaneVisible {
    return _globalInstance?._showPane ?? false;
  }
}

class _SlidePaneManagerState extends State<SlidePaneManager> {
  late bool _showPane;

  @override
  void initState() {
    super.initState();
    _showPane = widget.initiallyVisible;
    // 注册为全局实例
    SlidePaneManager._globalInstance = this;
  }
  
  @override
  void dispose() {
    // 清理全局实例
    if (SlidePaneManager._globalInstance == this) {
      SlidePaneManager._globalInstance = null;
    }
    super.dispose();
  }

  void _togglePane() {
    setState(() {
      _showPane = !_showPane;
    });
  }

  void _closePane() {
    setState(() {
      _showPane = false;
    });
  }

  bool _isLargeScreen() {
    return MediaQuery.of(context).size.width > widget.config.responsiveBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = _isLargeScreen();
    
    return material.Scaffold(
      body: Stack(
        children: [
          // 主内容区域
          SizedBox(
            width: isLargeScreen && _showPane 
                ? MediaQuery.of(context).size.width - widget.config.width 
                : double.infinity,
            child: widget.child,
          ),
          
          // 侧边栏
          SlidePane(
            isVisible: _showPane,
            config: widget.config,
            content: widget.contentBuilder(context, _closePane),
            footer: widget.footerBuilder?.call(context, _closePane),
            onClose: _closePane,
            onOverlayTap: _closePane,
          ),
        ],
      ),
    );
  }
  
  /// 切换侧边栏显示状态
  void togglePane() => _togglePane();
  
  /// 获取当前侧边栏是否显示
  bool get isPaneVisible => _showPane;
}