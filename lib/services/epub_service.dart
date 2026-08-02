import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';

/// EPUB / TXT 文件解析服务
class EpubService {
  final Uuid _uuid = const Uuid();

  // ── 统一入口 ──

  /// 根据扩展名自动识别格式并导入
  Future<Book> importBook(String filePath) async {
    final ext = filePath.split('.').last.toLowerCase();
    if (ext == 'epub') return _importEpub(filePath);
    if (ext == 'txt') return _importTxt(filePath);
    throw Exception('不支持的格式: .$ext（仅支持 .epub / .txt）');
  }

  /// 加载书籍的可读文本内容（供阅读器渲染）
  Future<String> loadContent(Book book) async {
    if (book.format == BookFormat.epub) {
      return _loadEpubContent(book.filePath);
    } else {
      return _loadTxtContent(book.filePath);
    }
  }

  // ── EPUB ──

  Future<Book> _importEpub(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('文件不存在: $filePath');

    final bytes = await file.readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);

    final title = epubBook.Title ?? _fileNameWithoutExt(filePath);
    final author = epubBook.Author ?? 'Unknown';

    // 提取封面
    String? coverPath;
    if (epubBook.CoverImage != null && epubBook.CoverImage!.isNotEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      coverPath = '${dir.path}/covers/${_uuid.v4()}.jpg';
      await Directory('${dir.path}/covers').create(recursive: true);
      await File(coverPath).writeAsBytes(epubBook.CoverImage!);
    }

    // 复制到应用内部存储
    final destPath = await _copyToAppStorage(file, 'epub');

    final now = DateTime.now();
    return Book(
      id: _uuid.v4(),
      title: title,
      author: author,
      filePath: destPath,
      format: BookFormat.epub,
      importedAt: now,
      lastOpenedAt: now,
      coverPath: coverPath,
    );
  }

  Future<String> _loadEpubContent(String epubPath) async {
    final bytes = await File(epubPath).readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);
    final buffer = StringBuffer();

    final chapters = epubBook.Chapters;
    if (chapters != null && chapters.isNotEmpty) {
      for (int i = 0; i < chapters.length; i++) {
        final ch = chapters[i];
        final title = ch.Title ?? '第${i + 1}章';
        final text = _stripHtml(ch.HtmlContent ?? '');
        if (text.trim().isNotEmpty) {
          buffer.writeln(title);
          buffer.writeln('');
          buffer.writeln(text);
          buffer.writeln('');
        }
      }
    }

    return buffer.toString().trim();
  }

  // ── TXT ──

  Future<Book> _importTxt(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('文件不存在: $filePath');

    final title = _fileNameWithoutExt(filePath);
    final destPath = await _copyToAppStorage(file, 'txt');
    final now = DateTime.now();

    return Book(
      id: _uuid.v4(),
      title: title,
      author: 'Unknown',
      filePath: destPath,
      format: BookFormat.txt,
      importedAt: now,
      lastOpenedAt: now,
    );
  }

  Future<String> _loadTxtContent(String txtPath) async {
    // 尝试 UTF-8，失败则用 GBK/Latin-1 兜底
    final file = File(txtPath);
    String content;
    try {
      content = await file.readAsString(encoding: utf8);
    } catch (_) {
      content = await file.readAsString(encoding: latin1);
    }
    return content;
  }

  // ── 工具方法 ──

  /// 复制文件到应用内部存储，避免原文件被删除后无法读取
  Future<String> _copyToAppStorage(File source, String ext) async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${appDir.path}/books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    final destPath = '${booksDir.path}/${_uuid.v4()}.$ext';
    await source.copy(destPath);
    return destPath;
  }

  /// 从路径提取文件名（不含扩展名）
  String _fileNameWithoutExt(String path) {
    final name = path.split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  /// 去除 HTML 标签，保留纯文本
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .trim();
  }
}

// ── 顶层工具（供外部直接使用） ──

/// 简单去除 HTML 标签
String stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
      .trim();
}
