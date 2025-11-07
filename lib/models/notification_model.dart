import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String imageUrl;
  final String userId;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
    required this.isRead,
  });

  /// 🔹 Factory untuk parsing data dari Firestore
  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  /// 🔹 Konversi model ke format Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  /// 🔹 Membuat salinan dengan nilai tertentu diubah
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? imageUrl,
    String? userId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
