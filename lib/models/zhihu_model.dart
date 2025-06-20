class ZhihuApiResponse {
  final List<ZhihuItem> items;

  ZhihuApiResponse({required this.items});

  factory ZhihuApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<ZhihuItem> itemList = list.map((i) => ZhihuItem.fromJson(i)).toList();
    return ZhihuApiResponse(items: itemList);
  }
}

class ZhihuItem {
  final String title;
  final String detail;
  final String cover;
  final String hotValueDesc;
  final int answerCount;
  final int followerCount;
  final String link;

  ZhihuItem({
    required this.title,
    required this.detail,
    required this.cover,
    required this.hotValueDesc,
    required this.answerCount,
    required this.followerCount,
    required this.link,
  });

  factory ZhihuItem.fromJson(Map<String, dynamic> json) {
    return ZhihuItem(
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      cover: json['cover'] ?? '',
      hotValueDesc: json['hot_value_desc'] ?? '',
      answerCount: json['answer_cnt'] ?? 0,
      followerCount: json['follower_cnt'] ?? 0,
      link: json['link'] ?? '',
    );
  }
}