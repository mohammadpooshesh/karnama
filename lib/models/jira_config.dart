class JiraConfig {
  final int? id;
  final String url;
  final String username;
  final String token;
  final String? name;
  final bool isActive;
  final String authType; // 'basic' or 'bearer'

  JiraConfig({
    this.id,
    required this.url,
    this.username = '',
    required this.token,
    this.name,
    this.isActive = false,
    this.authType = 'basic',
  });

  JiraConfig copyWith({
    int? id,
    String? url,
    String? username,
    String? token,
    String? name,
    bool? isActive,
    String? authType,
  }) => JiraConfig(
    id: id ?? this.id,
    url: url ?? this.url,
    username: username ?? this.username,
    token: token ?? this.token,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    authType: authType ?? this.authType,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'url': url,
    'username': username,
    'token': token,
    'name': name ?? '',
    'is_active': isActive ? 1 : 0,
    'auth_type': authType,
  };

  factory JiraConfig.fromMap(Map<String, dynamic> m) => JiraConfig(
    id: m['id'] as int?,
    url: m['url'] as String,
    username: m['username'] as String? ?? '',
    token: m['token'] as String,
    name: m['name'] as String?,
    isActive: (m['is_active'] as int?) == 1,
    authType: m['auth_type'] as String? ?? 'basic',
  );
}
