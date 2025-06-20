import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter/services.dart';
import 'package:yifeng_site/models/today_in_history_model.dart';
import 'package:yifeng_site/services/today_in_history_api.dart';

class TodayInHistoryPage extends StatefulWidget {
  const TodayInHistoryPage({super.key});

  @override
  _TodayInHistoryPageState createState() => _TodayInHistoryPageState();
}

class _TodayInHistoryPageState extends State<TodayInHistoryPage> {
  late Future<TodayInHistoryApiResponse> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchTodayInHistoryData(); // 初始化数据
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('历史上的今天'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                futureData = fetchTodayInHistoryData(); // 刷新数据
              });
            }, // 刷新按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<TodayInHistoryApiResponse>(
        future: futureData, // 使用State中的futureData
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          } else {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.events.length,
              itemBuilder: (context, index) {
                final event = data.events[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (event.link.isNotEmpty) {
                        _launchURL(event.link);
                      }
                    },
                    onLongPress: () {
                      _copyToClipboard('${event.title} (${event.year}): ${event.desc}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${event.title} (${event.year})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            event.desc,
                            style: const TextStyle(fontSize: 16),
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
