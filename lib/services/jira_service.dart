import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/jira_config.dart';
import '../models/jira_project.dart';
import '../models/jira_issue.dart';

class JiraService {
  HttpClient _httpClient = HttpClient()
    ..badCertificateCallback = (_, _, _) => true;
  JiraConfig? _config;

  void configure(JiraConfig config) {
    _config = config;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{};
    if (_config == null) return headers;
    if (_config!.authType == 'bearer') {
      headers['Authorization'] = 'Bearer ${_config!.token}';
    } else if (_config!.username.isNotEmpty) {
      final credentials = base64Encode(utf8.encode('${_config!.username}:${_config!.token}'));
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }

  String get _baseUrl {
    if (_config == null) return '';
    var url = _config!.url.trim();
    while (url.startsWith('/')) url = url.substring(1);
    while (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return '$url/rest/api/2';
  }

  Future<bool> testConnection() async {
    final (ok, _) = await testConnectionWithMessage();
    return ok;
  }

  Future<(bool, String)> testConnectionWithMessage([JiraConfig? config]) async {
    if (config != null) configure(config);
    final url = '$_baseUrl/myself';
    try {
      final req = await _httpClient.getUrl(Uri.parse(url));
      _headers.forEach((k, v) => req.headers.set(k, v));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode == 200) return (true, '');
      final msg = (resp.reasonPhrase != null && resp.reasonPhrase!.isNotEmpty)
          ? resp.reasonPhrase! : 'HTTP ${resp.statusCode}';
      return (false, msg);
    } catch (e) {
      final errMsg = '${e.runtimeType}: $e';
      _logError('Jira testConnection: $url -> $errMsg');
      return (false, errMsg);
    }
  }

  static Future<void> _logError(String msg) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/karnama_error.log');
      await file.writeAsString('$msg\n', mode: FileMode.append);
    } catch (_) {}
  }

  static String _describeHttpStatus(int code) {
    switch (code) {
      case 401: return 'نام کاربری یا رمز اشتباه است (401)';
      case 403: return 'دسترسی ممنوع — رمز یا مجوزها مشکل دارد (403)';
      case 404: return 'آدرس Jira پیدا نشد — context path را بررسی کنید (404)';
      case 500: return 'خطای داخلی سرور Jira (500)';
      case 502: return 'درگاه Jira پاسخ نمی‌دهد (502)';
      case 503: return 'سرویس Jira در دسترس نیست (503)';
      default: return 'HTTP $code';
    }
  }

  Future<List<JiraProject>> getProjects() async {
    final request = await _httpClient.getUrl(Uri.parse('$_baseUrl/project'));
    _headers.forEach((k, v) => request.headers.set(k, v));
    final response = await request.close();
    if (response.statusCode != 200) throw Exception('Failed to load projects: ${response.statusCode}');
    final body = await response.transform(utf8.decoder).join();
    final List data = jsonDecode(body);
    return data.map((p) => JiraProject(
      jiraId: p['id'].toString(),
      key: p['key'],
      name: p['name'],
      avatarUrl: p['avatarUrls']?['48x48'],
    )).toList();
  }

  Future<List<JiraIssue>> getIssues(String projectKey, {String? query, int maxResults = 50}) async {
    String jql = 'project = "$projectKey" ORDER BY updatedDate DESC';
    if (query != null && query.isNotEmpty) {
      jql = 'project = "$projectKey" AND text ~ "${query.replaceAll('"', '\\"')}" '
          'ORDER BY updatedDate DESC';
    }
    return _searchJira(jql, maxResults, projectKey);
  }

  Future<List<JiraIssue>> searchIssuesAll({String? query, int maxResults = 50}) async {
    String jql = 'ORDER BY updatedDate DESC';
    if (query != null && query.isNotEmpty) {
      final q = query.replaceAll('"', '\\"');
      jql = '(text ~ "$q" OR key = "$q") ORDER BY updatedDate DESC';
    }
    return _searchJira(jql, maxResults);
  }

  Future<List<JiraIssue>> _searchJira(String jql, int maxResults, [String? projectKey]) async {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'jql': jql,
      'maxResults': maxResults.toString(),
      'fields': 'summary,status,assignee,project',
    });
    final request = await _httpClient.getUrl(uri);
    _headers.forEach((k, v) => request.headers.set(k, v));
    final response = await request.close();
    if (response.statusCode != 200) throw Exception('Failed to search: ${response.statusCode}');
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    final List issues = decoded['issues'];
    return issues.map((i) => JiraIssue(
      jiraId: i['id'],
      projectKey: projectKey ?? (i['fields']['project'] as Map?)?['key'] ?? '',
      key: i['key'],
      summary: i['fields']['summary'] ?? '',
      status: i['fields']['status']?['name'],
      assignee: i['fields']['assignee']?['displayName'],
    )).toList();
  }

  Future<bool> postWorklog(String issueKey, int durationSeconds, String comment, String started) async {
    try {
      final request = await _httpClient.postUrl(Uri.parse('$_baseUrl/issue/$issueKey/worklog'));
      _headers.forEach((k, v) => request.headers.set(k, v));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      final tzOffset = started.contains('+') || started.contains('Z') ? '' : '+0330';
      final jiraStarted = started
          .replaceAll(RegExp(r'\.\d+'), '.000')
          .replaceAll(RegExp(r'Z$'), '')
          .trim() + (started.contains('+') || started.contains('Z') ? '' : tzOffset);

      final payload = jsonEncode({
        'started': jiraStarted,
        'timeSpentSeconds': durationSeconds,
        'comment': comment,
      });
      request.add(utf8.encode(payload));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 201) {
        _logError('Jira postWorklog $issueKey: ${response.statusCode} - $body | payload: $payload');
        return false;
      }
      return true;
    } catch (e) {
      _logError('Jira postWorklog $issueKey exception: $e');
      return false;
    }
  }
}
