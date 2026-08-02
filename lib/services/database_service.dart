import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/book.dart';
import '../models/word_annotation.dart';

/// SQLite 数据库服务 —— 管理书架、生词本、长难句解析记录
///
/// 单例模式，通过 [DatabaseService.instance] 访问。
class DatabaseService {
  // ── 单例 ──

  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  /// 获取数据库实例（延迟初始化）
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'linguo_reader.db'),
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── 建表 ──

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT DEFAULT 'Unknown',
        file_path TEXT NOT NULL,
        format TEXT NOT NULL,
        imported_at TEXT NOT NULL,
        last_opened_at TEXT NOT NULL,
        progress REAL DEFAULT 0.0,
        cover_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE word_annotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL,
        word TEXT NOT NULL,
        pronunciation TEXT,
        definition TEXT,
        part_of_speech TEXT,
        context_meaning TEXT,
        example_sentence TEXT,
        synonyms TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sentence_analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL,
        sentence TEXT NOT NULL,
        translation TEXT,
        grammar_notes TEXT,
        structure_breakdown TEXT,
        key_phrases TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id)
      )
    ''');

    // v2 新增：生词本
    await db.execute('''
      CREATE TABLE vocabulary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        pronunciation TEXT,
        definition TEXT,
        context_sentence TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vocabulary (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word TEXT NOT NULL,
          pronunciation TEXT,
          definition TEXT,
          context_sentence TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ── 书籍 CRUD ──

  Future<void> insertBook(Book book) async {
    final d = await database;
    await d.insert('books', book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Book>> getBooks() async {
    final d = await database;
    final maps = await d.query('books', orderBy: 'last_opened_at DESC');
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<void> updateProgress(String bookId, double progress) async {
    final d = await database;
    await d.update(
        'books',
        {
          'progress': progress,
          'last_opened_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [bookId]);
  }

  Future<void> deleteBook(String bookId) async {
    final d = await database;
    await d.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  // ── 单词注解 ──

  Future<void> insertAnnotation(String bookId, WordAnnotation annotation) async {
    final d = await database;
    await d.insert('word_annotations', {
      'book_id': bookId,
      ...annotation.toMap(),
    });
  }

  Future<List<WordAnnotation>> getAnnotations(String bookId) async {
    final d = await database;
    final maps = await d.query('word_annotations',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'created_at DESC');
    return maps.map((m) => WordAnnotation.fromMap(m)).toList();
  }

  // ── 长难句解析 ──

  Future<void> insertSentenceAnalysis(
      String bookId, SentenceAnalysis analysis) async {
    final d = await database;
    await d.insert('sentence_analyses', {
      'book_id': bookId,
      ...analysis.toMap(),
    });
  }

  Future<List<SentenceAnalysis>> getSentenceAnalyses(String bookId) async {
    final d = await database;
    final maps = await d.query('sentence_analyses',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'created_at DESC');
    return maps.map((m) => SentenceAnalysis.fromMap(m)).toList();
  }

  // ── 生词本 CRUD ──

  /// 添加单词到生词本
  Future<void> insertVocabulary(VocabularyWord word) async {
    final d = await database;
    await d.insert('vocabulary', word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 获取所有生词（按时间倒序）
  Future<List<VocabularyWord>> getVocabulary() async {
    final d = await database;
    final maps = await d.query('vocabulary', orderBy: 'created_at DESC');
    return maps.map((m) => VocabularyWord.fromMap(m)).toList();
  }

  /// 删除指定生词
  Future<void> deleteVocabulary(int id) async {
    final d = await database;
    await d.delete('vocabulary', where: 'id = ?', whereArgs: [id]);
  }

  /// 检查单词是否已在生词本中
  Future<bool> hasVocabularyWord(String word) async {
    final d = await database;
    final count = Sqflite.firstIntValue(
      await d.rawQuery('SELECT COUNT(*) FROM vocabulary WHERE word = ?', [word]),
    );
    return (count ?? 0) > 0;
  }
}
