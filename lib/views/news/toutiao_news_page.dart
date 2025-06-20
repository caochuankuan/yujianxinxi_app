import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yifeng_site/models/toutiao_news_model.dart';
import 'package:yifeng_site/services/toutiao_news_api.dart';

// 新闻页面部件
class ToutiaoNewsPage extends StatefulWidget {
  const ToutiaoNewsPage({super.key});

  @override
  _ToutiaoNewsPageState createState() => _ToutiaoNewsPageState();
}

class _ToutiaoNewsPageState extends State<ToutiaoNewsPage> {
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
