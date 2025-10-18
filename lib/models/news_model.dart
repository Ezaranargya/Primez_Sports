import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String author;
  final String brand;
  final List<String> categories;
  final List<ContentItem> content;
  final DateTime createdAt;
  final DateTime date;
  final String imageUrl1;
  final String subtitle;
  final String imageAsset;

  NewsModel({
    required this.id,
    required this.title,
    required this.author,
    required this.brand,
    required this.categories,
    required this.content,
    required this.createdAt,
    required this.date,
    required this.imageUrl1,
    required this.subtitle,
    this.imageAsset = '',
  });

  factory NewsModel.fromFirestore(Map<String, dynamic> data, String id) {
  final rawImage = data['imageUrl1'] ?? data['imageUrl'] ?? '';

  String assetPath = '';
  if (rawImage is String && rawImage.startsWith('assets/')) {
    assetPath = rawImage;
  }
  print("🔥 Firestore content field for $id: ${data['content']}");

  return NewsModel(
    id: id,
    title: data['title'] ?? '',
    author: data['author'] ?? '',
    brand: data['brand'] ?? '',
    categories: List<String>.from(data['categories'] ?? []),
    content: (data['content'] != null && data['content'] is List)
        ? (data['content'] as List)
            .whereType<Map>()
            .map((item) =>
                ContentItem.fromMap(Map<String, dynamic>.from(item)))
            .toList()
        : [],

    createdAt: (data['createdAt'] is Timestamp)
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    date: (data['date'] is Timestamp)
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now(),
    imageUrl1: rawImage,
    subtitle: data['subtitle'] ?? '',
    imageAsset: assetPath,
  );
}

  String get imageUrl => imageUrl1;
  String get safeImageAsset =>
      imageAsset.isNotEmpty ? imageAsset : 'assets/images/default_news.png';

  String get contentAsText {
    return content
        .where((item) => item.text != null)
        .map((item) => item.text!)
        .join('\n\n');
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'brand': brand,
      'categories': categories,
      'content': content.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'date': Timestamp.fromDate(date),
      'imageUrl1': imageUrl1,
      'subtitle': subtitle,
      'imageAsset': imageAsset,
    };
  }
}

class ContentItem {
  final String? imageUrl;
  final String? caption;
  final String? text;
  final String type;

  ContentItem({
    this.imageUrl,
    this.caption,
    this.text,
    required this.type,
  });

  factory ContentItem.fromMap(Map<String, dynamic> map) {
    return ContentItem(
      imageUrl: map['imageUrl'],
      caption: map['caption'],
      text: map['text'],
      type: map['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {'type': type};
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (caption != null) data['caption'] = caption;
    if (text != null) data['text'] = text;
    return data;
  }
}
