class DouyinItem {
  final String title;
  final int hotValue;
  final String coverUrl;
  final String link;

  DouyinItem({
    required this.title,
    required this.hotValue,
    required this.coverUrl,
    required this.link,
  });

  factory DouyinItem.fromJson(Map<String, dynamic> json) {
    return DouyinItem(
      title: json['title'] ?? '',
      hotValue: json['hot_value'] ?? 0,
      coverUrl: json['cover'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

class DouyinApiResponse {
  final List<DouyinItem> items;

  DouyinApiResponse({required this.items});

  factory DouyinApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<DouyinItem> itemList = list.map((i) => DouyinItem.fromJson(i)).toList();
    return DouyinApiResponse(items: itemList);
  }
}