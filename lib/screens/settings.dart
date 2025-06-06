import 'package:fluent_ui/fluent_ui.dart';
// import 'package:flutter/material.dart';

import '../features/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _webdavEnabled = false;
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final settings = await AppSettings.loadSettings();
      final webdavSettings = settings['webdav'] as Map<String, dynamic>? ?? {};
      setState(() {
        _webdavEnabled = webdavSettings['on'] as bool? ?? false;
        _hostController.text = webdavSettings['host'] as String? ?? '';
        _userController.text = webdavSettings['user'] as String? ?? '';
        _passwordController.text = webdavSettings['passwd'] as String? ?? '';
        _pathController.text = webdavSettings['path'] as String? ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载配置失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final currentSttings = await AppSettings.loadSettings();
        final newSettings = Map<String, dynamic>.from(currentSttings);
        newSettings['webdav'] = {
          'on': _webdavEnabled,
          'host': _hostController.text,
          'user': _userController.text,
          'passwd': _passwordController.text,
          'path': _pathController.text,
        };
        await AppSettings.saveSettings(newSettings);
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = '$e';
          _isLoading = false;
        });
        if (mounted) {
          await displayInfoBar(
            context,
            builder: (context, close) {
              return InfoBar(
                title: const Text('保存配置失败'),
                content: Text(_errorMessage ?? ''),
                action: IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: close,
                ),
                severity: InfoBarSeverity.warning,
              );
            },
          );
        }
      }
    }
  }

  void _onWebdavEnabledChanged(bool value) {
    setState(() {
      _webdavEnabled = value;
    });
  }

  Widget _buildWebdavFields() {
    return Expander(
      key: UniqueKey(),
      header: Row(
        children: [
          const Icon(FluentIcons.fabric_network_folder),
          SizedBox(width: 16),
          const Text('WebDAV'),
        ],
      ),
      icon: _webdavEnabled ? null : SizedBox(width: 8, height: 8),
      enabled: _webdavEnabled,
      trailing: ToggleSwitch(
        checked: _webdavEnabled,
        onChanged: _onWebdavEnabledChanged,
        content: Text(_webdavEnabled ? '启用' : '禁用'),
        leadingContent: true,
      ),
      initiallyExpanded: _webdavEnabled,
      content: Column(
        children: [
          InfoLabel(
            label: '服务器地址',
            child: TextFormBox(
              controller: _hostController,
              placeholder: '请输入服务器地址 (例如: https://dav.example.com)',
              validator: (value) {
                if (_webdavEnabled && (value == null || value.isEmpty)) {
                  return '请输入WebDAV服务器地址';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: '用户名',
            child: TextFormBox(
              controller: _userController,
              placeholder: '请输入用户名',
              validator: (value) {
                if (_webdavEnabled && (value == null || value.isEmpty)) {
                  return '请输入WebDAV用户名';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),
          InfoLabel(
            label: '访问密码',
            child: TextFormBox(
              controller: _passwordController,
              placeholder: '请输入访问密码',
              obscureText: true,
              validator: (value) {
                if (_webdavEnabled && (value == null || value.isEmpty)) {
                  return '请输入WebDAV密码';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: '访问路径',
            child: TextFormBox(
              controller: _pathController,
              placeholder: '请输入访问路径，例如 /dav/pp',
              validator: (value) {
                if (_webdavEnabled && (value == null || value.isEmpty)) {
                  return '请输入WebDAV路径';
                }
                if (_webdavEnabled && !value!.startsWith('/')) {
                  return '路径必须以 / 开头';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadSettings, child: const Text('重试加载')),
          ],
        ),
      );
    }
    final webdavSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[_buildWebdavFields()],
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            webdavSection,
            const SizedBox(height: 24),
            Center(
              child: FilledButton(
                onPressed: _saveSettings,
                child: const Text('保存设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Row(children: [Icon(FluentIcons.settings, size: 24,), SizedBox(width: 12), Text('设置')]),
      ),
      content: _buildBody(),
    );
  }
}
