import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:yifeng_site/models/daily_news_model.dart';
import 'package:yifeng_site/services/daily_news_api.dart';

// 每日新闻页面部件
class DailyNewsPage extends StatefulWidget {

  const DailyNewsPage({super.key});

  @override
  _DailyNewsPageState createState() => _DailyNewsPageState();
}

class _DailyNewsPageState extends State<DailyNewsPage> {
  late Future<DailyNewsApiResponse> _newsData;
  final GlobalKey _globalKey = GlobalKey(); // 用于 RepaintBoundary

  @override
  void initState() {
    super.initState();
    _newsData = fetchDailyNewsData();
  }

  // 刷新数据
  void _refreshData() {
    setState(() {
      _newsData = fetchDailyNewsData();
    });
  }

  // 保存整个页面为图片
  Future<void> _saveScreenAsImage() async {
    if (await Permission.storage.request().isGranted) {
      try {
        RenderRepaintBoundary boundary = _globalKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;

        // 获取图片尺寸
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);

        // 设置背景为白色
        final paint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        // 创建白色背景的画布
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            paint);
        canvas.drawImage(image, Offset.zero, Paint());

        final ui.Image fullImage =
            await recorder.endRecording().toImage(image.width, image.height);

        ByteData? byteData =
            await fullImage.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(imagePath);
        await file.writeAsBytes(pngBytes);

        // 保存到相册
        final result = await ImageGallerySaverPlus.saveFile(imagePath);
        if (result != null && result["isSuccess"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存成功!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败')),
          );
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
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
        title: const Text('60s 读懂世界'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData, // 点击刷新按钮
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _saveScreenAsImage, // 点击保存按钮
          ),
          SizedBox(width: 16),
        ],
      ),
      body: RepaintBoundary(
        key: _globalKey, // 将整个页面包裹在 RepaintBoundary 中
        child: FutureBuilder<DailyNewsApiResponse>(
          future: _newsData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: _buildLoadingIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data found'));
            } else {
              final data = snapshot.data!;
              // 检查封面和提示信息是否为空，或提示信息是否以中文开头
              if (data.cover.isEmpty ||
                  data.tip.isEmpty ||
                  !RegExp(r'^[\u4e00-\u9fa5]').hasMatch(data.tip)) {
                // 使用备用接口
                return Container(
                  decoration: BoxDecoration(),
                  child: Text(
                    '暂时无法获取新闻，请稍后重试',
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                );
              } else {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCoverImage(data.cover),
                      _buildTipSection(data.tip),
                      const Divider(thickness: 2),
                      _buildNewsSection(context, data.news),
                    ],
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  // 加载动画
  Widget _buildLoadingIndicator() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          '正在加载每日新闻...',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  // 封面图片部分
  Widget _buildCoverImage(String coverUrl) {
    return GestureDetector(
      onLongPress: () => _showDownloadDialog(coverUrl),
      child: Image.network(
        coverUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
      ),
    );
  }

  // 显示下载对话框
  void _showDownloadDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('下载图片'),
          content: const Text('您是否想下载此图片？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _downloadImage(imageUrl);
              },
              child: const Text('下载'),
            ),
          ],
        );
      },
    );
  }

  // 下载图片
  Future<void> _downloadImage(String imageUrl) async {
    if (await Permission.storage.request().isGranted) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final result = await ImageGallerySaverPlus.saveImage(
            response.bodyBytes,
            quality: 100,
          );
          if (result != null && result["isSuccess"]) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片下载成功!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片下载失败')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法下载图片')),
          );
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要存储权限才能下载图片')),
      );
    }
  }

  // 提示信息部分
  Widget _buildTipSection(String tip) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        tip,
        style: TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // 新闻部分，包含点击搜索和长按复制功能
  Widget _buildNewsSection(BuildContext context, List<String> news) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: news.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _searchOnBaidu(news[index]),
          onLongPress: () => _copyToClipboard(context, news[index]),
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                news[index],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.grey, size: 16),
            ),
          ),
        );
      },
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
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: "$text"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
