import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/show_event.dart';

class ShowService {
  static const String _cacheKey = 'bamap_shows_cache';
  static const String _cacheTimestampKey = 'bamap_shows_cache_ts';

  /// Fetch active shows from Firestore (one-time pull, no real-time listener).
  /// Falls back to cached data if the network is unavailable.
  /// Falls back to mock data if no cache exists.
  static Future<List<ShowEvent>> fetchShows() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shows')
          .where('end_time', isGreaterThan: DateTime.now())
          .get(const GetOptions(source: Source.server));

      final shows = snapshot.docs
          .map((doc) => ShowEvent.fromJson({
                ...doc.data(),
                'show_id': doc.id,
              }))
          .toList();

      // Cache locally
      await _cacheShows(shows);
      return shows;
    } on FirebaseException catch (_) {
      // Network error — try cache
      final cached = await _loadCachedShows();
      if (cached.isNotEmpty) return cached;
      // No cache — fall back to mock data
      return ShowEvent.mockShows;
    }
  }

  /// Fetch a single show by ID
  static Future<ShowEvent?> fetchShow(String showId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shows')
          .doc(showId)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) return null;
      return ShowEvent.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'show_id': doc.id,
      });
    } on FirebaseException catch (_) {
      return null;
    }
  }

  /// Create a new show document in Firestore.
  /// Returns the generated show ID.
  static Future<String?> createShow(ShowEvent show) async {
    try {
      // Create the doc ref first to get the ID
      final docRef = FirebaseFirestore.instance.collection('shows').doc();
      // Write using toFirestoreMap() which uses Timestamp objects
      await docRef.set(show.toFirestoreMap()..['show_id'] = docRef.id);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to create show: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Local caching
  // ---------------------------------------------------------------------------

  static Future<void> _cacheShows(List<ShowEvent> shows) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = shows.map((s) => s.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonList));
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<ShowEvent>> _loadCachedShows() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cacheKey);
    if (jsonStr == null) return [];

    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => ShowEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
