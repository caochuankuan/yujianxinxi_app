import 'package:flutter/material.dart';
import 'package:yifeng_site/models/epic_game.dart';
import 'package:yifeng_site/services/epic_game_api.dart';
import 'package:yifeng_site/utils/copy2clipboard.dart';
import 'package:yifeng_site/utils/launch_url.dart';

// Epic 免费游戏页面部件
class EpicFreeGamesPage extends StatefulWidget {

  const EpicFreeGamesPage({super.key});

  @override
  _EpicFreeGamesPageState createState() => _EpicFreeGamesPageState();
}

class _EpicFreeGamesPageState extends State<EpicFreeGamesPage> {
  late Future<List<EpicGame>> _futureGames;

  @override
  void initState() {
    super.initState();
    _futureGames = fetchEpicFreeGames();
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
                    onTap: () => launchURL(game.link),
                    onLongPress: () {
                      copyToClipboard(game.title, context);
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
}
