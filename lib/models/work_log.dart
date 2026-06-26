class WorkLog {
  final int? id;
  final String? jiraIssueId;
  final String? issueKey;
  final String? issueSummary;
  final String? jiraProjectId;
  final String? jiraProjectKey;
  final String? jiraProjectName;
  final String? description;
  final String startTime;
  final String? endTime;
  final int durationSeconds;
  final String logType;
  final bool syncedToJira;
  final String? jiraWorklogId;
  final String createdAt;
  final String? updatedAt;

  WorkLog({
    this.id,
    this.jiraIssueId,
    this.issueKey,
    this.issueSummary,
    this.jiraProjectId,
    this.jiraProjectKey,
    this.jiraProjectName,
    this.description,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.logType = 'manual',
    this.syncedToJira = false,
    this.jiraWorklogId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'jira_issue_id': jiraIssueId,
    'issue_key': issueKey,
    'issue_summary': issueSummary,
    'jira_project_id': jiraProjectId,
    'jira_project_key': jiraProjectKey,
    'jira_project_name': jiraProjectName,
    'description': description,
    'start_time': startTime,
    'end_time': endTime,
    'duration_seconds': durationSeconds,
    'log_type': logType,
    'synced_to_jira': syncedToJira ? 1 : 0,
    'jira_worklog_id': jiraWorklogId,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory WorkLog.fromMap(Map<String, dynamic> m) => WorkLog(
    id: m['id'] as int?,
    jiraIssueId: m['jira_issue_id'] as String?,
    issueKey: m['issue_key'] as String?,
    issueSummary: m['issue_summary'] as String?,
    jiraProjectId: m['jira_project_id'] as String?,
    jiraProjectKey: m['jira_project_key'] as String?,
    jiraProjectName: m['jira_project_name'] as String?,
    description: m['description'] as String?,
    startTime: m['start_time'] as String,
    endTime: m['end_time'] as String?,
    durationSeconds: m['duration_seconds'] as int,
    logType: m['log_type'] as String? ?? 'manual',
    syncedToJira: (m['synced_to_jira'] as int?) == 1,
    jiraWorklogId: m['jira_worklog_id'] as String?,
    createdAt: m['created_at'] as String,
    updatedAt: m['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'issue_key': issueKey,
    'issue_summary': issueSummary,
    'project_key': jiraProjectKey,
    'project_name': jiraProjectName,
    'description': description,
    'start_time': startTime,
    'end_time': endTime,
    'duration_seconds': durationSeconds,
    'duration_formatted': '${(durationSeconds ~/ 3600)}h ${(durationSeconds % 3600) ~/ 60}m',
    'log_type': logType,
    'synced_to_jira': syncedToJira,
    'created_at': createdAt,
  };
}
