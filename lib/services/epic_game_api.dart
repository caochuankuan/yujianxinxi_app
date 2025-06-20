import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yifeng_site/models/epic_game.dart';

Future<List<EpicGame>> fetchEpicFreeGames() async {
  final response = await http.get(Uri.parse('https://60s-api.viki.moe/v2/epic'));

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    final List<dynamic> gamesJson = jsonResponse['data'];
    return gamesJson.map((json) => EpicGame.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load Epic free games');
  }
}