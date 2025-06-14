import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Bing 每日壁纸页面部件
class BingWallpaperPage extends StatefulWidget {
  final Future<BingWallpaperApiResponse> futureData;

  const BingWallpaperPage({super.key, required this.futureData});

  @override
  _BingWallpaperPageState createState() => _BingWallpaperPageState();
}

class _BingWallpaperPageState extends State<BingWallpaperPage> {
  late Future<BingWallpaperApiResponse> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = widget.futureData;
  }

  // 刷新数据
  void _refreshData() {
    setState(() {
      _futureData = fetchBingWallpaperData();
    });
  }

  // 保存图片到相册
  Future<void> _saveImage(String imageUrl) async {
    if (await Permission.storage.request().isGranted) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;
          final directory = await getTemporaryDirectory();
          final imagePath = '${directory.path}/bing_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File(imagePath);
          await file.writeAsBytes(bytes);

          final result = await ImageGallerySaverPlus.saveFile(imagePath);
          if (result != null && result["isSuccess"]) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片保存成功!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片保存失败')),
            );
          }
        } else {
          throw Exception('Failed to load image');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片保存失败: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要存储权限才能保存图片')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Bing 每日壁纸'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData, // 刷新按钮
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () async {
              final data = await _futureData;
              await _saveImage(data.imageUrl); // 保存图片按钮
            },
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<BingWallpaperApiResponse>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片展示部分
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24), // 圆角
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(data.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    height: 250,
                  ),
                  // 内容展示部分
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Headline', data.headline),
                        _buildSection(data.title),
                        _buildSection(data.description),
                        _buildSection(data.mainText, fontStyle: FontStyle.italic),
                        _buildSection('版权信息: ${data.copyright}', color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SelectableText(
        content,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[800],
        ),
      ),
    );
  }

  Widget _buildSection(String content, {FontStyle? fontStyle, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SelectableText(
        content,
        style: TextStyle(
          fontSize: 16,
          fontStyle: fontStyle,
          color: color ?? Colors.black,
        ),
      ),
    );
  }
}

// 获取 Bing 每日壁纸数据
Future<BingWallpaperApiResponse> fetchBingWallpaperData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/bing'));

  if (response.statusCode == 200) {
    return BingWallpaperApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Bing wallpaper data');
  }
}

// Bing 每日壁纸数据模型类
class BingWallpaperApiResponse {
  final String date;
  final String headline;
  final String title;
  final String description;
  final String imageUrl;
  final String mainText;
  final String copyright;

  BingWallpaperApiResponse({
    required this.date,
    required this.headline,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.mainText,
    required this.copyright,
  });

  factory BingWallpaperApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return BingWallpaperApiResponse(
      date: data['update_date'] ?? '',
      headline: data['headline'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['cover'] ?? '', // 注意这里改成了 cover
      mainText: data['main_text'] ?? '',
      copyright: data['copyright'] ?? '',
    );
  }
}
