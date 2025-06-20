import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/global_box_office.dart';

class BoxOfficeService {
  static Future<GlobalBoxOfficeResponse> fetchGlobalBoxOffice() async {
    final response = await http.get(
      Uri.parse('https://piaofang.maoyan.com/i/globalBox/historyRank'),
    );

    if (response.statusCode == 200) {
      return GlobalBoxOfficeResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('加载票房数据失败: ${response.statusCode}');
    }
  }
}