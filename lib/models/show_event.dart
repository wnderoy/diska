import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class ShowEvent {
  final String showId;
  final String creatorUserId;
  final String title;
  final String description;
  final String primaryGenre;
  final double latitude;
  final double longitude;
  final String addressText;
  final DateTime startTime;
  final DateTime endTime;
  final bool isOfficial;
  final String externalTicketLink;
  final String primaryImageUrl;
  final int rsvpCount;

  const ShowEvent({
    required this.showId,
    this.creatorUserId = '',
    required this.title,
    this.description = '',
    required this.primaryGenre,
    required this.latitude,
    required this.longitude,
    this.addressText = '',
    required this.startTime,
    required this.endTime,
    this.isOfficial = false,
    this.externalTicketLink = '',
    this.primaryImageUrl = '',
    this.rsvpCount = 0,
  });

  LatLng get position => LatLng(latitude, longitude);

  String get artist {
    // For now, title doubles as the artist name in mock data
    // In production, linked via creatorUserId to a User document
    return title;
  }

  String get genre => primaryGenre;

  String get imageUrl => primaryImageUrl;

  factory ShowEvent.fromJson(Map<String, dynamic> json) {
    return ShowEvent(
      showId: json['show_id'] as String? ?? '',
      creatorUserId: json['creator_user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      primaryGenre: json['primary_genre'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      addressText: json['address_text'] as String? ?? '',
      startTime: _parseTimestamp(json['start_time']),
      endTime: _parseTimestamp(json['end_time']),
      isOfficial: json['is_official'] as bool? ?? false,
      externalTicketLink: json['external_ticket_link'] as String? ?? '',
      primaryImageUrl: json['primary_image_url'] as String? ?? '',
      rsvpCount: json['rsvp_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_id': showId,
      'creator_user_id': creatorUserId,
      'title': title,
      'description': description,
      'primary_genre': primaryGenre,
      'latitude': latitude,
      'longitude': longitude,
      'address_text': addressText,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_official': isOfficial,
      'external_ticket_link': externalTicketLink,
      'primary_image_url': primaryImageUrl,
      'rsvp_count': rsvpCount,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'show_id': showId,
      'creator_user_id': creatorUserId,
      'title': title,
      'description': description,
      'primary_genre': primaryGenre,
      'latitude': latitude,
      'longitude': longitude,
      'address_text': addressText,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'is_official': isOfficial,
      'external_ticket_link': externalTicketLink,
      'primary_image_url': primaryImageUrl,
      'rsvp_count': rsvpCount,
    };
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is DateTime) return ts;
    if (ts is Timestamp) return ts.toDate();
    if (ts is String) return DateTime.parse(ts);
    return DateTime.now();
  }

  static List<ShowEvent> get mockShows => [
        ShowEvent(
          showId: 'mock_1',
          title: 'Underground Jazz Night',
          description: 'An intimate evening of experimental jazz.',
          primaryGenre: 'Jazz',
          latitude: 32.0853,
          longitude: 34.7818,
          addressText: '12 Levontin St, Tel Aviv',
          startTime: DateTime.now().add(const Duration(days: 2, hours: 20)),
          endTime: DateTime.now().add(const Duration(days: 2, hours: 23)),
          rsvpCount: 47,
          isOfficial: true,
        ),
        ShowEvent(
          showId: 'mock_2',
          title: 'Rooftop Electronic',
          description: 'Electronic music under the stars.',
          primaryGenre: 'Electronic',
          latitude: 32.0775,
          longitude: 34.7689,
          addressText: '3 Rothschild Blvd, Tel Aviv',
          startTime: DateTime.now().add(const Duration(days: 3, hours: 22)),
          endTime: DateTime.now().add(const Duration(days: 4, hours: 2)),
          rsvpCount: 132,
          isOfficial: true,
        ),
        ShowEvent(
          showId: 'mock_3',
          title: 'Folk Acoustic Session',
          description: 'Acoustic folk originals and covers.',
          primaryGenre: 'Folk',
          latitude: 32.0692,
          longitude: 34.7885,
          addressText: '21 King George St, Tel Aviv',
          startTime: DateTime.now().add(const Duration(days: 1, hours: 19)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 22)),
          rsvpCount: 28,
        ),
        ShowEvent(
          showId: 'mock_4',
          title: 'Indie Rock Showcase',
          description: 'High-energy indie rock from local up-and-comers.',
          primaryGenre: 'Indie Rock',
          latitude: 32.0538,
          longitude: 34.7712,
          addressText: '49 Florentin St, Tel Aviv',
          startTime: DateTime.now().add(const Duration(days: 5, hours: 21)),
          endTime: DateTime.now().add(const Duration(days: 5, hours: 23, minutes: 30)),
          rsvpCount: 89,
          isOfficial: true,
        ),
        ShowEvent(
          showId: 'mock_5',
          title: 'Hip Hop Cypher',
          description: 'Open mic hip hop cypher. Bring your bars.',
          primaryGenre: 'Hip Hop',
          latitude: 32.0923,
          longitude: 34.7802,
          addressText: '7 HaArbaa St, Tel Aviv',
          startTime: DateTime.now().add(const Duration(days: 4, hours: 20)),
          endTime: DateTime.now().add(const Duration(days: 4, hours: 23)),
          rsvpCount: 64,
        ),
        ShowEvent(
          showId: 'mock_6',
          title: 'Punk Basement Gig',
          description: 'Loud, fast, and raw. Earplugs recommended.',
          primaryGenre: 'Punk',
          latitude: 32.0652,
          longitude: 34.7618,
          addressText: '8 HaMasger St, Tel Aviv',
          startTime: DateTime.now().add(const Duration(days: 6, hours: 21)),
          endTime: DateTime.now().add(const Duration(days: 6, hours: 23, minutes: 45)),
          rsvpCount: 35,
        ),
        ShowEvent(
          showId: 'mock_7',
          title: 'Jaffa Sunset Reggae',
          description: 'Reggae vibes at the Jaffa port sunset.',
          primaryGenre: 'Reggae',
          latitude: 32.0520,
          longitude: 34.7512,
          addressText: 'Jaffa Port, Tel Aviv',
          startTime: DateTime.now().add(const Duration(days: 7, hours: 17)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 21)),
          rsvpCount: 156,
          isOfficial: true,
        ),
        ShowEvent(
          showId: 'mock_8',
          title: 'Late Night Blues',
          description: 'Chicago blues meets Mediterranean soul.',
          primaryGenre: 'Blues',
          latitude: 32.0878,
          longitude: 34.7875,
          addressText: '41 Lilienblum St, Tel Aviv',
          startTime: DateTime.now().add(const Duration(days: 8, hours: 23)),
          endTime: DateTime.now().add(const Duration(days: 9, hours: 1)),
          rsvpCount: 53,
        ),
        ShowEvent(
          showId: 'mock_9',
          title: 'Haifa Alternative',
          description: 'Post-rock and ambient from the north.',
          primaryGenre: 'Alternative',
          latitude: 32.8203,
          longitude: 34.9988,
          addressText: '12 Sderot HaNassi, Haifa',
          startTime: DateTime.now().add(const Duration(days: 3, hours: 20)),
          endTime: DateTime.now().add(const Duration(days: 3, hours: 22, minutes: 30)),
          rsvpCount: 41,
        ),
        ShowEvent(
          showId: 'mock_10',
          title: 'Desert Techno',
          description: 'All-night techno party in the Negev.',
          primaryGenre: 'Techno',
          latitude: 31.1834,
          longitude: 34.8502,
          addressText: 'Beersheba, Industrial Zone',
          startTime: DateTime.now().add(const Duration(days: 10, hours: 23)),
          endTime: DateTime.now().add(const Duration(days: 11, hours: 6)),
          rsvpCount: 213,
          isOfficial: true,
        ),
      ];
}
