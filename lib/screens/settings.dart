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
        if (mounted) {
          await displayInfoBar(
            context,
            builder: (context, close) {
              return InfoBar(
                title: const Text('You can not do that :/'),
                content: const Text(
                  'A proper warning message of why the user can not do that :/',
                ),
                action: IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: close,
                ),
                severity: InfoBarSeverity.warning,
              );
            },
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = '保存配置失败: \$e';
          _isLoading = false;
        });
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
      icon: _webdavEnabled
          ? null
          : SizedBox(
              width: 8,
              height: 8,
            ), 
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
          TextFormBox(
            controller: _hostController,
            //decoration: const InputDecoration(labelText: '主机 (例如: https://dav.example.com)'),
            validator: (value) {
              if (_webdavEnabled && (value == null || value.isEmpty)) {
                return '请输入 WebDAV 主机地址';
              }
              if (_webdavEnabled && !Uri.tryParse(value!)!.isAbsolute) {
                return '请输入有效的主机地址 (例如 https://dav.jianguoyun.com/dav)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormBox(
            controller: _userController,
            //decoration: const InputDecoration(labelText: '用户名'),
            validator: (value) {
              if (_webdavEnabled && (value == null || value.isEmpty)) {
                return '请输入 WebDAV 用户名';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormBox(
            controller: _passwordController,
            //decoration: const InputDecoration(labelText: '密码'),
            obscureText: true,
            validator: (value) {
              if (_webdavEnabled && (value == null || value.isEmpty)) {
                return '请输入 WebDAV 密码';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormBox(
            controller: _pathController,
            //decoration: const InputDecoration(labelText: '路径 (例如: /dav/pp)'),
            validator: (value) {
              if (_webdavEnabled && (value == null || value.isEmpty)) {
                return '请输入 WebDAV 路径';
              }
              if (_webdavEnabled && !value!.startsWith('/')) {
                return '路径必须以 / 开头';
              }
              return null;
            },
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
      children: <Widget>[
        Text('WebDAV 设置', style: FluentTheme.of(context).typography.subtitle),
        // ToggleSwitch(
        //   title: const Text('启用 WebDAV'),
        //   value: _webdavEnabled,
        //   onChanged: _onWebdavEnabledChanged,
        // ),
        _buildWebdavFields(),
      ],
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
        //title: Text('设置', style: FluentTheme.of(context).typography.titleLarge),
        title: Text('设置'),
      ),
      content: _buildBody(),
    );
  }
}
