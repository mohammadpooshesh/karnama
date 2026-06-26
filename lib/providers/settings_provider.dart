import 'package:flutter/material.dart';
import '../models/jira_config.dart';
import '../services/database_service.dart';
import '../services/jira_service.dart';

class SettingsProvider extends ChangeNotifier {
  JiraConfig? _activeConfig;
  List<JiraConfig> _configs = [];
  bool _testingConnection = false;
  bool? _connectionResult;
  String _connectionError = '';
  bool _isDarkMode = false;
  late final Future<void> _ready;

  JiraConfig? get activeConfig => _activeConfig;
  List<JiraConfig> get configs => _configs;
  bool get testingConnection => _testingConnection;
  bool? get connectionResult => _connectionResult;
  String get connectionError => _connectionError;
  bool get isDarkMode => _isDarkMode;
  Future<void> get ready => _ready;

  SettingsProvider() {
    _ready = _init();
  }

  Future<void> _init() async {
    await loadConfigs();
  }

  Future<void> loadConfigs() async {
    _configs = await DatabaseService.instance.getJiraConfigs();
    _activeConfig = _configs.cast<JiraConfig?>().firstWhere(
      (c) => c!.isActive,
      orElse: () => _configs.isNotEmpty ? _configs.first : null,
    );
    final darkStr = await DatabaseService.instance.getSetting('dark_mode');
    _isDarkMode = darkStr == 'true';
    notifyListeners();
  }

  Future<void> saveConfig(JiraConfig config) async {
    await DatabaseService.instance.saveJiraConfig(config);
    await loadConfigs();
  }

  Future<void> deleteConfig(int id) async {
    await DatabaseService.instance.deleteJiraConfig(id);
    await loadConfigs();
  }

  Future<void> testConnection(JiraConfig config) async {
    _testingConnection = true;
    _connectionResult = null;
    _connectionError = '';
    notifyListeners();

    final jiraService = JiraService();
    final result = await jiraService.testConnectionWithMessage(config);

    _connectionResult = result.$1;
    _connectionError = result.$2;
    if (!_connectionResult! && _connectionError.isEmpty) {
      _connectionError = 'خطای نامشخص (اتصال برقرار نشد)';
    }
    _testingConnection = false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await DatabaseService.instance.setSetting('dark_mode', _isDarkMode.toString());
    notifyListeners();
  }
}
