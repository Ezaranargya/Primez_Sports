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
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  void _addNews() {
    _titleController.clear();
    _contentController.clear();
    _imageController.clear();

    showDialog(
      context: context,
      builder: (_) => _newsDialog(
        title: "Tambah Berita",
        onSave: () async {
          if (_titleController.text.isNotEmpty &&
              _contentController.text.isNotEmpty) {
            await newsCollection.add({
              'title': _titleController.text,
              'content': _contentController.text,
              'imageUrl': _imageController.text,
              'createdAt': DateTime.now(),
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _editNews(String id, News news) {
    _titleController.text = news.title;
    _contentController.text = news.content;
    _imageController.text = news.imageUrl;

    showDialog(
      context: context,
      builder: (_) => _newsDialog(
        title: "Edit Berita",
        onSave: () async {
          await newsCollection.doc(id).update({
            'title': _titleController.text,
            'content': _contentController.text,
            'imageUrl': _imageController.text,
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _newsDialog({required String title, required VoidCallback onSave}) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Judul")),
            TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: "Isi Berita")),
            TextField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: "URL Gambar")),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal")),
        ElevatedButton(onPressed: onSave, child: const Text("Simpan")),
      ],
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
        stream:
            newsCollection.orderBy("createdAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error load data"));
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
              final news = News.fromMap(docs[index].id, data);

              return ListTile(
                leading: news.imageUrl.isNotEmpty
                    ? Image.network(news.imageUrl,
                        width: 60, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 50, color: Colors.grey),
                title: Text(news.title),
                subtitle: Text(
                  news.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editNews(news.id, news),
                ),
                onLongPress: () async {
                  await newsCollection.doc(news.id).delete();
                },
              );
            },
          );
        },
      ),
    );
  }
}


class AdminChatsPage extends StatefulWidget {
  const AdminChatsPage({super.key});

  @override
  State<AdminChatsPage> createState() => _AdminChatsPageState();
}

class _AdminChatsPageState extends State<AdminChatsPage> {
  final CollectionReference chatsCollection =
      FirebaseFirestore.instance.collection('chats');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Chats")),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error mengambil data chat"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const Center(child: Text("Belum ada chat"));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              return ListTile(
                title: Text("Chat ID: ${chatDoc.id}"),
                subtitle: const Text("Klik untuk lihat pesan"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailPage(chatId: chatDoc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatDetailPage extends StatelessWidget {
  final String chatId;

  const ChatDetailPage({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final messagesCollection = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    return Scaffold(
      appBar: AppBar(title: Text("Detail Chat: $chatId")),
      body: StreamBuilder<QuerySnapshot>(
        stream: messagesCollection.orderBy("createdAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error mengambil pesan"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Belum ada pesan"));
          }

          return ListView.builder(
            reverse: true,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final message = ChatMessage.fromMap(docs[index].id, data);

              return ListTile(
                title: Text(message.text),
                subtitle: Text(
                  "Dari: ${message.senderId} | ${message.createdAt}",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await messagesCollection.doc(message.id).delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
