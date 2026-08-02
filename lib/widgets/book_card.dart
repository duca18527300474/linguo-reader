import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';

/// 书架网格/列表中的书籍卡片组件
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: book.coverPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(book.coverPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : _buildPlaceholderCover(context),
              ),
            ),
            const SizedBox(height: 8),
            // 书名
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            if (book.progress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                  value: book.progress,
                  minHeight: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book,
            size: 32,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            book.format == BookFormat.epub ? 'EPUB' : 'TXT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
