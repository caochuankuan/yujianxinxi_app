// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter/services.dart';

// Epic 免费游戏页面部件
class EpicFreeGamesPage extends StatefulWidget {
  final Future<List<EpicGame>> futureGames;

  EpicFreeGamesPage({required this.futureGames});

  @override
  _EpicFreeGamesPageState createState() => _EpicFreeGamesPageState();
}

class _EpicFreeGamesPageState extends State<EpicFreeGamesPage> {
  late Future<List<EpicGame>> _futureGames;

  @override
  void initState() {
    super.initState();
    _futureGames = widget.futureGames;
  }

  // 刷新数据
  void _refreshGames() {
    setState(() {
      _futureGames = fetchEpicFreeGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Epic 免费游戏'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshGames, // 刷新按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<List<EpicGame>>(
        future: _futureGames,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No games found'));
          } else {
            final games = snapshot.data!;
            return ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _launchURL(game.link),
                    onLongPress: () {
                      _copyToClipboard(game.title);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Image.network(
                            game.thumbnailUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  game.description,
                                  style: const TextStyle(fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    Text(
                                      game.isCurrentlyFree ? '当前免费' : '即将免费',
                                      style: TextStyle(
                                        color: game.isCurrentlyFree ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      '原价: ${game.originalPrice}',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${game.freeStartTime} - ${game.freeEndTime}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
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

  // 跳转到游戏链接
  void _launchURL(String urlSlug) async {
    final url = 'https://www.epicgames.com/store/en-US/p/$urlSlug';
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

// 获取 Epic 免费游戏数据
Future<List<EpicGame>> fetchEpicFreeGames() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/epic'));

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    final List<dynamic> gamesJson = jsonResponse['data'];
    return gamesJson.map((json) => EpicGame.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load Epic free games');
  }
}

// Epic 免费游戏数据模型类
class EpicGame {
  final String title;
  final String description;
  final String thumbnailUrl;
  final String link;
  final bool isCurrentlyFree;
  final String originalPrice;
  final String freeStartTime;
  final String freeEndTime;

  EpicGame({
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.link,
    required this.isCurrentlyFree,
    required this.originalPrice,
    required this.freeStartTime,
    required this.freeEndTime,
  });

  factory EpicGame.fromJson(Map<String, dynamic> json) {
    return EpicGame(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['cover'] ?? '',
      link: json['link'] ?? '',
      isCurrentlyFree: json['is_free_now'] ?? false,
      originalPrice: json['original_price_desc'] ?? '',
      freeStartTime: json['free_start'] ?? '',
      freeEndTime: json['free_end'] ?? '',
    );
  }
}
