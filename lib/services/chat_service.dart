import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/show_event.dart';

class ChatService {
  static const String _userIdKey = 'bamap_local_user_id';
  static const String _userNameKey = 'bamap_local_user_name';

  // ---------------------------------------------------------------------------
  // Local session user (no-auth fallback)
  // ---------------------------------------------------------------------------
  static Future<String> getLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_userIdKey);
    if (id == null) {
      id = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_userIdKey, id);
    }
    return id;
  }

  static Future<String> getLocalUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString(_userNameKey);
    if (name == null) {
      name = 'You';
      await prefs.setString(_userNameKey, name);
    }
    return name;
  }

  static Future<void> setLocalUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // ---------------------------------------------------------------------------
  // Interested-users tracking (Firestore array-based)
  // ---------------------------------------------------------------------------
  static Future<bool> markInterested(String showId) async {
    final uid = await getLocalUserId();
    final showRef = FirebaseFirestore.instance.collection('shows').doc(showId);
    try {
      await showRef.update({
        'interested_users': FieldValue.arrayUnion([uid]),
      });
      return true;
    } on FirebaseException catch (_) {
      return false;
    }
  }

  static Future<bool> hasMarkedInterested(String showId) async {
    final uid = await getLocalUserId();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shows')
          .doc(showId)
          .get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final users =
          (data['interested_users'] as List<dynamic>?)?.cast<String>() ?? [];
      return users.contains(uid);
    } on FirebaseException catch (_) {
      return false;
    }
  }

  static Future<List<String>> getInterestedShowIds() async {
    final uid = await getLocalUserId();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shows')
          .where('interested_users', arrayContains: uid)
          .get(const GetOptions(source: Source.server));
      return snapshot.docs.map((doc) => doc.id).toList();
    } on FirebaseException catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Capped message stream (REAL-TIME, but cost-capped)
  // ---------------------------------------------------------------------------
  static Stream<List<ChatMessage>> messageStream(String showId) {
    return FirebaseFirestore.instance
        .collection('shows')
        .doc(showId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return ChatMessage.fromJson({
                'message_id': doc.id,
                ...doc.data(),
              });
            }).toList());
  }

  // ---------------------------------------------------------------------------
  // Send a message
  // ---------------------------------------------------------------------------
  static Future<void> sendMessage({
    required String showId,
    required String text,
  }) async {
    final senderId = await getLocalUserId();
    final senderName = await getLocalUserName();
    final docRef =
        FirebaseFirestore.instance.collection('shows').doc(showId).collection('messages').doc();

    await docRef.set(ChatMessage(
      messageId: docRef.id,
      showId: showId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    ).toFirestoreMap());
  }

  // ---------------------------------------------------------------------------
  // Fetch user's active shows (joined or saved) for the Chat Hub
  // ---------------------------------------------------------------------------
  static Future<List<ShowEvent>> getUserShows() async {
    final joinedIds = await getInterestedShowIds();
    if (joinedIds.isEmpty) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shows')
          .where(FieldPath.documentId, whereIn: joinedIds.take(10).toList())
          .get(const GetOptions(source: Source.server));

      return snapshot.docs.map((doc) => ShowEvent.fromJson({
            ...doc.data(),
            'show_id': doc.id,
          })).toList();
    } on FirebaseException catch (_) {
      return [];
    }
  }
}
