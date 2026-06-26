import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../l10n/strings_fa.dart';
import 'persian_utils.dart';

class TimerWidget extends StatelessWidget {
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onChangeIssue;

  const TimerWidget({super.key, this.onStart, this.onStop, this.onChangeIssue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<TimerProvider>(
      builder: (context, timer, _) {
        final display = PersianUtils.formatPersianDuration(timer.elapsedSeconds);
        return Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: timer.isRunning
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        const Color(0xFFD4731A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (timer.isPaused
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF5B5B5B),
                            const Color(0xFF3A3A3A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                            theme.colorScheme.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      timer.isPaused ? Icons.pause_rounded : Icons.timer,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timer.isPaused ? 'متوقف' : (timer.isRunning ? AppStrings.stopTimer : AppStrings.startTimer),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Vazir'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  display,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Vazir',
                    letterSpacing: 2,
                  ),
                ),
                if (timer.activeIssue != null) ...[
                  const SizedBox(height: 6),
                  _buildIssueChip(context, timer),
                ],
                const SizedBox(height: 16),
                if (!timer.isRunning && !timer.isPaused)
                  _buildStartButton(context, timer)
                else
                  _buildRunningActions(context, timer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton(BuildContext context, TimerProvider timer) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text(
          AppStrings.startTimer,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildRunningActions(BuildContext context, TimerProvider timer) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: Text(
                AppStrings.stopTimer,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDA3633),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => timer.togglePause(),
              icon: Icon(
                timer.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 20,
              ),
              label: Text(
                timer.isPaused ? 'ادامه' : 'توقف موقت',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Vazir'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: timer.isPaused
                    ? const Color(0xFF2DA44E)
                    : Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssueChip(BuildContext context, TimerProvider timer) {
    return InkWell(
      onTap: timer.isRunning ? onChangeIssue : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              timer.activeIssue!.key,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Vazir'),
            ),
            if (timer.isRunning) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 11, color: Colors.white.withValues(alpha: 0.6)),
            ],
          ],
        ),
      ),
    );
  }
}
