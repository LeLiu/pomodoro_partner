import 'package:flutter/material.dart';

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
        _errorMessage = '加载配置失败: \$e';
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
        final currentSttings  = await AppSettings.loadSettings();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('设置已保存')),
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
    if (!_webdavEnabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
      child: Column(
        children: [
          TextFormField(
            controller: _hostController,
            decoration: const InputDecoration(labelText: '主机 (例如: https://dav.example.com)'),
            validator: (value) {
              if (_webdavEnabled && (value == null || value.isEmpty)) {
                return '请输入 WebDAV 主机地址';
              }
              if (_webdavEnabled && !Uri.tryParse(value!)!.isAbsolute) {
                return '请输入有效的主机地址 (例如 https://dav.example.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _userController,
            decoration: const InputDecoration(labelText: '用户名'),
            validator: (value) {
              if (_webdavEnabled && (value == null || value.isEmpty)) {
                return '请输入 WebDAV 用户名';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: '密码'),
            obscureText: true,
            validator: (value) {
              if (_webdavEnabled && (value == null || value.isEmpty)) {
                return '请输入 WebDAV 密码';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pathController,
            decoration: const InputDecoration(labelText: '路径 (例如: /dav/pp)'),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettings,
              child: const Text('重试加载'),
            ),
          ],
        ),
      );
    }
    final webdavSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('WebDAV 设置', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(
          title: const Text('启用 WebDAV'),
          value: _webdavEnabled,
          onChanged: _onWebdavEnabledChanged,
        ),
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
              child: ElevatedButton(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _buildBody(),
    );
  }
}