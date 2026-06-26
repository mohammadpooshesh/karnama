import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jira_issue.dart';
import '../models/jira_config.dart';
import '../providers/timer_provider.dart';
import '../providers/worklog_provider.dart';
import '../providers/settings_provider.dart';
import '../services/jira_service.dart';
import '../l10n/strings_fa.dart';
import '../widgets/timer_widget.dart';
import '../widgets/log_card.dart';
import '../widgets/persian_utils.dart';
import '../widgets/simple_bar_chart.dart';
import 'log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkLogProvider>().loadTodayLogs();
      context.read<WorkLogProvider>().loadWeekStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.dashboard,
                style: theme.textTheme.headlineSmall,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(AppStrings.today,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<TimerProvider>(
            builder: (context, timer, _) => TimerWidget(
              onStart: () => _showIssuePicker(context),
              onStop: () => _stopTimerAndSave(context),
              onChangeIssue: () => _showChangeIssuePicker(context, timer),
            ),
          ),
          const SizedBox(height: 16),
          Consumer2<TimerProvider, WorkLogProvider>(
            builder: (context, timer, wl, _) {
              if (!timer.isRunning && wl.lastIssueKey != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final key = wl.lastIssueKey;
                        if (key != null) {
                          timer.startTimer(issue: JiraIssue(
                            jiraId: '',
                            projectKey: '',
                            key: key,
                            summary: '',
                          ));
                        }
                      },
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: Text('ادامه آخرین تایمر (${wl.lastIssueKey})'),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Consumer<WorkLogProvider>(
            builder: (context, provider, _) {
              final todaySeconds = provider.todayLogs.fold<int>(
                0, (sum, log) => sum + log.durationSeconds);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.access_time, size: 20,
                            color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.totalToday,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 4),
                          Text(
                            PersianUtils.formatPersianDuration(todaySeconds),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Vazir',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Consumer<WorkLogProvider>(
            builder: (context, provider, _) {
              if (provider.weekStats.isEmpty) return const SizedBox.shrink();
              final todaySeconds = provider.todayLogs.fold<int>(0,
                  (sum, log) => sum + log.durationSeconds);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('آمار هفتگی', style: theme.textTheme.titleLarge),
                          Row(
                            children: [
                              _statChip(theme, 'امروز',
                                  PersianUtils.formatPersianDuration(todaySeconds)),
                              const SizedBox(width: 8),
                              _statChip(theme, 'دیروز',
                                  PersianUtils.formatPersianDuration(provider.yesterdayTotal)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: SimpleBarChart(
                          data: provider.weekStats.map((s) => BarData(
                            label: s.label,
                            value: s.seconds.toDouble() / 3600,
                          )).toList(),
                          barWidth: 26,
                        ),
                      ),
                      if (provider.topTaskKey != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.emoji_events, size: 14,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text('تسک برتر: ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                            Text(provider.topTaskKey!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.history, style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  DefaultTabController.of(context).animateTo(2);
                },
                child: const Text(AppStrings.history),
              ),
            ],
          ),
          Consumer<WorkLogProvider>(
            builder: (context, provider, _) {
              if (provider.todayLogs.isEmpty) {
                return _buildEmptyState(context);
              }
              return Column(
                children: provider.todayLogs.take(5).map((log) => LogCard(
                  log: log,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LogScreen(editLog: log)),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hourglass_empty_rounded,
                  size: 36, color: isDark ? Colors.white24 : Colors.black12),
            ),
            const SizedBox(height: 12),
            Text(AppStrings.noLogs,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black26)),
            const SizedBox(height: 4),
            Text('با شروع تایمر یا ثبت دستی، زمانت رو مدیریت کن',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white24 : Colors.black12)),
          ],
        ),
      ),
    );
  }

  Widget _statChip(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          Text(value,
              style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600, fontFamily: 'Vazir',
                  color: theme.colorScheme.primary)),
        ],
      ),
    );
  }

  void _showIssuePicker(BuildContext context) async {
    await context.read<SettingsProvider>().ready;
    final config = context.read<SettingsProvider>().activeConfig;
    if (config == null) {
      context.read<TimerProvider>().startTimer(issue: null);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _IssuePickerDialog(jiraConfig: config),
    );
  }

  void _showChangeIssuePicker(BuildContext context, TimerProvider timer) async {
    await context.read<SettingsProvider>().ready;
    final config = context.read<SettingsProvider>().activeConfig;
    if (config == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _IssuePickerDialog(jiraConfig: config, isChanging: true),
    );
  }

  void _stopTimerAndSave(BuildContext context) {
    final timer = context.read<TimerProvider>();
    final elapsed = timer.elapsedSeconds;
    if (elapsed < 5) {
      timer.cancelTimer();
      return;
    }
    timer.stopTimer();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LogScreen(
        timerSeconds: elapsed,
        startTime: timer.startTime,
        initialIssue: timer.activeIssue,
      )),
    );
  }
}

class _IssuePickerDialog extends StatefulWidget {
  final JiraConfig jiraConfig;
  final bool isChanging;
  const _IssuePickerDialog({required this.jiraConfig, this.isChanging = false});

  @override
  State<_IssuePickerDialog> createState() => _IssuePickerDialogState();
}

class _IssuePickerDialogState extends State<_IssuePickerDialog> {
  final _searchController = TextEditingController();
  final _jiraService = JiraService();
  List<JiraIssue> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _jiraService.configure(widget.jiraConfig);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      _results = await _jiraService.searchIssuesAll(query: query.trim(), maxResults: 50);
    } catch (_) {
      _results = [];
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.isChanging ? 'تغییر تسک فعال' : 'انتخاب تسک برای تایمر',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'KEY-123 یا بخشی از عنوان...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
              ),
              onChanged: _search,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            if (_results.isNotEmpty)
              SizedBox(
                height: 250,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (ctx, i) {
                    final issue = _results[i];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.task_alt, size: 16,
                            color: theme.colorScheme.primary),
                      ),
                      title: Text('${issue.key} — ${issue.summary}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                      subtitle: issue.status != null
                          ? Text(issue.status!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))
                          : null,
                      onTap: () {
                        if (widget.isChanging) {
                          context.read<TimerProvider>().changeIssue(issue);
                        } else {
                          context.read<TimerProvider>().startTimer(issue: issue);
                        }
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            if (_results.isEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('حداقل ۲ کاراکتر تایپ کنید...',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                context.read<TimerProvider>().startTimer(issue: null);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('شروع بدون تسک'),
            ),
          ],
        ),
      ),
    );
  }
}
