import 'package:shared_preferences/shared_preferences.dart';

/// API 配置模型 —— 管理大模型连接参数，支持 SharedPreferences 持久化
class AIConfig {
  static const _keyBaseUrl = 'ai_base_url';
  static const _keyApiKey = 'ai_api_key';
  static const _keyModel = 'ai_model';

  static const defaultBaseUrl = 'https://api.openai.com/v1';
  static const defaultModel = 'gpt-4o-mini';

  final String baseUrl;
  final String apiKey;
  final String model;

  const AIConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  bool get isConfigured => apiKey.isNotEmpty && baseUrl.isNotEmpty;

  /// 从 SharedPreferences 读取配置
  static Future<AIConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AIConfig(
      baseUrl: prefs.getString(_keyBaseUrl) ?? defaultBaseUrl,
      apiKey: prefs.getString(_keyApiKey) ?? '',
      model: prefs.getString(_keyModel) ?? defaultModel,
    );
  }

  /// 保存到 SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, baseUrl);
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyModel, model);
  }

  AIConfig copyWith({String? baseUrl, String? apiKey, String? model}) {
    return AIConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}
