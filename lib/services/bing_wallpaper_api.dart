import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/bing_wallpaper_model.dart';

// 获取 Bing 每日壁纸数据
Future<BingWallpaperApiResponse> fetchBingWallpaperData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/bing'));

  if (response.statusCode == 200) {
    return BingWallpaperApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load Bing wallpaper data');
  }
}