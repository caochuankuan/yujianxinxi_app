class NewsItem {
  final String title;
  final int hotValue;
  final String cover;
  final String link;

  NewsItem({
    required this.title,
    required this.hotValue,
    required this.cover,
    required this.link,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] ?? '',
      hotValue: json['hot_value'] ?? 0,
      cover: json['cover'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

class NewsParams {
  final int fakeClickCount;

  NewsParams({required this.fakeClickCount});

  factory NewsParams.fromJson(Map<String, dynamic> json) {
    return NewsParams(
      fakeClickCount: json['fake_click_cnt'] ?? 0, // Default to 0 if null
    );
  }
}

class NewsApiResponse {
  final List<NewsItem> items;

  NewsApiResponse({required this.items});

  factory NewsApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<NewsItem> itemList = list.map((i) => NewsItem.fromJson(i)).toList();
    return NewsApiResponse(items: itemList);
  }
}