// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// 微博页面部件
class WeiboPage extends StatefulWidget {

  WeiboPage({super.key});

  @override
  _WeiboPageState createState() => _WeiboPageState();
}

class _WeiboPageState extends State<WeiboPage> {
  late Future<WeiboApiResponse> futureData;
    
  @override
  void initState() {
    super.initState();
    futureData = fetchWeiboData();
  }
  
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
                futureData = fetchWeiboData();
              });
            }, // 刷新按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<WeiboApiResponse>(
        future: futureData,
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
                    onTap: () => _launchURL(item.link),
                    onLongPress: () => _copyToClipboard('${index + 1}. ${item.title}'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${item.title}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '热度: ${item.hotValue}',
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
  void _launchURL(String url) async {
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
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/weibo'));

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
  final String title;
  final int hotValue;
  final String link;

  WeiboItem({
    required this.title,
    required this.hotValue,
    required this.link,
  });

  factory WeiboItem.fromJson(Map<String, dynamic> json) {
    return WeiboItem(
      title: json['title'] ?? '',
      hotValue: json['hot_value'] ?? 0,
      link: json['link'] ?? '',
    );
  }
}
