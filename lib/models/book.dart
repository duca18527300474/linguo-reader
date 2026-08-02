/// 电子书数据模型
class Book {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final BookFormat format;
  final DateTime importedAt;
  final DateTime lastOpenedAt;
  final double progress; // 0.0 ~ 1.0
  final String? coverPath;

  const Book({
    required this.id,
    required this.title,
    this.author = 'Unknown',
    required this.filePath,
    required this.format,
    required this.importedAt,
    required this.lastOpenedAt,
    this.progress = 0.0,
    this.coverPath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'file_path': filePath,
        'format': format.name,
        'imported_at': importedAt.toIso8601String(),
        'last_opened_at': lastOpenedAt.toIso8601String(),
        'progress': progress,
        'cover_path': coverPath,
      };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String,
        title: map['title'] as String,
        author: (map['author'] as String?) ?? 'Unknown',
        filePath: map['file_path'] as String,
        format: BookFormat.values.byName(map['format'] as String),
        importedAt: DateTime.parse(map['imported_at'] as String),
        lastOpenedAt: DateTime.parse(map['last_opened_at'] as String),
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        coverPath: map['cover_path'] as String?,
      );

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    BookFormat? format,
    DateTime? importedAt,
    DateTime? lastOpenedAt,
    double? progress,
    String? coverPath,
  }) =>
      Book(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        filePath: filePath ?? this.filePath,
        format: format ?? this.format,
        importedAt: importedAt ?? this.importedAt,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
        progress: progress ?? this.progress,
        coverPath: coverPath ?? this.coverPath,
      );
}

enum BookFormat { epub, txt }
