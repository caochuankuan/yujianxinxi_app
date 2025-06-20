// 历史上的今天数据模型类
class TodayInHistoryApiResponse {
  final List<HistoryEvent> events;

  TodayInHistoryApiResponse({required this.events});

  factory TodayInHistoryApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data']['items'] as List;  // 修改这里，因为事件数据在 data.items 中
    List<HistoryEvent> eventsList = list.map((i) => HistoryEvent.fromJson(i)).toList();
    return TodayInHistoryApiResponse(events: eventsList);
  }
}

// 历史事件模型类
class HistoryEvent {
  final String title;
  final String year;
  final String desc;
  final String link;

  HistoryEvent({required this.title, required this.year, required this.desc, required this.link});

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      title: json['title'] ?? '',
      year: json['year'] ?? '',
      desc: json['description'] ?? '',  // API 返回的是 description
      link: json['link'] ?? '',
    );
  }
}