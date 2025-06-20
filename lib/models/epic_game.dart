class EpicGame {
  final String title;
  final String description;
  final String thumbnailUrl;
  final String link;
  final bool isCurrentlyFree;
  final String originalPrice;
  final String freeStartTime;
  final String freeEndTime;

  EpicGame({
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.link,
    required this.isCurrentlyFree,
    required this.originalPrice,
    required this.freeStartTime,
    required this.freeEndTime,
  });

  factory EpicGame.fromJson(Map<String, dynamic> json) {
    return EpicGame(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['cover'] ?? '',
      link: json['link'] ?? '',
      isCurrentlyFree: json['is_free_now'] ?? false,
      originalPrice: json['original_price_desc'] ?? '',
      freeStartTime: json['free_start'] ?? '',
      freeEndTime: json['free_end'] ?? '',
    );
  }
}