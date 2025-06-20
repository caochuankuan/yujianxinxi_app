import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yifeng_site/views/browser/browser_page.dart';

void showSpotlightSearchDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BackdropGroup(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter.grouped(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: MediaQuery.of(context).size.width > 500 ? 400 : MediaQuery.of(context).size.width * 0.92,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: '搜索…',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 20),
                              onSubmitted: (value) async {
                                Navigator.of(context).pop();
                                if (value.trim().isNotEmpty) {
                                  final url = 'https://www.baidu.com/s?wd=${Uri.encodeComponent(value)}';
                                  try {
                                    final uri = Uri.parse(url);
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    try {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BrowserPage(
                                            isShowAppBar: true,
                                            url: url,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      // 打开失败，复制到剪贴板
                                      await Clipboard.setData(ClipboardData(text: url));
                                      Fluttertoast.showToast(msg: "无法打开链接，地址已复制，请用浏览器粘贴访问");
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black38),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 16),
                      // 可扩展：搜索建议、历史、热词等
                      // const Text('搜索历史/建议区域', style: TextStyle(color: Colors.black45)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}