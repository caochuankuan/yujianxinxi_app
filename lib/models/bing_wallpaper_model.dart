class BingWallpaperApiResponse {
  final String date;
  final String headline;
  final String title;
  final String description;
  final String imageUrl;
  final String mainText;
  final String copyright;

  BingWallpaperApiResponse({
    required this.date,
    required this.headline,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.mainText,
    required this.copyright,
  });

  factory BingWallpaperApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return BingWallpaperApiResponse(
      date: data['update_date'] ?? '',
      headline: data['headline'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['cover'] ?? '',
      mainText: data['main_text'] ?? '',
      copyright: data['copyright'] ?? '',
    );
  }
}