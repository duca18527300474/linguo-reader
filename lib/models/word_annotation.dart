/// 大模型返回的单词注解
class WordAnnotation {
  final String word;
  final String? pronunciation;    // 音标
  final String? definition;        // 释义
  final String? partOfSpeech;      // 词性
  final String? contextMeaning;    // 在上下文中的具体含义
  final String? exampleSentence;   // 例句
  final List<String>? synonyms;    // 近义词
  final DateTime createdAt;

  const WordAnnotation({
    required this.word,
    this.pronunciation,
    this.definition,
    this.partOfSpeech,
    this.contextMeaning,
    this.exampleSentence,
    this.synonyms,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'word': word,
        'pronunciation': pronunciation,
        'definition': definition,
        'part_of_speech': partOfSpeech,
        'context_meaning': contextMeaning,
        'example_sentence': exampleSentence,
        'synonyms': synonyms?.join(','),
        'created_at': createdAt.toIso8601String(),
      };

  factory WordAnnotation.fromMap(Map<String, dynamic> map) => WordAnnotation(
        word: map['word'] as String,
        pronunciation: map['pronunciation'] as String?,
        definition: map['definition'] as String?,
        partOfSpeech: map['part_of_speech'] as String?,
        contextMeaning: map['context_meaning'] as String?,
        exampleSentence: map['example_sentence'] as String?,
        synonyms: (map['synonyms'] as String?)?.split(','),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// 生词本条目 —— 用户收藏的单词
class VocabularyWord {
  final int? id;
  final String word;
  final String? pronunciation;
  final String? definition;       // 中文释义
  final String? contextSentence;  // 上下文例句
  final DateTime createdAt;

  const VocabularyWord({
    this.id,
    required this.word,
    this.pronunciation,
    this.definition,
    this.contextSentence,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'word': word,
        'pronunciation': pronunciation,
        'definition': definition,
        'context_sentence': contextSentence,
        'created_at': createdAt.toIso8601String(),
      };

  factory VocabularyWord.fromMap(Map<String, dynamic> map) => VocabularyWord(
        id: map['id'] as int?,
        word: map['word'] as String,
        pronunciation: map['pronunciation'] as String?,
        definition: map['definition'] as String?,
        contextSentence: map['context_sentence'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// 长难句解析
class SentenceAnalysis {
  final String sentence;
  final String? translation;       // 中文翻译
  final String? grammarNotes;      // 语法分析
  final String? structureBreakdown; // 句子结构拆解
  final List<String>? keyPhrases;  // 关键短语
  final DateTime createdAt;

  const SentenceAnalysis({
    required this.sentence,
    this.translation,
    this.grammarNotes,
    this.structureBreakdown,
    this.keyPhrases,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'sentence': sentence,
        'translation': translation,
        'grammar_notes': grammarNotes,
        'structure_breakdown': structureBreakdown,
        'key_phrases': keyPhrases?.join(','),
        'created_at': createdAt.toIso8601String(),
      };

  factory SentenceAnalysis.fromMap(Map<String, dynamic> map) => SentenceAnalysis(
        sentence: map['sentence'] as String,
        translation: map['translation'] as String?,
        grammarNotes: map['grammar_notes'] as String?,
        structureBreakdown: map['structure_breakdown'] as String?,
        keyPhrases: (map['key_phrases'] as String?)?.split(','),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
