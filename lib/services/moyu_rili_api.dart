import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> fetchMoyuRiliImageUrl() async {
  final response = await http.get(Uri.parse('https://dayu.qqsuu.cn/moyurili/apis.php?type=json'));

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