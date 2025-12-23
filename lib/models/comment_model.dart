import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final String comment;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    required this.comment,
    required this.createdAt,
  });

  // ✅ FIXED: Konsisten dengan field yang disimpan di Firestore
  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      userId: map['userId'] ?? '', // ✅ Sesuai dengan yang disimpan di service
      username: map['username'] ?? 'Anonymous',
      userPhotoUrl: map['userPhotoUrl'], // ✅ Sesuai dengan yang disimpan di service
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}