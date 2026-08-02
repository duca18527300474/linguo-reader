import 'package:flutter/material.dart';

/// 阅读器中点击单词/句子时弹出的通用底部弹窗
class ReaderBottomSheet extends StatelessWidget {
  final Widget child;

  const ReaderBottomSheet({super.key, required this.child});

  /// 显示底部弹窗
  static Future<void> show(BuildContext context, Widget child) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReaderBottomSheet(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }
}
