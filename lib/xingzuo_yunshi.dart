import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// 星座运势页面部件
class XingzuoYunshiPage extends StatefulWidget {
  const XingzuoYunshiPage({super.key});

  @override
  _XingzuoYunshiPageState createState() => _XingzuoYunshiPageState();
}

class _XingzuoYunshiPageState extends State<XingzuoYunshiPage> {
  late Future<String> _futureImageUrl;
  bool isDownloading = false;
  DateTime selectedDate = DateTime.now();  // 添加日期状态

  // 添加日期选择方法
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        final formattedDate = "${picked.year}${picked.month.toString().padLeft(2, '0')}${picked.day.toString().padLeft(2, '0')}";
        _futureImageUrl = Future.value('https://dayu.qqsuu.cn/xingzuoyunshi/file/$formattedDate.png');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _futureImageUrl = fetchXingzuoYunshiImageUrl();
  }

  // 刷新图片
  void _refreshImage() {
    setState(() {
      _futureImageUrl = fetchXingzuoYunshiImageUrl();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('星座运势'),
        actions: [
          // 日期选择按钮
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          // 刷新按钮
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshImage,
          ),
          // 下载按钮
          IconButton(
            icon: isDownloading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 229, 166, 209),
                      semanticsLabel: '下载中',
                      semanticsValue: 'Downloading...',
                    ),
                  )
                : Icon(Icons.download),
            onPressed: isDownloading
                ? null
                : () async {
                    setState(() {
                      isDownloading = true;
                    });

                    final imageUrl = await _futureImageUrl;

                    if (await Permission.storage.request().isGranted) {
                      final success = await _saveImage(imageUrl);
                      if (success) {
                        Fluttertoast.showToast(msg: '图片保存成功！');
                      } else {
                        Fluttertoast.showToast(msg: '图片保存失败。');
                      }
                    } else {
                      Fluttertoast.showToast(msg: '存储权限被拒绝。');
                    }

                    setState(() {
                      isDownloading = false;
                    });
                  },
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<String>(
        future: _futureImageUrl,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No image found'));
          } else {
            final imageUrl = snapshot.data!;
            return Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    } else {
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    }
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('图片加载失败，请尝试选择其他日期'),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _selectDate(context),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('选择日期'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // 下载图片并保存到图库
  Future<bool> _saveImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = await ImageGallerySaverPlus.saveImage(
          response.bodyBytes,
          quality: 100,
        );
        return result != null && result['isSuccess'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }
}

// 获取星座运势图片 URL
Future<String> fetchXingzuoYunshiImageUrl() async {
  final response = await http
      .get(Uri.parse('https://dayu.qqsuu.cn/xingzuoyunshi/apis.php?type=json'));

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse['code'] == 200) {
      return jsonResponse['data'];
    } else {
      throw Exception('Failed to load image URL');
    }
  } else {
    throw Exception('Failed to load image URL');
  }
}
