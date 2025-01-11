import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// 知乎页面部件
class ZhihuPage extends StatefulWidget {
  late final Future<ZhihuApiResponse> futureData;

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
                    onTap: () => _searchOnBaidu(item.displayQuery),
                    onLongPress: () => _copyToClipboard('${index + 1}. ${item.displayQuery}'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: const Icon(
                        Icons.question_answer,
                        size: 50,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${item.displayQuery}',
                              style: const TextStyle(
                                fontSize: 16, // 调整字体大小
                                fontWeight: FontWeight.bold,
                              ),
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
  final response = await http.get(Uri.parse('https://60s.viki.moe/zhihu'));

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
  final String displayQuery;

  ZhihuItem({required this.displayQuery});

  factory ZhihuItem.fromJson(Map<String, dynamic> json) {
    return ZhihuItem(
      displayQuery: json['display_query'] ?? '', // Default to empty string if null
    );
  }
}
