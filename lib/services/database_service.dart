import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_log.dart';
import '../models/jira_config.dart';
import '../models/jira_project.dart';
import '../models/jira_issue.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  DatabaseService._();
  static DatabaseService get instance => _instance;

  String? _basePath;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _basePath = dir.path;
    final appDir = Directory('$_basePath/karnama');
    if (!await appDir.exists()) await appDir.create(recursive: true);
  }

  String get _logsPath => '$_basePath/karnama/work_logs.json';
  String get _configsPath => '$_basePath/karnama/jira_configs.json';
  String get _projectsPath => '$_basePath/karnama/jira_projects.json';
  String get _issuesPath => '$_basePath/karnama/jira_issues.json';

  Future<List<WorkLog>> getWorkLogs({String? dateFrom, String? dateTo}) async {
    final file = File(_logsPath);
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString()) as List;
    var logs = data.map((e) => WorkLog.fromMap(e as Map<String, dynamic>)).toList();
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (dateFrom != null) logs = logs.where((l) => l.createdAt.compareTo(dateFrom) >= 0).toList();
    if (dateTo != null) logs = logs.where((l) => l.createdAt.compareTo(dateTo) <= 0).toList();
    return logs;
  }

  Future<List<WorkLog>> getTodayLogs() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return getWorkLogs(dateFrom: today, dateTo: '${today}Z');
  }

  Future<int> insertWorkLog(WorkLog log) async {
    try {
      final file = File(_logsPath);
      final logs = await getWorkLogs();
      final newId = logs.isEmpty ? 1 : (logs.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final newLog = WorkLog(
        id: newId,
        jiraIssueId: log.jiraIssueId,
        issueKey: log.issueKey,
        issueSummary: log.issueSummary,
        jiraProjectId: log.jiraProjectId,
        jiraProjectKey: log.jiraProjectKey,
        jiraProjectName: log.jiraProjectName,
        description: log.description,
        startTime: log.startTime,
        endTime: log.endTime,
        durationSeconds: log.durationSeconds,
        logType: log.logType,
        syncedToJira: log.syncedToJira,
        jiraWorklogId: log.jiraWorklogId,
        createdAt: log.createdAt,
        updatedAt: log.updatedAt,
      );
      logs.insert(0, newLog);
      final jsonStr = jsonEncode(logs.map((e) => e.toMap()).toList());
      await file.writeAsString(jsonStr);
      return newId;
    } catch (e) {
      final dir = await getApplicationDocumentsDirectory();
      final errFile = File('${dir.path}/karnama_error.log');
      await errFile.writeAsString('insertWorkLog error: $e\n', mode: FileMode.append);
      rethrow;
    }
  }

  Future<int> updateWorkLog(WorkLog log) async {
    final file = File(_logsPath);
    final logs = await getWorkLogs();
    final index = logs.indexWhere((e) => e.id == log.id);
    if (index == -1) return 0;
    logs[index] = log;
    await file.writeAsString(jsonEncode(logs.map((e) => e.toMap()).toList()));
    return 1;
  }

  Future<int> deleteWorkLog(int id) async {
    final file = File(_logsPath);
    final logs = await getWorkLogs();
    logs.removeWhere((e) => e.id == id);
    await file.writeAsString(jsonEncode(logs.map((e) => e.toMap()).toList()));
    return 1;
  }

  Future<List<WorkLog>> getUnsyncedLogs() async {
    final logs = await getWorkLogs();
    return logs.where((l) => !l.syncedToJira).toList();
  }

  Future<int> saveJiraConfig(JiraConfig config) async {
    final file = File(_configsPath);
    List<JiraConfig> configs;
    if (await file.exists()) {
      final data = jsonDecode(await file.readAsString()) as List;
      configs = data.map((e) => JiraConfig.fromMap(e as Map<String, dynamic>)).toList();
    } else {
      configs = [];
    }
    if (config.isActive) {
      for (var i = 0; i < configs.length; i++) {
        configs[i] = JiraConfig(
          id: configs[i].id, url: configs[i].url,
          username: configs[i].username, token: configs[i].token,
          name: configs[i].name, isActive: false,
        );
      }
    }
    if (config.id == null) {
      final newId = configs.isEmpty ? 1 : (configs.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      configs.add(JiraConfig(
        id: newId, url: config.url, username: config.username,
        token: config.token, name: config.name, isActive: config.isActive,
      ));
    } else {
      final idx = configs.indexWhere((e) => e.id == config.id);
      if (idx != -1) configs[idx] = config;
    }
    await file.writeAsString(jsonEncode(configs.map((e) => e.toMap()).toList()));
    return config.id ?? 0;
  }

  Future<JiraConfig?> getActiveJiraConfig() async {
    final configs = await getJiraConfigs();
    return configs.cast<JiraConfig?>().firstWhere((c) => c!.isActive, orElse: () => configs.isNotEmpty ? configs.first : null);
  }

  Future<List<JiraConfig>> getJiraConfigs() async {
    final file = File(_configsPath);
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString()) as List;
    return data.map((e) => JiraConfig.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<int> deleteJiraConfig(int id) async {
    final file = File(_configsPath);
    final configs = await getJiraConfigs();
    configs.removeWhere((e) => e.id == id);
    await file.writeAsString(jsonEncode(configs.map((e) => e.toMap()).toList()));
    return 1;
  }

  Future<void> saveJiraProjects(List<JiraProject> projects) async {
    final file = File(_projectsPath);
    await file.writeAsString(jsonEncode(projects.map((e) => e.toMap()).toList()));
  }

  Future<List<JiraProject>> getJiraProjects() async {
    final file = File(_projectsPath);
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString()) as List;
    return data.map((e) => JiraProject.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveJiraIssues(List<JiraIssue> issues) async {
    final file = File(_issuesPath);
    await file.writeAsString(jsonEncode(issues.map((e) => e.toMap()).toList()));
  }

  Future<List<JiraIssue>> getJiraIssues({String? projectKey}) async {
    final file = File(_issuesPath);
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString()) as List;
    var issues = data.map((e) => JiraIssue.fromMap(e as Map<String, dynamic>)).toList();
    if (projectKey != null) issues = issues.where((i) => i.projectKey == projectKey).toList();
    return issues;
  }

  Future<String?> getSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
