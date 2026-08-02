/// ─── 文本分词服务 ────────────────────────────────────────────
/// 将原始文本拆分为：段落 → 句子 → 单词 / 标点 Token，
/// 为阅读器的"点词查词"和"长按析句"提供结构数据。

/// Token 类型
enum TokenType {
  word,          // 英文单词 / 数字
  punctuation,   // 标点符号
  space,         // 空格
  paragraphBreak,// 段落间空行
}

/// 单个文本 Token（单词或标点或空格）
class TextToken {
  final String text;
  final TokenType type;
  final int sentenceIndex; // 所属句子索引

  const TextToken({
    required this.text,
    required this.type,
    required this.sentenceIndex,
  });

  bool get isWord => type == TokenType.word;
  bool get isSpace => type == TokenType.space;

  @override
  String toString() =>
      'TextToken("$text", $type, sentence:$sentenceIndex)';
}

/// 句子信息
class SentenceInfo {
  final int index;
  final String text; // 完整句子文本（不含首尾多余空格）

  const SentenceInfo({required this.index, required this.text});

  @override
  String toString() => 'SentenceInfo(#$index, "$text")';
}

/// 分词结果
class ParsedText {
  final List<TextToken> tokens;
  final List<SentenceInfo> sentences;

  const ParsedText({required this.tokens, required this.sentences});

  /// 根据 token 索引查找所属句子
  SentenceInfo sentenceOf(TextToken token) => sentences[token.sentenceIndex];
}

/// 文本分词器
class TextTokenizer {
  // 不应被误认为句子结束的词（缩写等）
  static final Set<String> _abbreviations = {
    'Mr', 'Mrs', 'Ms', 'Dr', 'Prof', 'St', 'vs', 'etc',
    'e.g', 'i.e', 'a.m', 'p.m', 'U.S', 'U.K',
  };

