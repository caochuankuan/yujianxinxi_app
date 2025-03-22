// ignore_for_file: use_key_in_widget_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// B 站页面部件
class BilibiliPage extends StatefulWidget {
  @override
  _BilibiliPageState createState() => _BilibiliPageState();
}

class _BilibiliPageState extends State<BilibiliPage> {
  late Future<BilibiliApiResponse> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = fetchBilibiliData();
  }

  // 刷新数据
  void _refreshData() {
    setState(() {
      _futureData = fetchBilibiliData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('B站热搜'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData, // 刷新按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<BilibiliApiResponse>(
        future: _futureData,
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
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${index + 1}. ${item.title}',  // 使用 title 替代 keyword
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: null,  // 移除热度 ID 显示
                    onTap: () => _launchURL(item.link),  // 直接使用 link 打开链接
                    onLongPress: () => _copyToClipboard(item.title),  // 复制标题
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
  
    // 跳转到链接
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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

// B 站 API 数据模型类
Future<BilibiliApiResponse> fetchBilibiliData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/bili'));

  if (response.statusCode == 200) {
    return BilibiliApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Bilibili data');
  }
}

class BilibiliApiResponse {
  final List<BilibiliItem> items;

  BilibiliApiResponse({required this.items});

  factory BilibiliApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<BilibiliItem> itemList = list.map((i) => BilibiliItem.fromJson(i)).toList();
    return BilibiliApiResponse(items: itemList);
  }
}

class BilibiliItem {
  final String title;  // 改用 title 替代 keyword
  final String link;   // 改用 link 替代 icon
  final int position;  // 保持 position 用于显示序号

  BilibiliItem({
    required this.title,
    required this.link,
    required this.position,
  });

  factory BilibiliItem.fromJson(Map<String, dynamic> json) {
    int counter = 0;  // 用于生成位置序号
    return BilibiliItem(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      position: ++counter,  // 自动生成序号
    );
  }
}
