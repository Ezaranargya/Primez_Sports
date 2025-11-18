import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_app/theme/app_colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifikasi', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('Silakan login terlebih dahulu'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            onPressed: () => _markAllAsRead(context, userId),
            tooltip: 'Tandai semua sudah dibaca',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getCombinedNotifications(userId),
        builder: (context, snapshot) {
          print('🔔 Connection state: ${snapshot.connectionState}');
          print('🔔 Has data: ${snapshot.hasData}');
          print('🔔 Current user UID: $userId');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            print('🔔 Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
                        ),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];
          print('🔔 Notifications count: ${notifications.length}');

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['isRead'] ?? false;
              final source = notif['source'] ?? 'personal';
              final imageUrl = notif['imageUrl'] as String?;
              
              print('🖼️ [Notif ${index}] Title: ${notif['title']}');
              print('🖼️ [Notif ${index}] ImageUrl exists: ${imageUrl != null}');
              print('🖼️ [Notif ${index}] ImageUrl length: ${imageUrl?.length ?? 0}');
              if (imageUrl != null && imageUrl.isNotEmpty) {
                print('🖼️ [Notif ${index}] First 50 chars: ${imageUrl.substring(0, imageUrl.length > 50 ? 50 : imageUrl.length)}');
              }

              return Dismissible(
                key: Key('${source}_${notif['id']}'),
                direction: source == 'personal'
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (source != 'personal') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi global tidak dapat dihapus'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return false;
                  }
                  return true;
                },
                onDismissed: (direction) {
                  if (source == 'personal') {
                    _deleteNotification(userId, notif['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifikasi dihapus')),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : AppColors.secondary,
                    borderRadius: BorderRadius.circular(8.r)
                  ),
                  child: ListTile(
                    leading: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(imageUrl),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return CircleAvatar(
                                  backgroundColor: isRead ? Colors.grey : AppColors.primary,
                                  child: Icon(
                                    _getNotificationIcon(notif['type']),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: isRead ? Colors.grey : AppColors.primary,
                            child: Icon(
                              _getNotificationIcon(notif['type']),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                    title: Text(
                      notif['title'] ?? 'Notifikasi',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (notif['message'] != null && notif['message'].toString().isNotEmpty)
                          Text(
                            notif['message'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatTimestamp(notif['createdAt'] ?? notif['timestamp']),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (source == 'global') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Global',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: !isRead
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () => _handleNotificationTap(context, userId, notif),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedNotifications(String userId) {
    final personalStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return personalStream.asyncMap((personalSnapshot) async {
      final List<Map<String, dynamic>> allNotifications = [];

      for (var doc in personalSnapshot.docs) {
        final data = doc.data();
        allNotifications.add({
          'id': doc.id,
          'source': 'personal',
          'title': data['title'] ?? 'Notifikasi',
          'message': data['message'] ?? data['body'] ?? '',
          'type': data['type'] ?? 'general',
          'createdAt': data['createdAt'] ?? data['timestamp'],
          'isRead': data['isRead'] ?? false,
          'productId': data['productId'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'data': data,
        });
      }

      try {
        final globalSnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw TimeoutException('Global notifications timeout'),
            );

        print('✅ Successfully fetched ${globalSnapshot.docs.length} global notifications');

        Set<String> readGlobalIds = {};
        try {
          final readGlobalSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('readGlobalNotifications')
              .get()
              .timeout(const Duration(seconds: 3));
          
          readGlobalIds = readGlobalSnapshot.docs.map((doc) => doc.id).toSet();
          print('📚 User has read ${readGlobalIds.length} global notifications');
        } catch (e) {
          print('⚠️ Cannot get readGlobalNotifications: $e');
        }

        for (var doc in globalSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final isReadGlobal = readGlobalIds.contains(doc.id);
          
          allNotifications.add({
            'id': doc.id,
            'source': 'global',
            'title': data['title'] ?? 'Notifikasi',
            'message': data['message'] ?? data['body'] ?? '',
            'type': data['type'] ?? 'general',
            'createdAt': data['createdAt'] ?? data['timestamp'],
            'isRead': isReadGlobal,
            'productId': data['productId'] ?? '',
            'imageUrl': data['imageUrl'] ?? '',
            'data': data,
          });
        }
      } catch (e) {
        print('⚠️ Error fetching global notifications: $e');
      }


      allNotifications.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];

        if (aTime == null) return 1;
        if (bTime == null) return -1;

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        return 0;
      });

      return allNotifications;
    });
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'promo':
        return Icons.local_offer;
      case 'product':
        return Icons.inventory;
      case 'community':
        return Icons.forum;
      case 'news':
        return Icons.article;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Baru saja';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Baru saja';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    String userId,
    Map<String, dynamic> notif,
  ) {
    if (notif['source'] == 'personal') {
      _markAsRead(userId, notif['id']);
    } else if (notif['source'] == 'global') {
      _markGlobalAsRead(userId, notif['id']);
    }

    final productId = notif['productId'] ?? '';

    if (productId.isNotEmpty) {
      context.push('/product-detail?id=$productId');
      return;
    }

    _showNotificationDetail(context, notif);
  }

  void _showNotificationDetail(BuildContext context, Map<String, dynamic> notif) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notif['title'] ?? 'Notifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notif['message'] != null && notif['message'].toString().isNotEmpty)
              Text(notif['message']),
            if (notif['imageUrl'] != null && notif['imageUrl'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(notif['imageUrl']),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(String userId, String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markGlobalAsRead(String userId, String globalNotifId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('readGlobalNotifications')
          .doc(globalNotifId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); 
      print('✅ Global notification marked as read: $globalNotifId');
    } catch (e) {
      print('❌ Error marking global notification as read: $e');
    }
  }

  Future<void> _markAllAsRead(BuildContext context, String userId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: const Text('Tandai Semua Sudah Dibaca?'),
        content: const Text(
          'Semua notifikasi akan ditandai sebagai sudah dibaca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              elevation: 25,
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )
            ),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final batch = FirebaseFirestore.instance.batch();
                
                final personalNotifications = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .get()
                    .timeout(const Duration(seconds: 10));

                for (var doc in personalNotifications.docs) {
                  batch.update(doc.reference, {'isRead': true});
                }

                print('📝 Prepared ${personalNotifications.docs.length} personal notifications for update');

                try {
                  final globalNotifications = await FirebaseFirestore.instance
                      .collection('notifications')
                      .get()
                      .timeout(const Duration(seconds: 10));

                  print('📝 Fetched ${globalNotifications.docs.length} global notifications');

                  for (var doc in globalNotifications.docs) {
                    final readGlobalRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('readGlobalNotifications')
                        .doc(doc.id);
                    
                    batch.set(readGlobalRef, {
                      'readAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                  }

                  print('📝 Prepared ${globalNotifications.docs.length} global notifications for update');
                } catch (e) {
                  print('⚠️ Error preparing global notifications: $e');
                }

                await batch.commit().timeout(const Duration(seconds: 15));

                print('✅ All notifications marked as read successfully');

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi ditandai sudah dibaca'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error marking all notifications as read: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menandai notifikasi: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )
            ),
            child: const Text('Iya'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotification(String userId, String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}