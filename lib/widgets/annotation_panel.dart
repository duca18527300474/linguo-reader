import 'package:flutter/material.dart';

import '../models/ai_config.dart';
import '../models/word_annotation.dart' hide SentenceAnalysis;
import '../services/ai_service.dart';
import '../services/database_service.dart';

/// 单词释义面板 —— 底部弹窗，支持 loading / 结果 / 错误 / 未配置 四种状态
class AnnotationPanel extends StatefulWidget {
  final String word;
  final String contextSentence;
  final VoidCallback? onGoToSettings;

  const AnnotationPanel({
    super.key,
    required this.word,
    required this.contextSentence,
    this.onGoToSettings,
  });

  @override
  State<AnnotationPanel> createState() => _AnnotationPanelState();
}

class _AnnotationPanelState extends State<AnnotationPanel> {
  bool _loading = true;
  String? _error;
  bool _noConfig = false;
  WordAnalysis? _result;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _lookup();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final exists = await DatabaseService.instance.hasVocabularyWord(widget.word);
    if (mounted) setState(() => _bookmarked = exists);
  }

  Future<void> _lookup() async {
    final config = await AIConfig.load();

    if (!config.isConfigured) {
      if (mounted) setState(() { _loading = false; _noConfig = true; });
      return;
    }

    final service = AIService(config: config);
    final result = await service.lookupWord(widget.word, widget.contextSentence);

    if (!mounted) return;

    if (result != null) {
      setState(() { _loading = false; _result = result; });
    } else {
      setState(() { _loading = false; _error = service.lastError ?? '未知错误'; });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarked) return; // 已收藏，不重复添加

    final r = _result;
    final vocab = VocabularyWord(
      word: widget.word,
      pronunciation: r?.pronunciation,
      definition: r?.contextMeaning ?? r?.definition,
      contextSentence: widget.contextSentence,
      createdAt: DateTime.now(),
    );

    await DatabaseService.instance.insertVocabulary(vocab);

    if (mounted) {
      setState(() => _bookmarked = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('已收藏「${widget.word}」到生词本'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
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
            // 拖动指示条
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
            // 标题
            Row(
              children: [
                Icon(Icons.touch_app, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('单词查询', style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: Icon(
                    _bookmarked ? Icons.star : Icons.star_outline,
                    color: _bookmarked ? Colors.amber : null,
                  ),
                  tooltip: _bookmarked ? '已收藏' : '收藏到生词本',
                  onPressed: _bookmarked ? null : _toggleBookmark,
                ),
              ],
            ),
            const Divider(height: 24),
            // 目标单词
            _sectionLabel(theme, '已选中单词'),
            const SizedBox(height: 4),
            _wordCard(theme, widget.word),
            const SizedBox(height: 12),
            // 上下文
            _sectionLabel(theme, '上下文'),
            const SizedBox(height: 4),
            _sentenceCard(theme, widget.contextSentence),
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
              Text('AI 正在分析...'),
            ],
          ),
        ),
      );
    }

    if (_noConfig) {
      return _buildPromptBox(
        theme,
        icon: Icons.settings_outlined,
        color: Colors.orange,
        message: '尚未配置 API Key，无法查询单词释义',
        actionLabel: '去设置',
        onAction: () {
          Navigator.pop(context);
          widget.onGoToSettings?.call();
        },
      );
    }

    if (_error != null) {
      return _buildPromptBox(
        theme,
        icon: Icons.error_outline,
        color: Colors.red,
        message: _error!,
        actionLabel: '重试',
        onAction: () {
          setState(() { _loading = true; _error = null; });
          _lookup();
        },
      );
    }

    // ── 结果展示 ──
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.pronunciation != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.record_voice_over, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text('/${r.pronunciation}/',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    )),
              ],
            ),
          ),
        if (r.partOfSpeech != null) _resultRow(theme, '词性', r.partOfSpeech!),
        if (r.definition != null) _resultRow(theme, '释义', r.definition!),
        if (r.contextMeaning != null) _resultRow(theme, '文中含义', r.contextMeaning!,
            highlight: true),
        if (r.example != null) _resultRow(theme, '例句', r.example!,
            italic: true),
      ],
    );
  }

  // ── 小部件 ──

  Widget _wordCard(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
    );
  }

  Widget _sentenceCard(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            fontStyle: FontStyle.italic,
          )),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ));
  }

  Widget _resultRow(ThemeData theme, String label, String value,
      {bool highlight = false, bool italic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                )),
          ),
          Expanded(
            child: Container(
              padding: highlight
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : null,
              decoration: highlight
                  ? BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontStyle: italic ? FontStyle.italic : null,
                    fontWeight: highlight ? FontWeight.w500 : null,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptBox(ThemeData theme, {
    required IconData icon,
    required Color color,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
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
          Expanded(
            child: Text(message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.9),
                )),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
