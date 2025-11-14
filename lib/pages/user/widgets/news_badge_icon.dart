// lib/pages/user/widgets/news_badge_icon.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/news_model.dart';

class NewsBadgeIcon extends StatelessWidget {
  final bool isActive;

  const NewsBadgeIcon({super.key, this.isActive = false});

  Stream<int> getUnreadNewsCountStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('news')
        .snapshots()
        .map((snapshot) {
      final newsList = snapshot.docs
          .map((doc) => News.fromMap(doc.data(), doc.id))
          .toList();

      return newsList.where((news) => !news.isReadBy(userId)).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: getUnreadNewsCountStream(),
      builder: (context, snapshot) {
        final unreadNewsCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isActive ? Icons.newspaper : Icons.newspaper_outlined,
            ),
            if (unreadNewsCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadNewsCount > 9 ? '9+' : '$unreadNewsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}