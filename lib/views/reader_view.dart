import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/text_tokenizer.dart';
import '../widgets/annotation_panel.dart';
import '../widgets/sentence_analysis_panel.dart';
import 'settings_view.dart';

/// 阅读器页面 —— 支持点词查词、长按析句、字号调节
class ReaderView extends StatefulWidget {
  final Book book;
  final String content;

  const ReaderView({
    super.key,
    required this.book,
    required this.content,
  });

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  final ScrollController _scrollController = ScrollController();

  static const double _minFontSize = 14.0;
  static const double _maxFontSize = 32.0;
  static const double _fontSizeStep = 2.0;

  late double _fontSize;
  late ParsedText _parsedText;
  late List<List<TextToken>> _paragraphs;

  @override
  void initState() {
    super.initState();
    _fontSize = 18.0;
    _parsedText = TextTokenizer.tokenize(widget.content);
    _paragraphs = _splitIntoParagraphs(_parsedText.tokens);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── 将 token 流按 paragraphBreak 分组 ──

  List<List<TextToken>> _splitIntoParagraphs(List<TextToken> tokens) {
    final paragraphs = <List<TextToken>>[];
    var current = <TextToken>[];

    for (final token in tokens) {
      if (token.type == TokenType.paragraphBreak) {
        if (current.isNotEmpty) {
          paragraphs.add(current);
          current = [];
        }
      } else {
        current.add(token);
      }
    }
    if (current.isNotEmpty) paragraphs.add(current);
    return paragraphs;
  }

  // ── 字号控制 ──

  void _zoomIn() {
    setState(() {
      if (_fontSize < _maxFontSize) _fontSize += _fontSizeStep;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_fontSize > _minFontSize) _fontSize -= _fontSizeStep;
    });
  }

  // ── 交互回调 ──

  void _onWordTap(TextToken token) {
    final sentence = _parsedText.sentenceOf(token);
    _showWordLookup(token.text, sentence.text);
  }

  void _onSentenceLongPress(TextToken token) {
    final sentence = _parsedText.sentenceOf(token);
    _showSentenceAnalysis(sentence.text);
  }

  /// 从弹窗内导航到设置页（先关闭弹窗，再推入设置页）
  void _goToSettingsFromSheet() {
    Navigator.of(context).pop(); // 关闭弹窗
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
  }

  // ── 底部弹窗 ──

  void _showWordLookup(String word, String context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AnnotationPanel(
        word: word,
        contextSentence: context,
        onGoToSettings: _goToSettingsFromSheet,
      ),
    );
  }

  void _showSentenceAnalysis(String sentence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SentenceAnalysisPanel(
        sentence: sentence,
        onGoToSettings: _goToSettingsFromSheet,
      ),
    );
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, overflow: TextOverflow.ellipsis),
        actions: [
          _buildFontSizeChip(),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: _fontSize > _minFontSize ? _zoomOut : null,
            tooltip: '缩小文字',
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: _fontSize < _maxFontSize ? _zoomIn : null,
            tooltip: '加大文字',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _paragraphs.isEmpty
          ? const Center(child: Text('未能加载书籍内容'))
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int p = 0; p < _paragraphs.length; p++) ...[
                    _buildParagraph(_paragraphs[p]),
                    if (p < _paragraphs.length - 1)
                      const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }

  /// 渲染一个段落：Wrap → 每个 token 一个 widget
  Widget _buildParagraph(List<TextToken> tokens) {
    return Wrap(
      spacing: 0,
      runSpacing: 0,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final token in tokens) _buildToken(token),
      ],
    );
  }

  /// 渲染单个 Token
  Widget _buildToken(TextToken token) {
    final textStyle = TextStyle(
      fontSize: _fontSize,
      height: 1.7,
      color: Theme.of(context).colorScheme.onSurface,
    );

    switch (token.type) {
      case TokenType.word:
        return GestureDetector(
          onTap: () => _onWordTap(token),
          onLongPress: () => _onSentenceLongPress(token),
          child: Text(token.text, style: textStyle),
        );

      case TokenType.space:
        return Text(token.text, style: textStyle);

      case TokenType.punctuation:
        return Text(token.text, style: textStyle);

      case TokenType.paragraphBreak:
        return const SizedBox.shrink();
    }
  }

  /// AppBar 中间的字号指示器
  Widget _buildFontSizeChip() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          '${_fontSize.toInt()}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
