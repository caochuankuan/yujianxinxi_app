// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// 微博页面部件
class WeiboPage extends StatefulWidget {
  late final Future<WeiboApiResponse> futureData;

  WeiboPage({required this.futureData});

  @override
  _WeiboPageState createState() => _WeiboPageState();
}

class _WeiboPageState extends State<WeiboPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('微博热搜'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                widget.futureData = fetchWeiboData();
              });
            }, // 刷新按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<WeiboApiResponse>(
        future: widget.futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.items.length,
              itemBuilder: (context, index) {
                final item = snapshot.data!.items[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _searchOnBaidu(item.word),
                    onLongPress: () =>
                        _copyToClipboard('${index + 1}. ${item.word}'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      trailing: item.icon.isEmpty
                          ? null
                          : Image.network(
                              item.icon,
                              width: 35,
                              height: 35,
                            ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${item.word}',
                              style: const TextStyle(
                                fontSize: 16, // 调整字体大小
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '热度: ${item.num}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // 跳转到百度搜索
  void _searchOnBaidu(String query) async {
    final url = 'https://www.baidu.com/s?wd=${Uri.encodeComponent(query)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // 复制文本到剪贴板并显示 SnackBar
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: "$text"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// 微博 API 数据模型类
Future<WeiboApiResponse> fetchWeiboData() async {
  final response = await http.get(Uri.parse('https://60s.viki.moe/weibo'));

  if (response.statusCode == 200) {
    return WeiboApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Weibo data');
  }
}

class WeiboApiResponse {
  final List<WeiboItem> items;

  WeiboApiResponse({required this.items});

  factory WeiboApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<WeiboItem> itemList = list.map((i) => WeiboItem.fromJson(i)).toList();
    return WeiboApiResponse(items: itemList);
  }
}

class WeiboItem {
  final String word;
  final String icon;
  final int num;

  WeiboItem({required this.word, required this.icon, required this.num});

  factory WeiboItem.fromJson(Map<String, dynamic> json) {
    return WeiboItem(
      word: json['word'] ?? '', // Default to empty string if null
      icon: json['icon'] ?? '', // Default to empty string if null
      num: json['num'] ?? 0, // Default to 0 if null
    );
  }
}
