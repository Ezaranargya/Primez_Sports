import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String userId;
  final String username;
  final String bio;
  final double size;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.userId,
    required this.username,
    required this.bio,
    this.size = 40,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('👤 UserAvatar Widget Build:');
    debugPrint('   userId: $userId');
    debugPrint('   username: $username');
    debugPrint('   photoUrl: ${photoUrl ?? "NULL"}');
    debugPrint('   photoUrl length: ${photoUrl?.length ?? 0}');
    debugPrint('   bio: $bio');
    
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      debugPrint('   ✅ Using provided photoUrl (${photoUrl!.length} chars)');
      return _buildAvatar(photoUrl!);
    }

    debugPrint('   ⚠️ photoUrl NULL/EMPTY, fetching from Firestore...');
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('   ⏳ Loading from Firestore...');
          return _buildLoadingAvatar();
        }

        if (snapshot.hasError) {
          debugPrint('   ❌ Error fetching from Firestore: ${snapshot.error}');
          return _buildFallbackAvatar();
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final fetchedPhotoUrl = data?['photoBase64'] ?? 
                                  data?['photoUrl'] ?? '';

          debugPrint('   📦 Firestore data fetched:');
          debugPrint('      photoBase64: ${data?['photoBase64']?.toString().length ?? 0} chars');
          debugPrint('      photoUrl: ${data?['photoUrl']?.toString().length ?? 0} chars');
          debugPrint('      Final: ${fetchedPhotoUrl.length} chars');

          if (fetchedPhotoUrl.isNotEmpty) {
            debugPrint('   ✅ Using fetched photo from Firestore');
            return _buildAvatar(fetchedPhotoUrl);
          }
        }

        debugPrint('   ⚠️ No photo found, using fallback avatar');
        return _buildFallbackAvatar();
      },
    );
  }

  Widget _buildAvatar(String url) {
    debugPrint('   🎨 Building avatar with URL length: ${url.length}');
    
    Widget avatarWidget;

    if (url.startsWith('data:image')) {
      debugPrint('   📷 Detected data:image format');
      
      if (!url.contains(',')) {
        debugPrint('   ❌ Invalid format: no comma separator');
        return _buildFallbackAvatar();
      }
      
      try {
        final base64String = url.split(',')[1];
        debugPrint('   📦 Extracted base64: ${base64String.length} chars');
        
        final bytes = base64Decode(base64String);
        debugPrint('   ✅ Decoded to ${bytes.length} bytes');
        
        avatarWidget = CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('   ❌ Error loading base64 avatar: $exception');
          },
        );
      } catch (e) {
        debugPrint('   ❌ Error decoding base64 avatar: $e');
        return _buildFallbackAvatar();
      }
    } 

    else if (url.startsWith('http')) {
      debugPrint('   🌐 Detected HTTP URL');
      avatarWidget = CircleAvatar(
        radius: size / 2,
        backgroundImage: CachedNetworkImageProvider(url),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('   ❌ Error loading network avatar: $exception');
        },
      );
    } 

    else {
      debugPrint('   📝 Attempting raw base64 decode');
      try {
        final bytes = base64Decode(url);
        debugPrint('   ✅ Raw base64 decoded: ${bytes.length} bytes');
        avatarWidget = CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        debugPrint('   ❌ Raw base64 decode failed: $e');
        return _buildFallbackAvatar();
      }
    }

    if (showBorder) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: Center(
        child: SizedBox(
          width: size / 2,
          height: size / 2,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    debugPrint('   💬 Building fallback avatar with initial: ${username.isNotEmpty ? username[0] : "?"}');
    
    final initial = username.isNotEmpty 
        ? username[0].toUpperCase() 
        : '?';

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final colorIndex = userId.hashCode % colors.length;
    final color = colors[colorIndex];

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size / 2.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class UserAvatarSimple extends StatelessWidget {
  final String? photoUrl;
  final String username;
  final String bio;
  final double size;

  const UserAvatarSimple({
    super.key,
    this.photoUrl,
    required this.username,
    required this.bio,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return _buildFallbackAvatar();
    }

   
    if (photoUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    try {
      final bytes = base64Decode(photoUrl!);
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(bytes),
      );
    } catch (e) {
      return _buildFallbackAvatar();
    }
  }

  Widget _buildFallbackAvatar() {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade400,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size / 2.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}