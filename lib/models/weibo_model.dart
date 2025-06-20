class WeiboApiResponse {
  final List<WeiboItem> items;

  WeiboApiResponse({required this.items});

  factory WeiboApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<WeiboItem> itemList = list.map((i) => WeiboItem.fromJson(i)).toList();
    return WeiboApiResponse(items: itemList);
  }
}

class WeiboItem {
  final String title;
  final int hotValue;
  final String link;

  WeiboItem({
    required this.title,
    required this.hotValue,
    required this.link,
  });

  factory WeiboItem.fromJson(Map<String, dynamic> json) {
    return WeiboItem(
      title: json['title'] ?? '',
      hotValue: json['hot_value'] ?? 0,
      link: json['link'] ?? '',
    );
  }
}