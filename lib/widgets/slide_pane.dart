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
  
  const SlidePaneConfig({
    this.width = 360.0,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeOutCubic,
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.headerBackgroundColor = const Color(0xFFFFFFFF),
    this.headerTextColor = const Color(0xFF1F2937),
    this.footerBackgroundColor = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFFE5E7EB),
    this.shadowColor = const Color(0x0F000000),
    this.overlayColor = const Color(0x40000000),
    this.overlayOpacity = 0.4,
    this.responsiveBreakpoint = 1200.0,
    this.showScrollbar = false,
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
  
  /// 自定义头部组件
  final Widget? header;
  
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
    this.header,
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
        // 遮罩层（当面板打开时，仅在小屏幕显示）
        // 将遮罩层放在前面，这样面板内容可以覆盖它
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
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: widget.config.shadowColor,
                      //     blurRadius: 24,
                      //     offset: const Offset(-8, 0),
                      //   ),
                      // ],
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
      ],
    );
  }

  Widget _buildHeader() {
    // 如果有自定义header，直接使用
    if (widget.header != null) {
      return widget.header!;
    }
    
    // 否则返回空的Container
    return const SizedBox.shrink();
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

/// 滑动面板布局组件，用于在页面中集成侧边栏
class SlideLayout extends StatefulWidget {
  /// 主要内容
  final Widget mainContent;
  
  /// 侧边栏配置
  final SlidePaneConfig config;
  
  /// 侧边栏内容构建器
  final Widget Function(BuildContext context, VoidCallback closePane) paneBuilder;
  
  /// 是否显示侧边栏
  final bool isVisible;
  
  /// 面板状态变化回调
  final ValueChanged<bool>? onVisibilityChanged;
  
  const SlideLayout({
    super.key,
    required this.mainContent,
    required this.paneBuilder,
    this.config = const SlidePaneConfig(),
    this.isVisible = false,
    this.onVisibilityChanged,
  });

  @override
  State<SlideLayout> createState() => _SlideLayoutState();
}

class _SlideLayoutState extends State<SlideLayout> {
  void _closePane() {
    widget.onVisibilityChanged?.call(false);
  }

  bool _isLargeScreen() {
    return MediaQuery.of(context).size.width > widget.config.responsiveBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = _isLargeScreen();
    
    return material.Scaffold(
      body: isLargeScreen && widget.isVisible
          ? Row(
              children: [
                // 主内容区域
                Expanded(
                  child: widget.mainContent,
                ),
                // 侧边栏
                Container(
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
                  child: widget.paneBuilder(context, _closePane),
                ),
              ],
            )
          : Stack(
              children: [
                // 主内容区域
                SizedBox(
                  width: double.infinity,
                  child: widget.mainContent,
                ),
                
                // 侧边栏
                SlidePane(
                  isVisible: widget.isVisible,
                  config: widget.config,
                  content: widget.paneBuilder(context, _closePane),
                  onClose: _closePane,
                  onOverlayTap: _closePane,
                ),
              ],
            ),
    );
  }




}