import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void copyToClipboard(String text, BuildContext context) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('已复制: "$text"'),
      duration: const Duration(seconds: 2),
    ),
  );
}
