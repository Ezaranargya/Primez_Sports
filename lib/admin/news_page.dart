import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/news_model.dart';
import '../../models/chat_message.dart';

class AdminNewsPage extends StatefulWidget {
  const AdminNewsPage({super.key});

  @override
  State<AdminNewsPage> createState() => _AdminNewsPageState();
}

class _AdminNewsPageState extends State<AdminNewsPage> {
  final CollectionReference newsCollection =
      FirebaseFirestore.instance.collection('news');

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _contentTextController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  final List<String> _categories = [];
  final List<Map<String, String>> _contentItems = [];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _brandController.dispose();
    _imageController.dispose();
    _contentTextController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _titleController.clear();
    _subtitleController.clear();
    _authorController.clear();
    _brandController.clear();
    _imageController.clear();
    _contentTextController.clear();
    _categoryController.clear();
    _categories.clear();
    _contentItems.clear();
  }

  void _addNews() {
    _clearFields();

    showDialog(
      context: context,
      builder: (_) => _newsDialog(
        title: "Tambah Berita",
        onSave: () async {
          if (_titleController.text.isNotEmpty &&
              _contentItems.isNotEmpty) {
            await newsCollection.add({
              'title': _titleController.text,
              'subtitle': _subtitleController.text,
              'author': _authorController.text,
              'brand': _brandController.text,
              'imageUrl1': _imageController.text,
              'categories': _categories,
              'content': _contentItems,
              'createdAt': Timestamp.fromDate(DateTime.now()),
              'date': Timestamp.fromDate(DateTime.now()),
            });
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Judul dan konten harus diisi!')),
            );
          }
        },
      ),
    );
  }

  void _editNews(String id, NewsModel news) {
    _titleController.text = news.title;
    _subtitleController.text = news.subtitle;
    _authorController.text = news.author;
    _brandController.text = news.brand;
    _imageController.text = news.imageUrl1;
    _categories.clear();
    _categories.addAll(news.categories);
    _contentItems.clear();
    _contentItems.addAll(news.content.map((item) => {
      'type': item.type,
      if (item.text != null) 'text': item.text!,
      if (item.imageUrl != null) 'imageUrl': item.imageUrl!,
      if (item.caption != null) 'caption': item.caption!,
    }));

    showDialog(
      context: context,
      builder: (_) => _newsDialog(
        title: "Edit Berita",
        onSave: () async {
          await newsCollection.doc(id).update({
            'title': _titleController.text,
            'subtitle': _subtitleController.text,
            'author': _authorController.text,
            'brand': _brandController.text,
            'imageUrl1': _imageController.text,
            'categories': _categories,
            'content': _contentItems,
            'date': Timestamp.fromDate(DateTime.now()),
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      setState(() {
        _categories.add(_categoryController.text);
        _categoryController.clear();
      });
    }
  }

  void _addContentItem(String type) {
    if (type == 'text' && _contentTextController.text.isNotEmpty) {
      setState(() {
        _contentItems.add({
          'type': 'text',
          'text': _contentTextController.text,
        });
        _contentTextController.clear();
      });
    }
  }

  Widget _newsDialog({required String title, required VoidCallback onSave}) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul *"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(labelText: "Subtitle"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: "Author"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: "Brand"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _imageController,
                    decoration: const InputDecoration(labelText: "Path Asset Gambar Utama (contoh: assets/images/news1.png)"),
                  ),
                  const SizedBox(height: 16),
                  const Text("Kategori:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: "Tambah Kategori",
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _addCategory();
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) => Chip(
                      label: Text(cat),
                      onDeleted: () {
                        setDialogState(() {
                          _categories.remove(cat);
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("Konten:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentTextController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Text Konten *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _addContentItem('text');
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Tambah Text"),
                  ),
                  const SizedBox(height: 8),
                  if (_contentItems.isNotEmpty) ...[
                    const Text("Item Konten:", style: TextStyle(fontSize: 12)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _contentItems.length,
                      itemBuilder: (context, index) {
                        final item = _contentItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              item['type'] == 'text' ? Icons.text_fields : Icons.image,
                              size: 20,
                            ),
                            title: Text(
                              item['text'] ?? item['caption'] ?? item['imageUrl'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            subtitle: Text(
                              'Type: ${item['type']}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  _contentItems.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearFields();
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: onSave,
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola News")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNews,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: newsCollection.orderBy("date", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Belum ada berita"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final news = NewsModel.fromFirestore(data, docs[index].id);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: news.imageUrl1.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            news.imageUrl1,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                  title: Text(
                    news.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (news.subtitle.isNotEmpty)
                        Text(
                          news.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        news.contentAsText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: news.categories.take(3).map((cat) => Chip(
                          label: Text(cat, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editNews(news.id, news),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi'),
                              content: const Text('Hapus berita ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await newsCollection.doc(news.id).delete();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}