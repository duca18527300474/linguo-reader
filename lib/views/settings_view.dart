import 'package:flutter/material.dart';

import '../models/ai_config.dart';

/// 设置页面 —— 配置大模型 API 连接参数
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _baseUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await AIConfig.load();
    _baseUrlCtrl.text = config.baseUrl;
    _apiKeyCtrl.text = config.apiKey;
    _modelCtrl.text = config.model;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final baseUrl = _baseUrlCtrl.text.trim();
    final apiKey = _apiKeyCtrl.text.trim();
    final model = _modelCtrl.text.trim();

    if (baseUrl.isEmpty) {
      _showSnackBar('请输入 API Base URL');
      return;
    }
    if (apiKey.isEmpty) {
      _showSnackBar('请输入 API Key');
      return;
    }

    setState(() => _saving = true);

    try {
      final config = AIConfig(baseUrl: baseUrl, apiKey: apiKey, model: model);
      await config.save();

      if (mounted) {
        _showSnackBar('配置已保存');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存失败: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── 标题 ──
                Icon(Icons.smart_toy_outlined, size: 48,
                    color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text('AI 大模型配置',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('支持 OpenAI / DeepSeek / Claude 等兼容接口',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 28),

                // ── API Base URL ──
                TextField(
                  controller: _baseUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'https://api.openai.com/v1',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                    helperText: 'OpenAI 兼容接口地址，可替换为 DeepSeek / OneAPI 等',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                // ── API Key ──
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-...',
                    prefixIcon: const Icon(Icons.key),
                    border: const OutlineInputBorder(),
                    helperText: '你的 API 密钥，仅保存在本地',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Model ──
                TextField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'gpt-4o-mini',
                    prefixIcon: Icon(Icons.memory),
                    border: OutlineInputBorder(),
                    helperText: '模型名称，如 gpt-4o-mini、deepseek-chat、claude-3-opus',
                  ),
                ),
                const SizedBox(height: 28),

                // ── 保存按钮 ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? '保存中...' : '保存配置'),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 提示卡片 ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('配置示例', style: theme.textTheme.labelLarge),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildProviderExample(theme, 'OpenAI',
                          'Base: https://api.openai.com/v1\nModel: gpt-4o-mini'),
                      const SizedBox(height: 8),
                      _buildProviderExample(theme, 'DeepSeek',
                          'Base: https://api.deepseek.com/v1\nModel: deepseek-chat'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProviderExample(ThemeData theme, String name, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(name, style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          )),
        ),
        Expanded(
          child: Text(detail, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
