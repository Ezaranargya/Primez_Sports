import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> uploadImage(File file, {String? folder}) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String path = folder != null ? '$folder/$fileName.png' : 'images/$fileName.png';

      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('images').add({
        'url': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploadImage: $e');
      return null;
    }
  }

  String fileToBase64(File file) {
    List<int> bytes = file.readAsBytesSync();
    return base64Encode(bytes);
  }

  Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }
}