  /// 将原始文本解析为结构化 Token 流
  static ParsedText tokenize(String rawText) {
    // ── Step 1: 按段落拆分（双换行或更多） ──
    final paragraphs = rawText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'\n\s*\n+'));

    final allTokens = <TextToken>[];
    final allSentences = <SentenceInfo>[];

    for (int p = 0; p < paragraphs.length; p++) {
      final para = paragraphs[p].trim();
      if (para.isEmpty) continue;

      // ── Step 2: 按句子拆分 ──
      final rawSentences = _splitSentences(para);
      final sentenceStartIndices = <int>[];

      for (final raw in rawSentences) {
        if (raw.trim().isEmpty) continue;
        sentenceStartIndices.add(allSentences.length);
        allSentences.add(SentenceInfo(
          index: allSentences.length,
          text: raw.trim(),
        ));
      }

      // ── Step 3: 将每个句子拆分为 Token ──
      for (int s = 0; s < rawSentences.length; s++) {
        final sentIdx = sentenceStartIndices[s];
        final sentTokens = _tokenizeSentence(rawSentences[s], sentIdx);
        allTokens.addAll(sentTokens);
      }

      // ── Step 4: 段落间加一个分隔 Token ──
      if (p < paragraphs.length - 1 && _nextParaNonEmpty(paragraphs, p)) {
        allTokens.add(const TextToken(
          text: '\n\n',
          type: TokenType.paragraphBreak,
          sentenceIndex: -1,
        ));
      }
    }

    return ParsedText(tokens: allTokens, sentences: allSentences);
  }

  // ── 句子拆分 ──

  static List<String> _splitSentences(String paragraph) {
    final result = <String>[];
    int start = 0;

    for (int i = 0; i < paragraph.length; i++) {
      final ch = paragraph[i];

      // 句子结束符
      if (ch == '.' || ch == '!' || ch == '?') {
        // 检查是否为缩写（如 Mr. Dr.）
        if (ch == '.' && _isAbbreviationAt(paragraph, i)) {
          continue; // 不是句子结束
        }

        // 检查后面的字符：空格+大写字母、换行、或字符串末尾
        final next = i + 1 < paragraph.length ? paragraph[i + 1] : null;
        final afterNext = i + 2 < paragraph.length ? paragraph[i + 2] : null;

        final isEndOfText = i == paragraph.length - 1;
        final followedByNewline = next == '\n';
        final followedBySpaceAndUpper =
            (next == ' ' || next == '\t') &&
                afterNext != null &&
                afterNext == afterNext.toUpperCase() &&
                afterNext != afterNext.toLowerCase();

        if (isEndOfText || followedByNewline || followedBySpaceAndUpper) {
          // 切割句子
          final sentence = paragraph.substring(start, i + 1);
          result.add(sentence);

          // 跳过句号后的空格 / 换行
          int skip = i + 1;
          while (skip < paragraph.length &&
              (paragraph[skip] == ' ' || paragraph[skip] == '\t' || paragraph[skip] == '\n')) {
            skip++;
          }
          start = skip;
          i = skip - 1; // for 循环会 +1
        }
      }
    }

    // 最后一个句子（可能没有结束符）
    if (start < paragraph.length) {
      final remainder = paragraph.substring(start).trim();
      if (remainder.isNotEmpty) {
        result.add(remainder);
      }
    }

    return result;
  }

  /// 检查 '.' 是否属于缩写词（Mr. Dr. etc.）
  static bool _isAbbreviationAt(String text, int dotIndex) {
    // 向前找到 '.' 前的单词
    int wordStart = dotIndex - 1;
    while (wordStart >= 0 && _isLetter(text[wordStart])) {
      wordStart--;
    }
    wordStart++;

    final word = text.substring(wordStart, dotIndex);
    return _abbreviations.contains(word);
  }

  // ── 单词 / Token 拆分 ──

  static List<TextToken> _tokenizeSentence(String sentence, int sentenceIndex) {
    final tokens = <TextToken>[];
    int i = 0;

    while (i < sentence.length) {
      final ch = sentence[i];

      if (ch == ' ' || ch == '\t') {
        // 空格（合并连续空格）
        int end = i;
        while (end < sentence.length && (sentence[end] == ' ' || sentence[end] == '\t')) {
          end++;
        }
        tokens.add(TextToken(
          text: sentence.substring(i, end),
          type: TokenType.space,
          sentenceIndex: sentenceIndex,
        ));
        i = end;
      } else if (_isWordChar(ch)) {
        // 单词 / 数字（包括缩写中的点，如 "U.S." 但在句子拆分后不应出现）
        int end = i;
        while (end < sentence.length && _isWordChar(sentence[end])) {
          end++;
        }
        tokens.add(TextToken(
          text: sentence.substring(i, end),
          type: TokenType.word,
          sentenceIndex: sentenceIndex,
        ));
        i = end;
      } else if (ch == '\n') {
        tokens.add(TextToken(
          text: '\n',
          type: TokenType.space,
          sentenceIndex: sentenceIndex,
        ));
        i++;
      } else {
        // 标点符号（单个字符）
        tokens.add(TextToken(
          text: ch,
          type: TokenType.punctuation,
          sentenceIndex: sentenceIndex,
        ));
        i++;
      }
    }

    return tokens;
  }

  static bool _isWordChar(String ch) {
    final code = ch.codeUnitAt(0);
    // a-z, A-Z, 0-9, 撇号, 连字符
    return (code >= 65 && code <= 90) ||   // A-Z
        (code >= 97 && code <= 122) ||      // a-z
        (code >= 48 && code <= 57) ||       // 0-9
        code == 39 ||                        // '
        code == 8217 ||                       // ’
        code == 45;                           // -
  }

  static bool _isLetter(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  static bool _nextParaNonEmpty(List<String> paragraphs, int current) {
    for (int i = current + 1; i < paragraphs.length; i++) {
      if (paragraphs[i].trim().isNotEmpty) return true;
    }
    return false;
  }
}
