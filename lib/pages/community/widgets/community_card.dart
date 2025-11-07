import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommunityCard extends StatelessWidget {
  final String title;
  final String brand;
  final String? logoUrl;   final VoidCallback onTap;

  const CommunityCard({
    super.key,
    required this.title,
    required this.brand,
    this.logoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> brandLogos = {
      "Nike": "assets/logo_nike.png",
      "Jordan": "assets/logo_jordan.png",
      "Adidas": "assets/logo_adidas.png",
      "Under Armour": "assets/logo_under_armour.png",
      "Puma": "assets/logo_puma.png",
      "Mizuno": "assets/logo_mizuno.png",
    };

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor: Colors.grey[200],
          child: _buildLogo(brandLogos, brand, logoUrl),         ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}


bool _isBase64(String? str) {
  if (str == null || str.isEmpty) return false;
  final base64RegExp = RegExp(r'^[A-Za-z0-9+/=]+$');
  return str.length > 200 &&
      base64RegExp.hasMatch(str.replaceAll('\n', '').replaceAll('\r', ''));
}

String _cleanBase64(String base64Str) {
  return base64Str.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '');
}

Widget _buildLogo(Map<String, String> brandLogos, String brand, String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
        if (_isBase64(logoUrl)) {
      try {
        final cleaned = _cleanBase64(logoUrl).replaceAll(RegExp(r'\s+'), '');
        return Image.memory(
          base64Decode(cleaned),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.store, size: 20.sp, color: Colors.grey);
          },
        );
      } catch (_) {
        return Icon(Icons.store, size: 20.sp, color: Colors.grey);
      }
    } else {
            return Image.network(
        logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.store, size: 20.sp, color: Colors.grey);
        },
      );
    }
  }

    if (brandLogos.containsKey(brand)) {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: Image.asset(
        brandLogos[brand]!,
        fit: BoxFit.contain,
        width: 24.w,
        height: 24.w,
      ),
    );
  }

    return Text(
    brand[0].toUpperCase(),
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14.sp,
      color: Colors.black87,
    ),
  );
}
