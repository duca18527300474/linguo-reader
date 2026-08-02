import 'package:flutter/material.dart';

import '../models/ai_config.dart';
import '../services/ai_service.dart';

/// 长难句解析面板 —— 底部弹窗，支持 loading / 结果 / 错误 / 未配置 四种状态
class SentenceAnalysisPanel extends StatefulWidget {
  final String sentence;
  final VoidCallback? onGoToSettings;

  const SentenceAnalysisPanel({
    super.key,
    required this.sentence,
    this.onGoToSettings,
  });

  @override
  State<SentenceAnalysisPanel> createState() => _SentenceAnalysisPanelState();
}

class _SentenceAnalysisPanelState extends State<SentenceAnalysisPanel> {
  bool _loading = true;
  String? _error;
  bool _noConfig = false;
  SentenceAnalysis? _result;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final config = await AIConfig.load();

    if (!config.isConfigured) {
      if (mounted) setState(() { _loading = false; _noConfig = true; });
      return;
    }

    final service = AIService(config: config);
    final result = await service.analyzeSentence(widget.sentence);

    if (!mounted) return;

    if (result != null) {
      setState(() { _loading = false; _result = result; });
    } else {
      setState(() { _loading = false; _error = service.lastError ?? '未知错误'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.menu_open, size: 20, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('长难句解析',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            // 原文
            Text('原文', style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.sentence,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 16),
            // 状态区域
            _buildStateArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStateArea(ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('AI 正在解析句子结构...'),
            ],
          ),
        ),
      );
    }

    if (_noConfig) {
      return _promptBox(theme,
          icon: Icons.settings_outlined, color: Colors.orange,
          message: '尚未配置 API Key，无法解析句子',
          actionLabel: '去设置',
          onAction: () {
            Navigator.pop(context);
            widget.onGoToSettings?.call();
          });
    }

    if (_error != null) {
      return _promptBox(theme,
          icon: Icons.error_outline, color: Colors.red,
          message: _error!,
          actionLabel: '重试',
          onAction: () {
            setState(() { _loading = true; _error = null; });
            _analyze();
          });
    }

    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.translation != null) ...[
          _sectionTitle(theme, '中文翻译'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(r.translation!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          ),
        ],
        if (r.grammarBreakdown != null) ...[
          const SizedBox(height: 16),
          _sectionTitle(theme, '语法分析'),
          const SizedBox(height: 6),
          Text(r.grammarBreakdown!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
        ],
        if (r.keyVocabulary != null && r.keyVocabulary!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle(theme, '核心词汇'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: r.keyVocabulary!
                .map((w) => Chip(
                      label: Text(w, style: theme.textTheme.labelSmall),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Text(text, style: theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.primary, fontWeight: FontWeight.w600));
  }

  Widget _promptBox(ThemeData theme, {
    required IconData icon, required Color color, required String message,
    String? actionLabel, VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: theme.textTheme.bodySmall?.copyWith(color: color.withOpacity(0.9)))),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
