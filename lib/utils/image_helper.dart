import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
