import 'package:flutter_test/flutter_test.dart';

import 'package:linguo_reader/models/book.dart';

void main() {
  group('Book Model', () {
    test('toMap and fromMap should be inverses', () {
      final book = Book(
        id: 'test-id',
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/book.epub',
        format: BookFormat.epub,
        importedAt: DateTime(2026, 1, 1),
        lastOpenedAt: DateTime(2026, 8, 1),
        progress: 0.42,
      );

      final map = book.toMap();
      final restored = Book.fromMap(map);

      expect(restored.id, book.id);
      expect(restored.title, book.title);
      expect(restored.format, book.format);
      expect(restored.progress, book.progress);
    });

    test('copyWith should preserve unchanged fields', () {
      final book = Book(
        id: 'id',
        title: 'Title',
        author: 'Author',
        filePath: '/path',
        format: BookFormat.txt,
        importedAt: DateTime(2026, 1, 1),
        lastOpenedAt: DateTime(2026, 1, 1),
      );

      final updated = book.copyWith(progress: 0.5);

      expect(updated.progress, 0.5);
      expect(updated.title, book.title); // unchanged
      expect(updated.format, book.format); // unchanged
    });
  });
}
