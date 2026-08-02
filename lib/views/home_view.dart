import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/book.dart';
import '../services/epub_service.dart';
import 'library_view.dart';
import 'reader_view.dart';
import 'settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final EpubService _epubService = EpubService();
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 语境阅读器'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: '生词本',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '欢迎使用 AI 语境阅读器',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '导入 EPUB 或 TXT 电子书，开始智能阅读',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),
            _importing
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: _importBook,
                    icon: const Icon(Icons.add),
                    label: const Text('导入书籍'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _importBook() async {
    // 打开文件选择器
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'txt'],
    );

    // 用户取消选择
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) {
      if (mounted) {
        _showError('无法获取文件路径');
      }
      return;
    }

    setState(() => _importing = true);

    try {
      // 解析文件
      final book = await _epubService.importBook(filePath);
      // 加载文本内容
      final content = await _epubService.loadContent(book);

      if (!mounted) return;

      // 跳转到阅读器
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReaderView(
            book: book,
            content: content,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showError('导入失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
