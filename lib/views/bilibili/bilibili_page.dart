import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:yifeng_site/models/bilibili_item.dart';
import 'package:yifeng_site/services/bilibili_api.dart';

class BilibiliPage extends StatefulWidget {
  const BilibiliPage({super.key});

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
