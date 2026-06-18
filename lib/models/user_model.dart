class UserModel {
  final String userId;
  final String username;
  final String bio;
  final String profileImageUrl;
  final bool isArtist;
  final bool isVerified;
  final List<String> topGenres;
  final List<String> topArtists;
  final int followingCount;
  final int followersCount;
  final List<String> displayedPatchIds;

  const UserModel({
    required this.userId,
    required this.username,
    this.bio = '',
    this.profileImageUrl = '',
    this.isArtist = false,
    this.isVerified = false,
    this.topGenres = const [],
    this.topArtists = const [],
    this.followingCount = 0,
    this.followersCount = 0,
    this.displayedPatchIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      isArtist: json['is_artist'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      topGenres: (json['top_genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      topArtists: (json['top_artists'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      followingCount: json['following_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      displayedPatchIds: (json['displayed_patch_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'is_artist': isArtist,
      'is_verified': isVerified,
      'top_genres': topGenres,
      'top_artists': topArtists,
      'following_count': followingCount,
      'followers_count': followersCount,
      'displayed_patch_ids': displayedPatchIds,
    };
  }
}
