// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter/services.dart';

class TodayInHistoryPage extends StatefulWidget {
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

// 获取历史上的今天数据
Future<TodayInHistoryApiResponse> fetchTodayInHistoryData() async {
  final response = await http.get(Uri.parse('https://60s.viki.moe/today_in_history'));

  if (response.statusCode == 200) {
    return TodayInHistoryApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load today in history data');
  }
}

// 历史上的今天数据模型类
class TodayInHistoryApiResponse {
  final List<HistoryEvent> events;

  TodayInHistoryApiResponse({required this.events});

  factory TodayInHistoryApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<HistoryEvent> eventsList = list.map((i) => HistoryEvent.fromJson(i)).toList();
    return TodayInHistoryApiResponse(events: eventsList);
  }
}

// 历史事件模型类
class HistoryEvent {
  final String title;
  final String year;
  final String desc;
  final String link;

  HistoryEvent({required this.title, required this.year, required this.desc, required this.link});

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      title: json['title'] ?? '', // Default to empty string if null
      year: json['year'] ?? '',   // Default to empty string if null
      desc: json['desc'] ?? '',   // Default to empty string if null
      link: json['link'] ?? '',   // Default to empty string if null
    );
  }
}
