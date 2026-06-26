import 'package:flutter/material.dart';
import '../models/work_log.dart';
import 'persian_utils.dart';

class LogCard extends StatelessWidget {
  final WorkLog log;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const LogCard({super.key, required this.log, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: log.syncedToJira
                      ? const Color(0xFF2DA44E).withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  log.syncedToJira ? Icons.cloud_done_rounded : Icons.access_time_rounded,
                  size: 18,
                  color: log.syncedToJira
                      ? const Color(0xFF2DA44E)
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (log.issueKey != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.issueKey!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (log.description != null && log.description!.isNotEmpty)
                          Expanded(
                            child: Text(
                              log.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ),
                      ],
                    ),
                    if (log.issueSummary != null && log.issueSummary!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        log.issueSummary!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 10,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        Text(
                          PersianUtils.toPersianDateTime(DateTime.parse(log.createdAt)),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    PersianUtils.formatPersianDuration(log.durationSeconds),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Vazir',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(height: 4),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16,
                          color: const Color(0xFFDA3633).withValues(alpha: 0.6)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
