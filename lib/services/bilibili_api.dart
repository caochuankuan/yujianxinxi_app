import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/bilibili_item.dart';

Future<BilibiliApiResponse> fetchBilibiliData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/bili'));

  if (response.statusCode == 200) {
    return BilibiliApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Bilibili data');
  }
}