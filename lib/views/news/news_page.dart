import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// 新闻页面部件
class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<NewsApiResponse> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = fetchNewsData();
  }

  // 刷新数据
  void _refreshData() {
    setState(() {
      _futureData = fetchNewsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('头条热搜'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData, // 刷新按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<NewsApiResponse>(
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
                    onTap: () => _launchURL(item.link),
                    onLongPress: () => _copyToClipboard('${index + 1}. ${item.title}'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: item.cover.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item.cover,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.article, size: 50),
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

// 新闻 API 数据模型类
Future<NewsApiResponse> fetchNewsData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/toutiao'));

  if (response.statusCode == 200) {
    return NewsApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load news data');
  }
}

class NewsApiResponse {
  final List<NewsItem> items;

  NewsApiResponse({required this.items});

  factory NewsApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<NewsItem> itemList = list.map((i) => NewsItem.fromJson(i)).toList();
    return NewsApiResponse(items: itemList);
  }
}

class NewsItem {
  final String title;
  final int hotValue;
  final String cover;
  final String link;

  NewsItem({
    required this.title,
    required this.hotValue,
    required this.cover,
    required this.link,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] ?? '',
      hotValue: json['hot_value'] ?? 0,
      cover: json['cover'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

class NewsParams {
  final int fakeClickCount;

  NewsParams({required this.fakeClickCount});

  factory NewsParams.fromJson(Map<String, dynamic> json) {
    return NewsParams(
      fakeClickCount: json['fake_click_cnt'] ?? 0, // Default to 0 if null
    );
  }
}
