class NotificationPreferenceModel {
  final String userId;
  final List<String> listenToZones;
  final bool alertOnMutualRsvp;
  final bool alertOnFollowedArtistPost;

  const NotificationPreferenceModel({
    required this.userId,
    this.listenToZones = const [],
    this.alertOnMutualRsvp = false,
    this.alertOnFollowedArtistPost = false,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      userId: json['user_id'] as String,
      listenToZones: (json['listen_to_zones'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      alertOnMutualRsvp: json['alert_on_mutual_rsvp'] as bool? ?? false,
      alertOnFollowedArtistPost:
          json['alert_on_followed_artist_post'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'listen_to_zones': listenToZones,
      'alert_on_mutual_rsvp': alertOnMutualRsvp,
      'alert_on_followed_artist_post': alertOnFollowedArtistPost,
    };
  }
}
