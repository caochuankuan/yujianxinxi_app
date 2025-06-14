import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

// 摸鱼日报页面部件
class MoyuRibaoPage extends StatefulWidget {
  const MoyuRibaoPage({super.key});

  @override
  _MoyuRibaoPageState createState() => _MoyuRibaoPageState();
}

class _MoyuRibaoPageState extends State<MoyuRibaoPage> {
  late Future<String> _futureImageUrl;
  bool isDownloading = false;
  DateTime selectedDate = DateTime.now(); // 记录用户选择的日期
  String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now()); // 当前日期格式

  @override
  void initState() {
    super.initState();
    _futureImageUrl = fetchMoyuRibaoImageUrl(); // 默认使用原始接口请求图片
  }

  // 刷新图片
  void _refreshImage() {
    setState(() {
      _futureImageUrl = fetchMoyuRibaoImageUrl();
    });
  }

  // 选择日期
  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        formattedDate = DateFormat('yyyyMMdd').format(selectedDate);
        _futureImageUrl = fetchMoyuRibaoImageUrlForDate(formattedDate); // 根据选择的日期请求图片
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('摸鱼日报'),
        actions: [
          // 日期选择按钮
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDate,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('图片加载失败'),
                  SizedBox(height: 8),
                  Text('可能遇到了问题，可以切换别的日期看看。'),
                  // 显示日期选择按钮
                  ElevatedButton(
                    onPressed: _selectDate,
                    child: Text('选择日期'),
                  ),
                ],
              ),
            );
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
                  fit: BoxFit.contain,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    } else {
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
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
                          Text('图片加载失败'),
                          SizedBox(height: 8),
                          Text('可能遇到了问题，可以切换别的日期看看。'),
                          ElevatedButton(
                            onPressed: _selectDate,
                            child: Text('选择日期'),
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

// 保持原有逻辑：获取摸鱼日报图片 URL
Future<String> fetchMoyuRibaoImageUrl() async {
  final response = await http.get(Uri.parse('https://dayu.qqsuu.cn/moyuribao/apis.php?type=json'));

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse['code'] == 200) {
      return jsonResponse['data']; // 从 JSON 响应中返回图片 URL
    } else {
      throw Exception('Failed to load image URL');
    }
  } else {
    throw Exception('Failed to load image URL');
  }
}

// 新增：根据日期获取特定图片
Future<String> fetchMoyuRibaoImageUrlForDate(String date) async {
  final url = 'https://dayu.qqsuu.cn/moyuribao/file/$date.png';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    return url; // 返回根据日期构建的 URL
  } else {
    throw Exception('Failed to load image for date: $date');
  }
}
