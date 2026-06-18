import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoModel {
  final String photoId;
  final String showId;
  final String uploaderUserId;
  final String imageUrl;
  final DateTime uploadTimestamp;
  final int upvoteCount;
  final int downvoteCount;
  final bool isGreyedOut;

  const PhotoModel({
    required this.photoId,
    required this.showId,
    required this.uploaderUserId,
    required this.imageUrl,
    required this.uploadTimestamp,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.isGreyedOut = false,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      photoId: json['photo_id'] as String? ?? '',
      showId: json['show_id'] as String,
      uploaderUserId: json['uploader_user_id'] as String,
      imageUrl: json['image_url'] as String,
      uploadTimestamp: (json['upload_timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      upvoteCount: json['upvote_count'] as int? ?? 0,
      downvoteCount: json['downvote_count'] as int? ?? 0,
      isGreyedOut: json['is_greyed_out'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_id': photoId,
      'show_id': showId,
      'uploader_user_id': uploaderUserId,
      'image_url': imageUrl,
      'upload_timestamp': Timestamp.fromDate(uploadTimestamp),
      'upvote_count': upvoteCount,
      'downvote_count': downvoteCount,
      'is_greyed_out': isGreyedOut,
    };
  }
}
