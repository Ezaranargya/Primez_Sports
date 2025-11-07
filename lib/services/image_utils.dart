import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

String imageFileToBase64(File file)  {
  List<int> bytes = file.readAsBytesSync();
  return base64Encode(bytes);
}

Uint8List base64ToImage(String base64String) {
  return base64Decode(base64String);
}