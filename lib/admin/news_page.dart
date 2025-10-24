import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminNewsPage extends StatefulWidget {
  const AdminNewsPage({super.key});

  @override
  State<AdminNewsPage> createState() => _AdminNewsPageState();
}

class _AdminNewsPageState extends State<AdminNewsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final CollectionReference news = FirebaseFirestore.instance.collection('news');

  Future<void> addNews(String title, String content) async {
    await news.add({
      'title': title,
      'content': content,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteNews(String id) async {
    await news.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola News'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Berita'),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Isi Berita'),
              maxLines: 3,
            ),
            SizedBox(height: 10.h),
            ElevatedButton.icon(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _contentController.text.isNotEmpty) {
                  addNews(_titleController.text, _contentController.text);
                  _titleController.clear();
                  _contentController.clear();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Berita'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 45.h),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: news.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Gagal memuat berita'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('Belum ada berita'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12.h),
                        child: ListTile(
                          title: Text(
                            data['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            data['content'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteNews(data.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
