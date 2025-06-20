import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/toutiao_news_model.dart';

Future<NewsApiResponse> fetchNewsData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/toutiao'));

  if (response.statusCode == 200) {
    return NewsApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load news data');
  }
}