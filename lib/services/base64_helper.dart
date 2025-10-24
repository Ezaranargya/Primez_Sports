import 'dart:io';
import 'dart:convert';

String fileToBase64(File file) {
  return base64Encode(file.readAsBytesSync());
}

File base64ToFile(String base64Str, String path) {
  final bytes = base64Decode(base64Str);
  return File(path)..writeAsBytesSync(bytes);
}
  