import 'dart:convert';
import 'package:http/http.dart' as http;

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