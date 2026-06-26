import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/work_log.dart';
import '../models/jira_issue.dart';
import '../providers/worklog_provider.dart';
import '../providers/settings_provider.dart';
import '../services/jira_service.dart';
import '../l10n/strings_fa.dart';
import '../widgets/issue_selector.dart';
import '../widgets/persian_utils.dart';

class LogScreen extends StatefulWidget {
  final WorkLog? editLog;
  final int? timerSeconds;
  final DateTime? startTime;
  final JiraIssue? initialIssue;

  const LogScreen({super.key, this.editLog, this.timerSeconds, this.startTime, this.initialIssue});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _descController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  JiraIssue? _selectedIssue;
  int _hours = 0;
  int _minutes = 0;
  bool _logTypeTimer = false;
  bool _syncToJira = true;
  bool _saving = false;
  JiraService? _jiraService;

  @override
  void initState() {
    super.initState();
    if (widget.editLog != null) {
      final log = widget.editLog!;
      _descController.text = log.description ?? '';
      _hours = log.durationSeconds ~/ 3600;
      _minutes = (log.durationSeconds % 3600) ~/ 60;
      _syncToJira = !log.syncedToJira;
    } else if (widget.timerSeconds != null) {
      _logTypeTimer = true;
      _hours = widget.timerSeconds! ~/ 3600;
      _minutes = (widget.timerSeconds! % 3600) ~/ 60;
      _selectedIssue = widget.initialIssue;
    }
    _hoursController.text = _hours.toString();
    _minutesController.text = _minutes.toString();
    _initJira();
  }

  Future<void> _initJira() async {
    await context.read<SettingsProvider>().ready;
    final config = context.read<SettingsProvider>().activeConfig;
    if (config != null) {
      _jiraService = JiraService();
      _jiraService!.configure(config);
      if (mounted) {
        context.read<WorkLogProvider>().loadJiraProjects(_jiraService!);
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmbedded = widget.editLog == null && widget.timerSeconds == null;
    return Scaffold(
      appBar: isEmbedded ? null : AppBar(
        title: Text(widget.editLog != null ? AppStrings.edit : AppStrings.newLog),
        toolbarHeight: 40,
        centerTitle: true,
        actions: [
          if (_saving)
            const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEmbedded) ...[
              Text(AppStrings.newLog, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
            ],
            Text(AppStrings.logType, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _logTypeButton(AppStrings.timer, true, Icons.timer_outlined),
                const SizedBox(width: 8),
                _logTypeButton(AppStrings.manual, false, Icons.edit_outlined),
              ],
            ),
            const SizedBox(height: 20),
            Text(AppStrings.duration, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    readOnly: _logTypeTimer && widget.timerSeconds != null,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.hours,
                      prefixIcon: const Icon(Icons.schedule, size: 18),
                      isDense: true,
                    ),
                    style: theme.textTheme.bodyLarge,
                    controller: _hoursController,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      _hours = n.clamp(0, 23);
                      if (n != _hours) _hoursController.text = _hours.toString();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    readOnly: _logTypeTimer && widget.timerSeconds != null,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.minutes,
                      isDense: true,
                    ),
                    style: theme.textTheme.bodyLarge,
                    controller: _minutesController,
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      _minutes = n.clamp(0, 59);
                      if (n != _minutes) _minutesController.text = _minutes.toString();
                    },
                  ),
                ),
              ],
            ),
            if (_logTypeTimer && widget.timerSeconds != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.timer, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${PersianUtils.formatPersianDuration(widget.timerSeconds!)} از تایمر',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (_jiraService != null) ...[
              Text(AppStrings.selectIssue, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              IssueSelector(
                jiraService: _jiraService,
                selectedIssue: _selectedIssue,
                onSelected: (issue) => setState(() => _selectedIssue = issue),
              ),
              const SizedBox(height: 20),
            ],
            Text(AppStrings.description, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: AppStrings.enterDescription,
              ),
            ),
            const SizedBox(height: 16),
            if (_jiraService != null)
              Card(
                child: CheckboxListTile(
                  title: Text(AppStrings.syncToJira, style: theme.textTheme.bodyLarge),
                  subtitle: Text('دقیقه‌های کاری به Jira ارسال شود',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  value: _syncToJira,
                  onChanged: (v) => setState(() => _syncToJira = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(AppStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logTypeButton(String label, bool isTimer, IconData icon) {
    final selected = _logTypeTimer == isTimer;
    final theme = Theme.of(context);
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _logTypeTimer = isTimer),
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
            side: BorderSide(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<WorkLogProvider>();
    final now = DateTime.now();
    final totalSeconds = _hoursController.text.isNotEmpty
        ? (int.tryParse(_hoursController.text) ?? 0) * 3600 + (int.tryParse(_minutesController.text) ?? 0) * 60
        : _hours * 3600 + _minutes * 60;

    if (totalSeconds <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مدت زمان باید بیشتر از صفر باشد')),
        );
      }
      setState(() => _saving = false);
      return;
    }

    final log = WorkLog(
      id: widget.editLog?.id,
      jiraIssueId: _selectedIssue?.jiraId,
      issueKey: _selectedIssue?.key,
      issueSummary: _selectedIssue?.summary,
      jiraProjectId: _selectedIssue?.projectKey,
      description: _descController.text,
      startTime: widget.editLog?.startTime ?? (widget.startTime ?? now).toIso8601String(),
      endTime: now.toIso8601String(),
      durationSeconds: totalSeconds,
      logType: _logTypeTimer ? 'timer' : 'manual',
      syncedToJira: false,
      createdAt: widget.editLog?.createdAt ?? now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );

    try {
      if (widget.editLog != null) {
        await provider.updateLog(log);
      } else {
        await provider.saveLog(log);
      }

      if (_syncToJira && _jiraService != null && _selectedIssue != null) {
        final success = await provider.syncLogToJira(log, _jiraService!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? AppStrings.syncSuccess : AppStrings.syncFailed),
              backgroundColor: success ? const Color(0xFF2DA44E) : const Color(0xFFDA3633),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.logSaved), backgroundColor: const Color(0xFF2DA44E)),
          );
        }
      }
    } catch (e, stack) {
      final dir = await getApplicationDocumentsDirectory();
      final errFile = File('${dir.path}/karnama_error.log');
      await errFile.writeAsString('LogScreen._save error: $e\n$stack\n', mode: FileMode.append);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: const Color(0xFFDA3633)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    }
  }
}
