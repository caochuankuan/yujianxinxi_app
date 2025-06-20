// 获取历史上的今天数据
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/today_in_history_model.dart';

Future<TodayInHistoryApiResponse> fetchTodayInHistoryData() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/today_in_history'));

  if (response.statusCode == 200) {
    return TodayInHistoryApiResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load today in history data');
  }
}