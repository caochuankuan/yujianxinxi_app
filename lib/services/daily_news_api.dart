import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/daily_news_model.dart';

Future<DailyNewsApiResponse> fetchDailyNewsData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/60s'));

  if (response.statusCode == 200) {    
    return DailyNewsApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load daily news data');
  }
}