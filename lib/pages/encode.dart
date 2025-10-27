import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class EncodecodeExample extends StatefulWidget{
  const EncodecodeExample ({super.key});

  @override
  _EncodecodeExampleState createState () => _EncodecodeExampleState();
}

class _EncodecodeExampleState extends State<EncodecodeExample> {
  File? _imageFile;
  String? _base64Image;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final imageFile = File(picked.path);

      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _imageFile = imageFile;
        _base64Image = base64String;
      });

      print('✅ Base64 Image: $_base64Image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Encode & Decode Base64')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile != null
            ? Image.file(_imageFile!)
            : Text('Belum ada gambar'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage, 
              child: Text('Pilih Gambar'),
              ),
              SizedBox(height: 20),
              if (_base64Image != null)
              ElevatedButton(
                onPressed: () {
                  final decodeBytes = base64Decode(_base64Image!);
                  showDialog(
                    context: context, 
                    builder: (_) => AlertDialog(
                      content: Image.memory(decodeBytes),
                    ),
                    );
                }, 
                child: Text('Lihat hasil decode'),
                )
          ],
        ),
      ),
    );
  }
}