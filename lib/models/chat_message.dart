import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String messageId;
  final String showId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.messageId,
    required this.showId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'] as String? ?? '',
      showId: json['show_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'show_id': showId,
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'message_id': messageId,
      'show_id': showId,
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is DateTime) return ts;
    if (ts is Timestamp) return ts.toDate();
    if (ts is String) return DateTime.parse(ts);
    return DateTime.now();
  }
}
