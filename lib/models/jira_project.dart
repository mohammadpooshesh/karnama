class JiraProject {
  final int? id;
  final String jiraId;
  final String key;
  final String name;
  final String? avatarUrl;

  JiraProject({
    this.id,
    required this.jiraId,
    required this.key,
    required this.name,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'jira_id': jiraId,
    'key': key,
    'name': name,
    'avatar_url': avatarUrl,
  };

  factory JiraProject.fromMap(Map<String, dynamic> m) => JiraProject(
    id: m['id'] as int?,
    jiraId: m['jira_id'] as String,
    key: m['key'] as String,
    name: m['name'] as String,
    avatarUrl: m['avatar_url'] as String?,
  );
}
