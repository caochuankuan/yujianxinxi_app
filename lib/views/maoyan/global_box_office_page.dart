import 'package:flutter/material.dart';
import 'package:yifeng_site/models/global_box_office.dart';
import 'package:yifeng_site/services/box_office_service.dart';
import 'package:yifeng_site/views/maoyan/movie_card.dart';

class GlobalBoxOfficePage extends StatefulWidget {
  const GlobalBoxOfficePage({super.key});

  @override
  State<GlobalBoxOfficePage> createState() => _GlobalBoxOfficePageState();
}

class _GlobalBoxOfficePageState extends State<GlobalBoxOfficePage> {
  late Future<GlobalBoxOfficeResponse> _futureBoxOffice;

  @override
  void initState() {
    super.initState();
    _futureBoxOffice = BoxOfficeService.fetchGlobalBoxOffice();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureBoxOffice = BoxOfficeService.fetchGlobalBoxOffice();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('全球电影票房排行榜')),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    Text('加载失败: ${snapshot.error}'),
                    ElevatedButton(onPressed: _refresh, child: const Text('重试')),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.data.list.isEmpty) {
              return const Center(child: Text('没有可用数据'));
            }

            final movies = snapshot.data!.data.list;
            return ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return MovieCard(movie: movies[index], rank: index + 1);
              },
            );
          },
        ),
      ),
    );
  }
}