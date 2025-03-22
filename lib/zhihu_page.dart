import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// 知乎页面部件
class ZhihuPage extends StatefulWidget {
  Future<ZhihuApiResponse> futureData;

  ZhihuPage({required this.futureData});

  @override
  _ZhihuPageState createState() => _ZhihuPageState();
}

class _ZhihuPageState extends State<ZhihuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('知乎热搜'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                widget.futureData = fetchZhihuData();
              });
            }, // 刷新按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<ZhihuApiResponse>(
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
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _searchOnBaidu(item.title),
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
                          : const Icon(Icons.question_answer, size: 50),
                      title: Text(
                        '${index + 1}. ${item.title}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            item.hotValueDesc,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${item.answerCount} 回答 · ${item.followerCount} 关注',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

// 知乎 API 数据模型类
Future<ZhihuApiResponse> fetchZhihuData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/zhihu'));

  if (response.statusCode == 200) {
    return ZhihuApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Zhihu data');
  }
}

class ZhihuApiResponse {
  final List<ZhihuItem> items;

  ZhihuApiResponse({required this.items});

  factory ZhihuApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<ZhihuItem> itemList = list.map((i) => ZhihuItem.fromJson(i)).toList();
    return ZhihuApiResponse(items: itemList);
  }
}

class ZhihuItem {
  final String title;
  final String detail;
  final String cover;
  final String hotValueDesc;
  final int answerCount;
  final int followerCount;
  final String link;

  ZhihuItem({
    required this.title,
    required this.detail,
    required this.cover,
    required this.hotValueDesc,
    required this.answerCount,
    required this.followerCount,
    required this.link,
  });

  factory ZhihuItem.fromJson(Map<String, dynamic> json) {
    return ZhihuItem(
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      cover: json['cover'] ?? '',
      hotValueDesc: json['hot_value_desc'] ?? '',
      answerCount: json['answer_cnt'] ?? 0,
      followerCount: json['follower_cnt'] ?? 0,
      link: json['link'] ?? '',
    );
  }
}
