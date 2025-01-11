// ignore_for_file: use_key_in_widget_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// 抖音页面部件
class DouyinPage extends StatefulWidget {
  @override
  _DouyinPageState createState() => _DouyinPageState();
}

class _DouyinPageState extends State<DouyinPage> {
  late Future<DouyinApiResponse> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = fetchDouyinData();
  }

  // 刷新数据
  void _refreshData() {
    setState(() {
      _futureData = fetchDouyinData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('抖音热搜'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData, // 刷新按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<DouyinApiResponse>(
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
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _searchOnBaidu(item.title),
                    onLongPress: () => _copyToClipboard('${index + 1}. ${item.title}'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: item.coverUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item.coverUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : null,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${item.title}',
                              style: const TextStyle(
                                fontSize: 16, // 调整字体大小
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '热度值: ${item.hotValue}',
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

// 抖音 API 数据模型类
Future<DouyinApiResponse> fetchDouyinData() async {
  final response = await http.get(Uri.parse('https://60s.viki.moe/douyin'));

  if (response.statusCode == 200) {
    return DouyinApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Douyin data');
  }
}

class DouyinApiResponse {
  final List<DouyinItem> items;

  DouyinApiResponse({required this.items});

  factory DouyinApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<DouyinItem> itemList = list.map((i) => DouyinItem.fromJson(i)).toList();
    return DouyinApiResponse(items: itemList);
  }
}

class DouyinItem {
  final String coverUrl;
  final String title;
  final int hotValue;

  DouyinItem({required this.coverUrl, required this.title, required this.hotValue});

  factory DouyinItem.fromJson(Map<String, dynamic> json) {
    return DouyinItem(
      coverUrl: json['cover'] ?? '', // Default to empty string if null
      title: json['word'] ?? '',    // Default to empty string if null
      hotValue: json['hot_value'] ?? 0, // Default to 0 if null
    );
  }
}
