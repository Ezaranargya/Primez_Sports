import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ImageHelper {
  static Future<String?> pickImageAsBase64() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final bytes = await File(pickedFile.path).readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('❌ Error picking or encoding image: $e');
      return null;
    }
  }

  static Future<String?> xFileToBase64(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('❌ Error converting XFile to Base64: $e');
      return null;
    }
  }

  static Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('❌ Error converting File to Base64: $e');
      return null;
    }
  }
}


bool isBase64(String str) {
  if (str.isEmpty) return false;
  final base64RegExp = RegExp(r'^[A-Za-z0-9+/=]+$');
  return str.length > 200 &&
      base64RegExp.hasMatch(str.replaceAll('\n', '').replaceAll('\r', ''));
}

String cleanBase64(String base64Str) {
  return base64Str.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '');
}

Widget buildLogo(String logoUrl) {
  if (logoUrl.startsWith('assets/')) {
    return Image.asset(
      logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.store, size: 24.sp, color: Colors.grey),
    );
  } else if (isBase64(logoUrl)) {
    try {
      final cleaned = cleanBase64(logoUrl).replaceAll(RegExp(r'\s+'), '');
      return Image.memory(
        base64Decode(cleaned),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.store, size: 24.sp, color: Colors.grey),
      );
    } catch (_) {
      return Icon(Icons.store, size: 24.sp, color: Colors.grey);
    }
  } else {
    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.store, size: 24.sp, color: Colors.grey),
    );
  }
}


String formatRupiah(num price) {
  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatCurrency.format(price);
}

String formatCurrency(num value) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(value);
}
