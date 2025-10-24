import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String name;
  final String brand;
  final List<String> categories;
  final String imageUrl;
  final bool isRead;
  final String userId; // Kosong untuk global notification
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.name,
    required this.brand,
    required this.categories,
    required this.imageUrl,
    required this.isRead,
    required this.userId,
    required this.createdAt,
  });

  /// Factory constructor untuk parse dari Firestore
  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle imageUrl atau imageUrl1 (fallback)
    String image = data['imageUrl'] ?? data['imageUrl1'] ?? '';
    
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      categories: data['categories'] != null 
          ? List<String>.from(data['categories']) 
          : [],
      imageUrl: image,
      isRead: data['isRead'] ?? false,
      userId: data['userId'] ?? '', // Kosong = global notification
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ke Map untuk save ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'name': name,
      'brand': brand,
      'categories': categories,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copy with method untuk update field tertentu
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? name,
    String? brand,
    List<String>? categories,
    String? imageUrl,
    bool? isRead,
    String? userId,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      categories: categories ?? this.categories,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check apakah ini global notification
  bool get isGlobal => userId.isEmpty;

  /// Check apakah ini personal notification
  bool get isPersonal => userId.isNotEmpty;

  /// Get formatted date untuk display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      // Format: 20 Okt 2025
      return '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';
    }
  }

  /// Helper untuk nama bulan
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  /// Check apakah image adalah network URL
  bool get isNetworkImage => 
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  /// Check apakah image adalah asset
  bool get isAssetImage => 
      imageUrl.startsWith('assets/') || !isNetworkImage;

  /// Get safe image URL (return placeholder jika kosong)
  String get safeImageUrl => 
      imageUrl.isEmpty ? 'assets/images/placeholder.png' : imageUrl;

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, message: $message, '
        'isGlobal: $isGlobal, isRead: $isRead, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ═══════════════════════════════════════════════════════════════
// EXTENSION untuk kemudahan grouping/filtering
// ═══════════════════════════════════════════════════════════════

extension NotificationListExtension on List<AppNotification> {
  /// Filter hanya notifikasi yang belum dibaca
  List<AppNotification> get unreadOnly => 
      where((notif) => !notif.isRead).toList();

  /// Filter hanya notifikasi global
  List<AppNotification> get globalOnly => 
      where((notif) => notif.isGlobal).toList();

  /// Filter hanya notifikasi personal
  List<AppNotification> get personalOnly => 
      where((notif) => notif.isPersonal).toList();

  /// Filter berdasarkan category
  List<AppNotification> filterByCategory(String category) =>
      where((notif) => notif.categories.contains(category)).toList();

  /// Filter berdasarkan brand
  List<AppNotification> filterByBrand(String brand) =>
      where((notif) => notif.brand.toLowerCase() == brand.toLowerCase())
          .toList();

  /// Hitung jumlah notifikasi belum dibaca
  int get unreadCount => where((notif) => !notif.isRead).length;

  /// Group by date (today, yesterday, older)
  Map<String, List<AppNotification>> groupByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AppNotification>> grouped = {
      'Hari Ini': [],
      'Kemarin': [],
      'Sebelumnya': [],
    };

    for (var notif in this) {
      final notifDate = DateTime(
        notif.createdAt.year,
        notif.createdAt.month,
        notif.createdAt.day,
      );

      if (notifDate == today) {
        grouped['Hari Ini']!.add(notif);
      } else if (notifDate == yesterday) {
        grouped['Kemarin']!.add(notif);
      } else {
        grouped['Sebelumnya']!.add(notif);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  /// Sort by newest first
  List<AppNotification> sortByNewest() {
    final sorted = List<AppNotification>.from(this);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Sort by oldest first
  List<AppNotification> sortByOldest() {
    final sorted = List<AppNotification>.from(this);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }
}