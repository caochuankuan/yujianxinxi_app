// 微博 API 数据模型类
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/weibo_model.dart';

Future<WeiboApiResponse> fetchWeiboData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/weibo'));

  if (response.statusCode == 200) {
    return WeiboApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Weibo data');
  }
}