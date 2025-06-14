import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GlobalBoxOfficeResponse {
  final GlobalBoxOfficeData data;
  final bool success;

  GlobalBoxOfficeResponse({
    required this.data,
    required this.success,
  });

  factory GlobalBoxOfficeResponse.fromJson(Map<String, dynamic> json) {
    return GlobalBoxOfficeResponse(
      data: GlobalBoxOfficeData.fromJson(json['data']),
      success: json['success'],
    );
  }
}

class GlobalBoxOfficeData {
  final List<MovieBoxOffice> list;
  final String tips;

  GlobalBoxOfficeData({
    required this.list,
    required this.tips,
  });

  factory GlobalBoxOfficeData.fromJson(Map<String, dynamic> json) {
    return GlobalBoxOfficeData(
      list: (json['list'] as List)
          .map((item) => MovieBoxOffice.fromJson(item))
          .toList(),
      tips: json['tips'],
    );
  }
}

class MovieBoxOffice {
  final String box;
  final bool force;
  final int movieId;
  final String movieName;
  final int rawValue;
  final String releaseTime;
  final List<IndexItem>? indexItems;

  MovieBoxOffice({
    required this.box,
    required this.force,
    required this.movieId,
    required this.movieName,
    required this.rawValue,
    required this.releaseTime,
    this.indexItems,
  });

  factory MovieBoxOffice.fromJson(Map<String, dynamic> json) {
    return MovieBoxOffice(
      box: json['box'],
      force: json['force'],
      movieId: json['movieId'],
      movieName: json['movieName'],
      rawValue: json['rawValue'],
      releaseTime: json['releaseTime'],
      indexItems: json['indexItems'] != null
          ? (json['indexItems'] as List)
              .map((item) => IndexItem.fromJson(item))
              .toList()
          : null,
    );
  }
}

class IndexItem {
  final String boxInfo;
  final String title;
  final String unitDesc;

  IndexItem({
    required this.boxInfo,
    required this.title,
    required this.unitDesc,
  });

  factory IndexItem.fromJson(Map<String, dynamic> json) {
    return IndexItem(
      boxInfo: json['boxInfo'],
      title: json['title'],
      unitDesc: json['unitDesc'],
    );
  }
}

class GlobalBoxOfficePage extends StatefulWidget {
  const GlobalBoxOfficePage({super.key});

  @override
  _GlobalBoxOfficePageState createState() => _GlobalBoxOfficePageState();
}

class _GlobalBoxOfficePageState extends State<GlobalBoxOfficePage> {
  late Future<GlobalBoxOfficeResponse> _futureBoxOffice;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _futureBoxOffice = fetchGlobalBoxOffice();
  }

  Future<GlobalBoxOfficeResponse> fetchGlobalBoxOffice() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://piaofang.maoyan.com/i/api/rank/globalBox/historyRankList?WuKongReady=h5'));

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        return GlobalBoxOfficeResponse.fromJson(json.decode(response.body));
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('加载票房数据失败: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      throw Exception('网络请求错误: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全球电影票房排行榜'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureBoxOffice = fetchGlobalBoxOffice();
          });
        },
        child: FutureBuilder<GlobalBoxOfficeResponse>(
          future: _futureBoxOffice,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      '加载失败: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _futureBoxOffice = fetchGlobalBoxOffice();
                        });
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.data.list.isEmpty) {
              return const Center(child: Text('没有可用数据'));
            }

            final boxOfficeData = snapshot.data!.data;
            return Column(
              children: [
                // _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: boxOfficeData.list.length,
                    itemBuilder: (context, index) {
                      final movie = boxOfficeData.list[index];
                      return _buildMovieCard(movie, index + 1);
                    },
                  ),
                ),
                // _buildFooter(boxOfficeData.tips),
              ],
            );
          },
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Column(
        children: [
          Text(
            '全球电影票房排行榜',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '数据来源: 猫眼电影',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(MovieBoxOffice movie, int rank) {
    // 根据排名设置不同的颜色
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[300]!;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
    } else {
      rankColor = Colors.blueGrey[100]!;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // 可以添加点击事件，跳转到电影详情页
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 排名
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: rank <= 3 ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 电影信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.movieName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '上映年份: ${movie.releaseTime}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (movie.indexItems != null && movie.indexItems!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          children: movie.indexItems!.map((item) {
                            return Chip(
                              label: Text(
                                '${item.title}: ${item.boxInfo}${item.unitDesc}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue[50],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              // 票房
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${movie.box}亿',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '人民币',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}