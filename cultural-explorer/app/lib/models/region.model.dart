class Region {
  final String id;
  final String name;
  final String? nameEn;
  final String? shortName;
  final String? capital;
  final String? area;
  final String? population;
  final String description;
  final String geography;
  final String history;
  final String culture;
  final String? coverImage;
  final List<String> images;
  final String? bgmUrl;
  final String? audioUrl;
  final int viewCount;
  final int favoriteCount;
  final List<Landmark> landmarks;
  final String? mnemonic;
  final int questionCount;
  final Map<String, dynamic>? userProgress;
  final bool isFavorited;

  Region({
    required this.id,
    required this.name,
    this.nameEn,
    this.shortName,
    this.capital,
    this.area,
    this.population,
    required this.description,
    required this.geography,
    required this.history,
    required this.culture,
    this.coverImage,
    this.images = const [],
    this.bgmUrl,
    this.audioUrl,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.landmarks = const [],
    this.mnemonic,
    this.questionCount = 0,
    this.userProgress,
    this.isFavorited = false,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String?,
      shortName: json['shortName'] as String?,
      capital: json['capital'] as String?,
      area: json['area'] as String?,
      population: json['population'] as String?,
      description: (json['description'] as String?) ?? '',
      geography: (json['geography'] as String?) ?? '',
      history: (json['history'] as String?) ?? '',
      culture: (json['culture'] as String?) ?? '',
      coverImage: json['coverImage'] as String?,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      bgmUrl: json['bgmUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      landmarks: (json['landmarks'] as List<dynamic>?)?.map((e) => Landmark.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      mnemonic: json['mnemonic'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      userProgress: json['userProgress'] as Map<String, dynamic>?,
      isFavorited: (json['isFavorited'] as bool?) ?? false,
    );
  }
}

class Landmark {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  Landmark({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
