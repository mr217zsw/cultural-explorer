class UserInfo {
  final String id;
  final String? nickname;
  final String? avatar;
  final int totalScore;
  final int completedCount;
  final List<String> completedRegions;
  final int maxStreak;
  final DateTime? lastLoginAt;

  UserInfo({
    required this.id,
    this.nickname,
    this.avatar,
    this.totalScore = 0,
    this.completedCount = 0,
    this.completedRegions = const [],
    this.maxStreak = 0,
    this.lastLoginAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      completedRegions: (json['completedRegions'] as List<dynamic>?)?.cast<String>() ?? [],
      maxStreak: (json['maxStreak'] as num?)?.toInt() ?? 0,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'] as String) : null,
    );
  }
}
