import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/work_log.dart';
import '../models/jira_project.dart';
import '../models/jira_issue.dart';
import '../services/database_service.dart';
import '../services/jira_service.dart';

class WorkLogProvider extends ChangeNotifier {
  List<WorkLog> _todayLogs = [];
  List<WorkLog> _allLogs = [];
  List<JiraProject> _projects = [];
  List<JiraIssue> _issues = [];
  bool _loading = false;
  String? _error;

  List<WorkLog> get todayLogs => _todayLogs;
  List<WorkLog> get allLogs => _allLogs;
  List<JiraProject> get projects => _projects;
  List<JiraIssue> get issues => _issues;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadTodayLogs() async {
    _todayLogs = await DatabaseService.instance.getTodayLogs();
    notifyListeners();
  }

  Future<void> loadLogs({String? dateFrom, String? dateTo}) async {
    _loading = true;
    notifyListeners();
    _allLogs = await DatabaseService.instance.getWorkLogs(dateFrom: dateFrom, dateTo: dateTo);
    _loading = false;
    notifyListeners();
  }

  Future<void> saveLog(WorkLog log) async {
    try {
      await DatabaseService.instance.insertWorkLog(log);
      await loadTodayLogs();
    } catch (e) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/karnama_error.log');
      await file.writeAsString('saveLog error: $e\n', mode: FileMode.append);
    }
  }

  Future<void> updateLog(WorkLog log) async {
    await DatabaseService.instance.updateWorkLog(log);
    await loadTodayLogs();
  }

  Future<void> deleteLog(int id) async {
    await DatabaseService.instance.deleteWorkLog(id);
    await loadTodayLogs();
    _allLogs.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<List<WorkLog>> getUnsyncedLogs() async {
    return DatabaseService.instance.getUnsyncedLogs();
  }

  Future<bool> syncLogToJira(WorkLog log, JiraService jiraService) async {
    try {
      final success = await jiraService.postWorklog(
        log.issueKey ?? '',
        log.durationSeconds,
        log.description ?? '',
        log.startTime,
      );
      if (success) {
        final updated = WorkLog(
          id: log.id,
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
          syncedToJira: true,
          createdAt: log.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await DatabaseService.instance.updateWorkLog(updated);
        await loadTodayLogs();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> exportToJson() async {
    try {
      final logs = await DatabaseService.instance.getWorkLogs();
      final json = jsonEncode(logs.map((l) => l.toJson()).toList());
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/karnama/export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadJiraProjects(JiraService jiraService) async {
    try {
      _projects = await jiraService.getProjects();
      await DatabaseService.instance.saveJiraProjects(_projects);
    } catch (e) {
      _projects = await DatabaseService.instance.getJiraProjects();
    }
    notifyListeners();
  }

  Future<void> loadJiraIssues(JiraService jiraService, String projectKey, {String? query}) async {
    _loading = true;
    notifyListeners();
    try {
      _issues = await jiraService.getIssues(projectKey, query: query);
      await DatabaseService.instance.saveJiraIssues(_issues);
    } catch (e) {
      _issues = await DatabaseService.instance.getJiraIssues(projectKey: projectKey);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadCachedIssues(String projectKey) async {
    _issues = await DatabaseService.instance.getJiraIssues(projectKey: projectKey);
    notifyListeners();
  }

  // --- Stats ---
  List<({String label, int seconds})> _weekStats = [];
  int _yesterdayTotal = 0;
  String? _topTaskKey;

  List<({String label, int seconds})> get weekStats => _weekStats;
  int get yesterdayTotal => _yesterdayTotal;
  String? get topTaskKey => _topTaskKey;

  String? get lastIssueKey {
    if (_allLogs.isNotEmpty) {
      return _allLogs.first.issueKey;
    }
    if (_todayLogs.isNotEmpty) {
      return _todayLogs.first.issueKey;
    }
    return null;
  }

  Future<void> loadWeekStats() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final logs = await DatabaseService.instance.getWorkLogs(
      dateFrom: weekAgo.toIso8601String().substring(0, 10),
      dateTo: '${now.toIso8601String().substring(0, 10)}Z',
    );

    final dayNames = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    final dayMap = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = d.toIso8601String().substring(0, 10);
      dayMap[key] = 0;
    }

    for (final log in logs) {
      final day = log.createdAt.substring(0, 10);
      if (dayMap.containsKey(day)) {
        dayMap[day] = (dayMap[day] ?? 0) + log.durationSeconds;
      }
    }

    _weekStats = [];
    int idx = 0;
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = d.toIso8601String().substring(0, 10);
      _weekStats.add((label: dayNames[idx % 7], seconds: dayMap[key] ?? 0));
      idx++;
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey = yesterday.toIso8601String().substring(0, 10);
    _yesterdayTotal = dayMap[yesterdayKey] ?? 0;

    final todayKey = now.toIso8601String().substring(0, 10);
    final todayLogs = logs.where((l) => l.createdAt.startsWith(todayKey)).toList();
    final taskSeconds = <String, int>{};
    for (final log in todayLogs) {
      final key = log.issueKey ?? 'بدون تسک';
      taskSeconds[key] = (taskSeconds[key] ?? 0) + log.durationSeconds;
    }
    _topTaskKey = taskSeconds.entries.fold<String?>(
      null,
      (best, e) => best == null || e.value > (taskSeconds[best] ?? 0) ? e.key : best,
    );

    notifyListeners();
  }
}
