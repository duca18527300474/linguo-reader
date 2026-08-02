import 'package:flutter/material.dart';

import '../models/word_annotation.dart';
import '../services/database_service.dart';

/// 生词本页面 —— 展示所有已收藏的单词，按时间倒序，支持侧滑删除
class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  List<VocabularyWord> _words = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    final words = await DatabaseService.instance.getVocabulary();
    if (mounted) {
      setState(() {
        _words = words;
        _loading = false;
      });
    }
  }

  Future<void> _deleteWord(VocabularyWord word) async {
    if (word.id == null) return;
    await DatabaseService.instance.deleteVocabulary(word.id!);
    if (mounted) {
      setState(() => _words.remove(word));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('已删除「${word.word}」'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('生词本'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? _buildEmptyState(theme)
              : _buildWordList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_outline, size: 72,
              color: Colors.grey[350]),
          const SizedBox(height: 16),
          Text('生词本为空',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[500],
              )),
          const SizedBox(height: 8),
          Text('在阅读时点击单词旁边的 ☆ 即可收藏',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[400],
              )),
        ],
      ),
    );
  }

  Widget _buildWordList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _words.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final w = _words[index];
        return Dismissible(
          key: ValueKey(w.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: theme.colorScheme.errorContainer,
            child: Icon(Icons.delete_outline,
                color: theme.colorScheme.onErrorContainer),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('确认删除'),
                content: Text('确定要删除「${w.word}」吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('删除'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => _deleteWord(w),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Row(
              children: [
                Text(w.word,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    )),
                if (w.pronunciation != null) ...[
                  const SizedBox(width: 10),
                  Text('/${w.pronunciation}/',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      )),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (w.definition != null) ...[
                  const SizedBox(height: 4),
                  Text(w.definition!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      )),
                ],
                if (w.contextSentence != null) ...[
                  const SizedBox(height: 4),
                  Text(w.contextSentence!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      )),
                ],
              ],
            ),
            trailing: Text(
              _formatDate(w.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey[400],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
