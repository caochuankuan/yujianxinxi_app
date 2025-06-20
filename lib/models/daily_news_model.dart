class DailyNewsApiResponse {
  final List<String> news;
  final String tip;
  final String url;
  final String cover;

  DailyNewsApiResponse(
      {required this.news,
      required this.tip,
      required this.url,
      required this.cover});

  factory DailyNewsApiResponse.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'];
      if (data == null) throw Exception('No data field in response');
      
      return DailyNewsApiResponse(
        news: List<String>.from(data['news'] ?? []),
        tip: data['tip'] ?? '',
        url: data['url'] ?? '',
        cover: data['cover'] ?? '',
      );
    } catch (e) {
      print('Error parsing DailyNewsApiResponse: $e');
      // 返回一个带有默认值的对象
      return DailyNewsApiResponse(
        news: ['暂时无法获取新闻，请稍后重试'],
        tip: '数据加载失败',
        url: '',
        cover: '',
      );
    }
  }
}