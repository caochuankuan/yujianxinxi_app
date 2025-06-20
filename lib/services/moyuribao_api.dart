import 'dart:convert';
import 'package:http/http.dart' as http;

// 获取摸鱼日报图片 URL
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

// 根据日期获取特定图片
Future<String> fetchMoyuRibaoImageUrlForDate(String date) async {
  final url = 'https://dayu.qqsuu.cn/moyuribao/file/$date.png';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    return url; // 返回根据日期构建的 URL
  } else {
    throw Exception('Failed to load image for date: $date');
  }
}