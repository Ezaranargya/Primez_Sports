import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAvatar extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final String? base64Image;
  final double size;

  const ProfileAvatar({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.base64Image,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (imageFile != null && imageFile!.existsSync()) {
      imageProvider = FileImage(imageFile!);
    } else if (base64Image != null && base64Image!.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image!);
        imageProvider = MemoryImage(bytes);
      } catch (_) {
        imageProvider = const AssetImage('assets/images/default_profile.png');
      }
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl!);
    } else {
      imageProvider = const AssetImage('assets/images/default_profile.png');
    }

    return ClipOval(
      child: Image(
        image: imageProvider,
        width: size.w,
        height: size.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size.w,
          height: size.w,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_outline,
              size: size / 2, color: Colors.grey[600]),
        ),
      ),
    );
  }
}
