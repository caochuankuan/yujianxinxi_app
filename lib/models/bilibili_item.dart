class BilibiliItem {
  final String title;
  final String link;
  final int position;  // 用于显示序号

  BilibiliItem({
    required this.title,
    required this.link,
    required this.position,
  });

  factory BilibiliItem.fromJson(Map<String, dynamic> json) {
    int counter = 0;  // 用于生成位置序号
    return BilibiliItem(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      position: ++counter,  // 自动生成序号
    );
  }
}

class BilibiliApiResponse {
  final List<BilibiliItem> items;

  BilibiliApiResponse({required this.items});

  factory BilibiliApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<BilibiliItem> itemList = list.map((i) => BilibiliItem.fromJson(i)).toList();
    return BilibiliApiResponse(items: itemList);
  }
}