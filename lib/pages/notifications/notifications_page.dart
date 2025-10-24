import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/notification_model.dart';
import 'package:my_app/theme/app_colors.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Silakan login terlebih dahulu",
            style: TextStyle(fontFamily: "Poppins"),
          ),
        ),
      );
    }

    print('🔑 Current User ID: ${currentUser.uid}');
    print('📧 Current User Email: ${currentUser.email}');

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Notifikasi",
          style: TextStyle(
            fontFamily: "Poppins",
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // PERBAIKAN: Baca dari collection root 'notifications'
        // Ambil semua, lalu filter di client-side
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print('═══════════════════════════════════════');
          print('🔍 StreamBuilder State:');
          print('   Connection: ${snapshot.connectionState}');
          print('   Has Data: ${snapshot.hasData}');
          print('   Has Error: ${snapshot.hasError}');
          
          if (snapshot.hasError) {
            print('   ❌ Error: ${snapshot.error}');
          }
          
          if (snapshot.hasData) {
            print('   📦 Raw Documents Count: ${snapshot.data!.docs.length}');
            
            // Print setiap dokumen
            for (var doc in snapshot.data!.docs) {
              print('   📄 Doc ID: ${doc.id}');
              final data = doc.data() as Map<String, dynamic>;
              print('      Title: ${data['title']}');
              print('      Message: ${data['message']}');
              print('      UserId: "${data['userId']}"');
              print('      ImageUrl: ${data['imageUrl']}');
            }
          }
          print('═══════════════════════════════════════');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Memuat notifikasi...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.black87,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48.sp,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Terjadi kesalahan",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        color: Colors.black87,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "${snapshot.error}",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        color: Colors.grey[600],
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.grey[400],
                    size: 64.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Belum ada notifikasi",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      color: Colors.black87,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Parse semua dokumen
          final allNotifications = snapshot.data!.docs.map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              print('✅ Parsing notification ${doc.id}: Success');
              return AppNotification.fromFirestore(data, doc.id);
            } catch (e, stackTrace) {
              print('❌ Error parsing notification ${doc.id}:');
              print('   Error: $e');
              print('   Stack: $stackTrace');
              return null;
            }
          }).whereType<AppNotification>().toList();

          print('📊 Total valid notifications: ${allNotifications.length}');

          // FILTER: Tampilkan global (userId kosong) ATAU personal (userId == current user)
          final notifications = allNotifications.where((notif) {
            final isGlobal = notif.userId.isEmpty;
            final isForCurrentUser = notif.userId == currentUser.uid;
            final shouldShow = isGlobal || isForCurrentUser;
            
            print('🔍 Notification ${notif.id}:');
            print('   userId: "${notif.userId}"');
            print('   isGlobal: $isGlobal');
            print('   isForCurrentUser: $isForCurrentUser');
            print('   shouldShow: $shouldShow');
            
            return shouldShow;
          }).toList();

          print('📊 Filtered notifications for user: ${notifications.length}');

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.grey[400],
                    size: 64.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Belum ada notifikasi",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      color: Colors.black87,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Total di database: ${allNotifications.length}",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      color: Colors.grey[500],
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              
              print('🎨 Rendering notification $index:');
              print('   Title: ${notif.title}');
              print('   Message: ${notif.message}');
              print('   Image: ${notif.imageUrl}');
              
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image di kiri
                    _buildNotificationImage(notif.imageUrl),
                    SizedBox(width: 12.w),
                    // Text di kanan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title/Message
                          Text(
                            notif.message.isNotEmpty 
                                ? notif.message 
                                : notif.title,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13.sp,
                              fontFamily: "Poppins",
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          // Date
                          Text(
                            DateFormat('d/M/yyyy, HH:mm', "id_ID")
                                .format(notif.createdAt),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[500],
                              fontFamily: "Poppins",
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unread indicator (dot merah)
                    if (!notif.isRead)
                      Container(
                        margin: EdgeInsets.only(left: 8.w, top: 4.h),
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationImage(String imageUrl) {
    print('🖼️ Building image widget for: "$imageUrl"');
    
    if (imageUrl.isEmpty) {
      print('⚠️ Image URL is empty, showing placeholder');
      return _buildPlaceholderImage();
    }

    // Network image
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('🌐 Loading network image: $imageUrl');
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Image.network(
          imageUrl,
          width: 100.w,
          height: 100.w,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('✅ Network image loaded successfully');
              return child;
            }
            return Container(
              width: 100.w,
              height: 100.w,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Network image failed: $error');
            return _buildPlaceholderImage();
          },
        ),
      );
    }

    // Asset image
    print('📁 Loading asset image: $imageUrl');
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Image.asset(
        imageUrl,
        width: 100.w,
        height: 100.w,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Asset image failed: $error');
          print('   Path: $imageUrl');
          print('   ⚠️ Make sure asset is declared in pubspec.yaml');
          return _buildPlaceholderImage();
        },
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        Icons.notifications_active,
        size: 40.sp,
        color: Colors.grey[400],
      ),
    );
  }
}