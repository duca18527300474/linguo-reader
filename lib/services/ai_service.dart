import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/ai_config.dart';

/// AI 词语分析结果
class WordAnalysis {
  final String word;
  final String? pronunciation;
  final String? partOfSpeech;
  final String? definition;
  final String? contextMeaning;
  final String? example;

  const WordAnalysis({
    required this.word,
    this.pronunciation,
    this.partOfSpeech,
    this.definition,
    this.contextMeaning,
    this.example,
  });

  factory WordAnalysis.fromJson(Map<String, dynamic> json) => WordAnalysis(
        word: json['word'] as String? ?? '',
        pronunciation: json['pronunciation'] as String?,
        partOfSpeech: json['part_of_speech'] as String?,
        definition: json['definition'] as String?,
        contextMeaning: json['context_meaning'] as String?,
        example: json['example'] as String?,
      );
}

/// AI 长难句分析结果
class SentenceAnalysis {
  final String? translation;
  final String? grammarBreakdown;
  final List<String>? keyVocabulary;

  const SentenceAnalysis({
    this.translation,
    this.grammarBreakdown,
    this.keyVocabulary,
  });

  factory SentenceAnalysis.fromJson(Map<String, dynamic> json) => SentenceAnalysis(
        translation: json['translation'] as String?,
        grammarBreakdown:
            json['grammar_breakdown'] as String? ?? json['grammar_notes'] as String?,
        keyVocabulary: (json['key_vocabulary'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
}

// ═══════════════════════════════════════════════════════════════
// AI 服务
// ═══════════════════════════════════════════════════════════════

/// 大模型 API 服务 —— OpenAI 兼容接口
///
/// 适配: ChatGPT / DeepSeek / Claude / 自建 OneAPI 代理 等
class AIService {
  final AIConfig config;
  late final Dio _dio;

  /// 最后一次错误的描述信息
  String? lastError;

  AIService({required this.config}) {
    _dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
    ));
  }

  // ── 单词查询 ──

  /// 根据上下文查询单词的语境释义
  Future<WordAnalysis?> lookupWord(String word, String context) async {
    lastError = null;

    final prompt = _buildWordPrompt(word, context);

    try {
      final content = await _callChatCompletions(prompt);
      if (content == null) return null;

      final json = _extractJson(content);
      if (json == null) {
        lastError = 'AI 返回格式异常，请重试';
        return null;
      }

      return WordAnalysis.fromJson(json);
    } on DioException catch (e) {
      lastError = _dioErrorToMessage(e);
      return null;
    } catch (e) {
      lastError = '解析失败: $e';
      return null;
    }
  }

  // ── 长难句解析 ──

  /// 分析长难句的语法结构与翻译
  Future<SentenceAnalysis?> analyzeSentence(String sentence) async {
    lastError = null;

    final prompt = _buildSentencePrompt(sentence);

    try {
      final content = await _callChatCompletions(prompt);
      if (content == null) return null;

      final json = _extractJson(content);
      if (json == null) {
        lastError = 'AI 返回格式异常，请重试';
        return null;
      }

      return SentenceAnalysis.fromJson(json);
    } on DioException catch (e) {
      lastError = _dioErrorToMessage(e);
      return null;
    } catch (e) {
      lastError = '解析失败: $e';
      return null;
    }
  }

  // ── 底层 HTTP 调用 ──

  Future<String?> _callChatCompletions(String userPrompt) async {
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': config.model,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个英语阅读助手。你必须只返回合法的 JSON 对象，不要包含任何 markdown 标记或其他文字。'
          },
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
        'max_tokens': 2048,
      },
    );

    final choices = response.data?['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      lastError = 'AI 未返回有效响应';
      return null;
    }

    return choices[0]['message']['content'] as String?;
  }

  // ── Prompt 模板 ──

  String _buildWordPrompt(String word, String context) {
    return '''你是一个英语阅读助手。用户正在阅读英文书籍，点击了单词 "$word"。

上下文句子：
---
$context
---

请分析该单词在此语境中的含义，严格返回以下 JSON（不要 markdown 标记）：

{
  "word": "$word",
  "pronunciation": "IPA 音标",
  "part_of_speech": "词性（如 noun/verb/adjective）",
  "definition": "英文词典释义",
  "context_meaning": "在此句子中的中文含义",
  "example": "一个简单的英文例句"
}''';
  }

  String _buildSentencePrompt(String sentence) {
    return '''你是一个英语阅读导师。请分析以下英文长难句，帮助中文母语者理解。

"$sentence"

严格返回以下 JSON（不要 markdown 标记）：

{
  "translation": "地道的中文翻译",
  "grammar_breakdown": "中文语法分析：拆解句子结构，说明主谓宾、从句类型等",
  "key_vocabulary": ["难词或短语1", "难词或短语2"]
}''';
  }

  // ── JSON 提取 ──

  /// 从 AI 返回的文本中健壮地提取 JSON 对象
  Map<String, dynamic>? _extractJson(String raw) {
    final trimmed = raw.trim();

    // 1) 直接解析
    try {
      return json.decode(trimmed) as Map<String, dynamic>;
    } catch (_) {}

    // 2) 去掉 ```json ... ``` 包裹
    final fencePattern = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final fenceMatch = fencePattern.firstMatch(trimmed);
    if (fenceMatch != null) {
      try {
        return json.decode(fenceMatch.group(1)!.trim()) as Map<String, dynamic>;
      } catch (_) {}
    }

    // 3) 提取第一个 { ... } 对（支持嵌套）
    final bracePattern = RegExp(r'\{(?:[^{}]|\{[^{}]*\})*\}');
    final braceMatch = bracePattern.firstMatch(trimmed);
    if (braceMatch != null) {
      try {
        return json.decode(braceMatch.group(0)!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return null;
  }

  // ── 错误映射 ──

  String _dioErrorToMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '请求超时，请检查网络连接';
      case DioExceptionType.connectionError:
        return '无法连接到服务器，请检查 API 地址';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'API Key 无效，请在设置中更新';
        if (code == 403) return '访问被拒绝，请检查 API Key 权限';
        if (code == 404) return '接口不存在，请检查 API Base URL';
        if (code == 429) return '请求过于频繁，请稍后重试';
        if (code != null && code >= 500) return '服务器错误（$code），请稍后重试';
        return '请求失败（$code）';
      default:
        return '网络错误: ${e.message}';
    }
  }
}
