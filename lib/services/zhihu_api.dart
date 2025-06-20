import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/zhihu_model.dart';

Future<ZhihuApiResponse> fetchZhihuData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/zhihu'));

  if (response.statusCode == 200) {
    print(response.body);
    return ZhihuApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Zhihu data');
  }
}