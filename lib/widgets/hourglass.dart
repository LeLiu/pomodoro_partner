import 'dart:math' as math;
import 'package:flutter/material.dart';

class HourglassAnimation extends StatefulWidget {
  final Duration duration;
  final Color color;
  final double size;
  final bool isRunning;
  final double progress;

  const HourglassAnimation({
    super.key,
    this.duration = const Duration(seconds: 60),
    this.color = Colors.red,
    this.size = 240,
    this.isRunning = false,
    this.progress = 0,
  });

  @override
  State<HourglassAnimation> createState() => _HourglassAnimationState();
}

class _HourglassAnimationState extends State<HourglassAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.progress,
    );
    if (widget.isRunning) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(HourglassAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _controller.forward();
      } else {
        _controller.stop();
      }
    }
    if (widget.progress != oldWidget.progress) {
      _controller.value = widget.progress;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: CircularTimerPainter(
            progress: 1 - _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Paint _paint;

  CircularTimerPainter({required this.progress, required this.color})
      : _paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0
          ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    // 绘制背景圆环
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0,
    );

    // 绘制进度圆弧
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 从12点钟方向开始
      2 * math.pi * progress,
      false,
      _paint,
    );
  }

  @override
  bool shouldRepaint(CircularTimerPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}