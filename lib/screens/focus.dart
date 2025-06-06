import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../models/timer.dart';
import '../widgets/hourglass.dart';


class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerModel>(
      builder: (context, timer, child) => Column(
        children: [
          const SizedBox(height: 20),
          if (timer.currentTaskName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                timer.currentTaskName!,
                style: FluentTheme.of(context).typography.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < timer.completedSessions % 4 
                    ? FluentTheme.of(context).accentColor
                    : FluentTheme.of(context).resources.subtleFillColorSecondary,
                ),
              )),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: HourglassAnimation(
                    isRunning: timer.isRunning,
                    progress: timer.remainingSeconds / (25 * 60),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimerDisplay(context, timer),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
          _buildControlButtons(context, timer),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(BuildContext context, TimerModel timer) {
    final minutes = (timer.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timer.remainingSeconds % 60).toString().padLeft(2, '0');
    
    return Text(
      '$minutes:$seconds',
      style: FluentTheme.of(context).typography.display?.copyWith(
        fontSize: 60,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, TimerModel timer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!timer.isStarted)
          Column(
            children: [
              Button(
                onPressed: timer.start,
                child: const Icon(FluentIcons.play, size: 32),
              ),
              const SizedBox(height: 8),
              Text('开始', style: FluentTheme.of(context).typography.body),
            ],
          )
        else ...[  
          Column(
            children: [
              Button(
                onPressed: timer.isRunning ? timer.pause : timer.start,
                child: Icon(timer.isRunning ? FluentIcons.pause : FluentIcons.play, size: 32),
              ),
              const SizedBox(height: 8),
              Text(timer.isRunning ? '中断' : '继续', style: FluentTheme.of(context).typography.body),
            ],
          ),
          const SizedBox(width: 32),
          Column(
            children: [
              Button(
                onPressed: timer.reset,
                child: const Icon(FluentIcons.refresh, size: 32),
              ),
              const SizedBox(height: 8),
              Text('取消', style: FluentTheme.of(context).typography.body),
            ],
          ),
        ],
      ],
    );
  }
}