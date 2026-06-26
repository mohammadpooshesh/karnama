import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/worklog_provider.dart';
import '../l10n/strings_fa.dart';
import '../widgets/log_card.dart';
import 'log_screen.dart';
import 'dart:async';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkLogProvider>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(AppStrings.history, style: theme.textTheme.headlineSmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _dateField(
                          label: 'از تاریخ',
                          value: _dateFrom,
                          onPicked: (d) => setState(() => _dateFrom = d),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      ),
                      Expanded(
                        child: _dateField(
                          label: 'تا تاریخ',
                          value: _dateTo,
                          onPicked: (d) => setState(() => _dateTo = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _filter,
                          icon: const Icon(Icons.filter_list, size: 16),
                          label: const Text(AppStrings.refresh),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _export,
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text(AppStrings.exportJson),
                        ),
                      ),
                      if (_dateFrom != null || _dateTo != null) ...[
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 36,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _dateFrom = null;
                                _dateTo = null;
                              });
                              context.read<WorkLogProvider>().loadLogs();
                            },
                            icon: Icon(Icons.filter_alt_off_rounded, size: 18,
                                color: theme.colorScheme.primary),
                            tooltip: 'نمایش همه',
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<WorkLogProvider>(
            builder: (context, provider, _) {
              if (provider.loading) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (provider.allLogs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.inbox_rounded, size: 36,
                            color: isDark ? Colors.white24 : Colors.black12),
                      ),
                      const SizedBox(height: 12),
                      Text(AppStrings.noLogs,
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: isDark ? Colors.white38 : Colors.black26)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => provider.loadLogs(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: provider.allLogs.length,
                  itemBuilder: (ctx, i) {
                    final log = provider.allLogs[i];
                    return LogCard(
                      log: log,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LogScreen(editLog: log)),
                      ),
                      onDelete: () => _deleteLog(context, log.id!),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dateField({required String label, required DateTime? value, required ValueChanged<DateTime> onPicked}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 1)),
          );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 2),
                  Text(
                    value != null
                        ? '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}'
                        : 'انتخاب...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: value != null ? null : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
            Icon(Icons.date_range, size: 16,
                color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  void _filter() {
    final from = _dateFrom?.toIso8601String().substring(0, 10);
    final to = _dateTo?.toIso8601String().substring(0, 10);
    context.read<WorkLogProvider>().loadLogs(dateFrom: from, dateTo: to);
  }

  Future<void> _export() async {
    final provider = context.read<WorkLogProvider>();
    final path = await provider.exportToJson();
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خروجی در: $path')),
      );
    }
  }

  Future<void> _deleteLog(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(AppStrings.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.delete, style: const TextStyle(color: Color(0xFFDA3633))),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<WorkLogProvider>().deleteLog(id);
    }
  }
}
