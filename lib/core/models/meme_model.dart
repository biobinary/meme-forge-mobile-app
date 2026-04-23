import 'package:cloud_firestore/cloud_firestore.dart';

class MemeModel {
  final String? id;
  final String userId;
  final String imageUrl;
  final String caption;
  final DateTime? createdAt;
  final List<String> likes;

  MemeModel({
    this.id,
    required this.userId,
    required this.imageUrl,
    required this.caption,
    this.createdAt,
    this.likes = const [],
  });

  factory MemeModel.fromMap(Map<String, dynamic> map, String id) {
    return MemeModel(
      id: id,
      userId: map['user_id'] ?? '',
      imageUrl: map['image_url'] ?? '',
      caption: map['caption'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      likes: List<String>.from(map['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'image_url': imageUrl,
      'caption': caption,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'likes': likes,
    };
  }
}
