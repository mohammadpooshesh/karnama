import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jira_config.dart';
import '../providers/settings_provider.dart';
import '../l10n/strings_fa.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _tokenController = TextEditingController();
  final _nameController = TextEditingController();
  bool _showToken = false;
  bool _saving = false;
  String _authType = 'bearer';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExisting();
    });
  }

  void _loadExisting() {
    final config = context.read<SettingsProvider>().activeConfig;
    if (config != null) {
      _urlController.text = config.url;
      _userController.text = config.username;
      _tokenController.text = config.token;
      _nameController.text = config.name ?? '';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _tokenController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.settings, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: AppStrings.jiraConfig,
            subtitle: 'Jira Server / Data Center',
            child: Column(
              children: [
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: AppStrings.jiraUrl,
                    hintText: 'https://jira.company.com',
                    prefixIcon: const Icon(Icons.link, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'bearer', label: Text('Bearer Token'), icon: Icon(Icons.vpn_key, size: 16)),
                      ButtonSegment(value: 'basic', label: Text('Basic Auth'), icon: Icon(Icons.person, size: 16)),
                    ],
                    selected: {_authType},
                    onSelectionChanged: (v) => setState(() => _authType = v.first),
                  ),
                ),
                const SizedBox(height: 12),
                if (_authType == 'basic')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: AppStrings.jiraUsername,
                        prefixIcon: const Icon(Icons.person, size: 18),
                      ),
                    ),
                  ),
                TextField(
                  controller: _tokenController,
                  obscureText: !_showToken,
                  decoration: InputDecoration(
                    labelText: AppStrings.jiraToken,
                    prefixIcon: const Icon(Icons.key, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_showToken ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _showToken = !_showToken),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'نام (اختیاری)',
                    prefixIcon: const Icon(Icons.label, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: provider.testingConnection ? null :
                            () => _testConnection(provider),
                        icon: provider.testingConnection
                            ? const SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.wifi_find, size: 16),
                        label: Text(provider.testingConnection
                            ? AppStrings.loading : AppStrings.testConnection),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _saveConfig,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
                if (provider.connectionResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (provider.connectionResult!
                          ? const Color(0xFF2DA44E)
                          : const Color(0xFFDA3633)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          provider.connectionResult!
                              ? Icons.check_circle : Icons.error,
                          size: 18,
                          color: provider.connectionResult!
                              ? const Color(0xFF2DA44E) : const Color(0xFFDA3633),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.connectionResult!
                                    ? AppStrings.connectionOk : AppStrings.connectionFailed,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                              if (!provider.connectionResult! && provider.connectionError.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(provider.connectionError,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFFDA3633))),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (provider.configs.isNotEmpty) ...[
            _buildSection(
              context,
              title: 'کَانْفیک‌های ذخیره شده',
              subtitle: 'برای ویرایش روی هر کانفیگ کلیک کنید',
              child: Column(
                children: provider.configs.map((config) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: config.isActive
                          ? const Color(0xFF2DA44E).withValues(alpha: 0.15)
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                      child: Icon(
                        config.isActive ? Icons.check : Icons.circle_outlined,
                        size: 14,
                        color: config.isActive
                            ? const Color(0xFF2DA44E)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    title: Text(config.name?.isNotEmpty == true
                        ? config.name! : config.url,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: Text(config.username,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, size: 18,
                          color: const Color(0xFFDA3633)),
                      onPressed: () => provider.deleteConfig(config.id!),
                    ),
                    onTap: () {
                      _urlController.text = config.url;
                      _userController.text = config.username;
                      _tokenController.text = config.token;
                      _nameController.text = config.name ?? '';
                    },
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildSection(
            context,
            title: AppStrings.darkMode,
            child: Row(
              children: [
                Icon(provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.darkMode, style: theme.textTheme.bodyLarge),
                      Text(provider.isDarkMode ? 'فعال' : 'غیرفعال',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Switch(
                  value: provider.isDarkMode,
                  onChanged: (_) => provider.toggleDarkMode(),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.access_time_rounded, size: 24,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.appName} ${AppStrings.version} ۱.۰.۰',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, String? subtitle, required Widget child}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ],
    );
  }

  Future<void> _testConnection(SettingsProvider provider) async {
    if (_urlController.text.isEmpty || _tokenController.text.isEmpty ||
        (_authType == 'basic' && _userController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً تمام فیلدها را پر کنید')),
      );
      return;
    }
    final config = JiraConfig(
      url: _urlController.text.trim(),
      username: _userController.text.trim(),
      token: _tokenController.text.trim(),
      name: _nameController.text.trim(),
      authType: _authType,
    );
    await provider.testConnection(config);
  }

  Future<void> _saveConfig() async {
    if (_urlController.text.isEmpty || _tokenController.text.isEmpty ||
        (_authType == 'basic' && _userController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً تمام فیلدها را پر کنید')),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<SettingsProvider>();
    final config = JiraConfig(
      url: _urlController.text.trim(),
      username: _userController.text.trim(),
      token: _tokenController.text.trim(),
      name: _nameController.text.trim(),
      isActive: true,
      authType: _authType,
    );
    await provider.saveConfig(config);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تنظیمات ذخیره شد')),
      );
    }
  }
}
