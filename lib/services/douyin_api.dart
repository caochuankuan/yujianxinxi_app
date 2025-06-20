import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/douyin_item.dart';

// 抖音 API 数据模型类
Future<DouyinApiResponse> fetchDouyinData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/douyin'));

  if (response.statusCode == 200) {
    return DouyinApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Douyin data');
  }
}