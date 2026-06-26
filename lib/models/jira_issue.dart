class JiraIssue {
  final int? id;
  final String jiraId;
  final String projectKey;
  final String key;
  final String summary;
  final String? status;
  final String? assignee;

  JiraIssue({
    this.id,
    required this.jiraId,
    required this.projectKey,
    required this.key,
    required this.summary,
    this.status,
    this.assignee,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'jira_id': jiraId,
    'project_key': projectKey,
    'key': key,
    'summary': summary,
    'status': status,
    'assignee': assignee,
  };

  factory JiraIssue.fromMap(Map<String, dynamic> m) => JiraIssue(
    id: m['id'] as int?,
    jiraId: m['jira_id'] as String,
    projectKey: m['project_key'] as String,
    key: m['key'] as String,
    summary: m['summary'] as String,
    status: m['status'] as String?,
    assignee: m['assignee'] as String?,
  );

  @override
  String toString() => '$key: $summary';
}
