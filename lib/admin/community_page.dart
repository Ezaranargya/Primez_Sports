import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminCommunityPage extends StatefulWidget {
  const AdminCommunityPage({super.key});

  @override
  State<AdminCommunityPage> createState() => _AdminCommunityPageState();
}

class _AdminCommunityPageState extends State<AdminCommunityPage> {
  final TextEditingController _nameController = TextEditingController();
  final CollectionReference communities =
      FirebaseFirestore.instance.collection('communities');

  Future<void> addCommunity(String name) async {
    await communities.add({
      'name': name,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateCommunity(String id, String newName) async {
    await communities.doc(id).update({'name': newName});
  }

  Future<void> deleteCommunity(String id) async {
    await communities.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Komunitas'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Komunitas',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      addCommunity(_nameController.text);
                      _nameController.clear();
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: communities.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Gagal memuat data'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('Belum ada komunitas'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      return Card(
                        child: ListTile(
                          title: Text(data['name']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  updateCommunity(data.id, '${data['name']} (edit)');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteCommunity(data.id),
                              ),
                            ],
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
