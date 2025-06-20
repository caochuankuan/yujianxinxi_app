class GlobalBoxOfficeResponse {
  final GlobalBoxOfficeData data;
  final bool success;

  GlobalBoxOfficeResponse({required this.data, required this.success});

  factory GlobalBoxOfficeResponse.fromJson(Map<String, dynamic> json) {
    return GlobalBoxOfficeResponse(
      data: GlobalBoxOfficeData.fromJson(json['data']),
      success: json['success'],
    );
  }
}

class GlobalBoxOfficeData {
  final List<MovieBoxOffice> list;
  final String tips;

  GlobalBoxOfficeData({required this.list, required this.tips});

  factory GlobalBoxOfficeData.fromJson(Map<String, dynamic> json) {
    return GlobalBoxOfficeData(
      list: (json['list'] as List)
          .map((item) => MovieBoxOffice.fromJson(item))
          .toList(),
      tips: json['tips'],
    );
  }
}

class MovieBoxOffice {
  final String box;
  final bool force;
  final int movieId;
  final String movieName;
  final int rawValue;
  final String releaseTime;
  final List<IndexItem>? indexItems;

  MovieBoxOffice({
    required this.box,
    required this.force,
    required this.movieId,
    required this.movieName,
    required this.rawValue,
    required this.releaseTime,
    this.indexItems,
  });

  factory MovieBoxOffice.fromJson(Map<String, dynamic> json) {
    return MovieBoxOffice(
      box: json['box'],
      force: json['force'],
      movieId: json['movieId'],
      movieName: json['movieName'],
      rawValue: json['rawValue'],
      releaseTime: json['releaseTime'],
      indexItems: json['indexItems'] != null
          ? (json['indexItems'] as List)
              .map((item) => IndexItem.fromJson(item))
              .toList()
          : null,
    );
  }
}

class IndexItem {
  final String boxInfo;
  final String title;
  final String unitDesc;

  IndexItem({
    required this.boxInfo,
    required this.title,
    required this.unitDesc,
  });

  factory IndexItem.fromJson(Map<String, dynamic> json) {
    return IndexItem(
      boxInfo: json['boxInfo'],
      title: json['title'],
      unitDesc: json['unitDesc'],
    );
  }
}