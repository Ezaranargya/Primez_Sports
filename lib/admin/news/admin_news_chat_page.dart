import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:intl/intl.dart';

class AdminNewsChatPage extends StatefulWidget {
  final String newsId;
  final String newsTitle;

  const AdminNewsChatPage({
    super.key,
    required this.newsId,
    required this.newsTitle,
  });

  @override
  State<AdminNewsChatPage> createState() => _AdminNewsChatPageState();
}

class _AdminNewsChatPageState extends State<AdminNewsChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await _firestore
          .collection('news')
          .doc(widget.newsId)
          .collection('chats')
          .add({
        'message': message,
        'sender': 'admin',
        'senderName': 'Admin',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      _messageController.clear();
      
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('news')
          .doc(widget.newsId)
          .collection('chats')
          .doc(messageId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pesan'),
        content: const Text('Apakah Anda yakin ingin menghapus pesan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat Berita',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.newsTitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white.withOpacity(0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('news')
                  .doc(widget.newsId)
                  .collection('chats')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Belum ada pesan',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Mulai percakapan dengan pengguna',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[500],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.w),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isAdmin = data['sender'] == 'admin';
                    final message = data['message'] ?? '';
                    final senderName = data['senderName'] ?? 'Unknown';
                    final timestamp = data['timestamp'] as Timestamp?;

                    return _buildMessageBubble(
                      messageId: doc.id,
                      message: message,
                      senderName: senderName,
                      isAdmin: isAdmin,
                      timestamp: timestamp,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String messageId,
    required String message,
    required String senderName,
    required bool isAdmin,
    Timestamp? timestamp,
  }) {
    final formatTime = DateFormat('HH:mm');
    final formatDate = DateFormat('dd MMM yyyy');
    
    String timeString = '';
    if (timestamp != null) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        timeString = formatTime.format(date);
      } else if (difference.inDays == 1) {
        timeString = 'Kemarin ${formatTime.format(date)}';
      } else {
        timeString = '${formatDate.format(date)} ${formatTime.format(date)}';
      }
    }

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isAdmin ? () => _confirmDelete(messageId) : null,
        child: Container(
          margin: EdgeInsets.only(
            bottom: 12.h,
            left: isAdmin ? 60.w : 0,
            right: isAdmin ? 0 : 60.w,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isAdmin ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(isAdmin ? 16.r : 4.r),
              bottomRight: Radius.circular(isAdmin ? 4.r : 16.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isAdmin)
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                  ),
                ),
              if (!isAdmin) SizedBox(height: 4.h),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isAdmin ? Colors.white : Colors.black87,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                timeString,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isAdmin ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 24.r,
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}