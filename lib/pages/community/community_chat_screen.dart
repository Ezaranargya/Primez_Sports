import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityChatScreen extends StatefulWidget {
  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kumpulan Brand Nike Official'),
      ),

      /// ===============================
      /// 🔥 STREAM REALTIME FIRESTORE
      /// ===============================
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Belum ada postingan"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();

              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: _buildPostCard(
                  userId: data['userId'] ?? '',
                  username: data['username'] ?? 'User',
                  userPhoto: data['userPhotoUrl'] ?? '',
                  imageUrl: data['imageUrl'] ?? '',
                  description: data['description'] ?? '',
                  createdAt: (data['createdAt'] as Timestamp).toDate(),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  // ===============================
  // CARD POSTINGAN (MILIKMU)
  // ===============================
  Widget _buildPostCard({
    required String userId,
    required String username,
    required String userPhoto,
    required String imageUrl,
    required String description,
    required DateTime createdAt,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 2),
            blurRadius: 5,
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showUserProfileBottomSheet(
                  userId: userId,
                  username: username,
                  userPhoto: userPhoto,
                ),
                child: _buildUserAvatar(userPhoto),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatTimeAgo(createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_vert),
            ],
          ),

          SizedBox(height: 12.h),
          _buildPostImage(imageUrl),

          SizedBox(height: 12.h),
          Text(
            description,
            style: TextStyle(fontSize: 14.sp, height: 1.4),
          )
        ],
      ),
    );
  }

  // ===============================
  // USER PROFILE BOTTOM SHEET
  // ===============================
  void _showUserProfileBottomSheet({
    required String userId,
    required String username,
    required String userPhoto,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              SizedBox(height: 20.h),
              _buildUserAvatar(userPhoto, radius: 40),

              SizedBox(height: 12.h),
              Text(
                username,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToUserProfile(userId, username);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Lihat Profil',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  void _navigateToUserProfile(String userId, String username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membuka profil $username'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ===============================
  // AVATAR
  // ===============================
  Widget _buildUserAvatar(String url, {double radius = 22}) {
    final trimmed = url.trim();

    if (trimmed.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: const Icon(Icons.person),
      );
    }

    if (trimmed.startsWith("http")) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(trimmed),
      );
    }

    final bytes = _decodeBase64(trimmed);
    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: const Icon(Icons.person),
    );
  }

  // ===============================
  // GAMBAR POST
  // ===============================
  Widget _buildPostImage(String url) {
    final trimmed = url.trim();

    if (trimmed.isEmpty) return _imagePlaceholder();

    if (trimmed.startsWith("http")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          trimmed,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    }

    final bytes = _decodeBase64(trimmed);
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
        ),
      );
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: const Center(
        child: Text("Gambar tidak dapat dimuat"),
      ),
    );
  }

  Uint8List? _decodeBase64(String src) {
    try {
      String cleaned = src
          .replaceAll("\n", "")
          .replaceAll("\r", "")
          .replaceAll(" ", "")
          .trim();

      if (cleaned.contains(",")) {
        cleaned = cleaned.split(",").last;
      }

      cleaned = cleaned.replaceAll(RegExp(r"\s+"), "");

      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit yang lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam yang lalu";
    if (diff.inDays < 7) return "${diff.inDays} hari yang lalu";

    return DateFormat('dd MMM yyyy').format(time);
  }
}
