import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String subtitle;
  final String author;
  final String brand;
  final DateTime date;
  final DateTime createdAt;
  final List<String> categories;
  final String imageUrl1;
  final String imageAsset;
  final List<ContentBlock> content;

  News({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.author,
    required this.brand,
    required this.date,
    required this.createdAt,
    required this.categories,
    required this.imageUrl1,
    required this.content,
    this.imageAsset = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'author': author,
      'brand': brand,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'categories': categories,
      'imageUrl1': imageUrl1,
      'imageAsset': imageAsset,
      'content': content.map((block) => block.toMap()).toList(),
    };
  }

  factory News.fromMap(Map<String, dynamic> map, String id) {
    final rawImage = map['imageUrl1'] ?? map['imageUrl'] ?? '';

    String assetPath = '';
    if (rawImage is String && rawImage.startsWith('assets/')) {
      assetPath = rawImage;
    }
    print("🔥 Firestore content field for $id: ${map['content']}");

    return News(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      author: map['author'] ?? '',
      brand: map['brand'] ?? '',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      categories: List<String>.from(map['categories'] ?? []),
      imageUrl1: rawImage,
      imageAsset: assetPath,
      content: (map['content'] != null)
          ? (map['content'] is List)
              ? (map['content'] as List)
                  .whereType<Map>()
                  .map((item) =>
                      ContentBlock.fromMap(Map<String, dynamic>.from(item)))
                  .toList()
              : [
                  ContentBlock(
                    type: 'text',
                    value: map['content'].toString(),
                  )
                ]
          : [],
    );
  }

    factory News.fromFirestore(Map<String, dynamic> data, String id) {
    return News.fromMap(data, id);
  }

  String get imageUrl => imageUrl1;
  String get safeImageAsset =>
      imageAsset.isNotEmpty ? imageAsset : 'assets/images/default_news.png';

  String get contentAsText {
    return content
        .where((item) => item.value.isNotEmpty && item.type == 'text')
        .map((item) => item.value)
        .join('\n\n');
  }
}

class ContentBlock {
  final String type;   final String value;
  final String? caption;

  ContentBlock({
    required this.type,
    required this.value,
    this.caption,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      'caption': caption ?? '',
            if (type == 'text') 'text': value,
      if (type == 'image') 'imageUrl': value,
    };
  }

  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    final type = map['type'] ?? 'text';
    String value = '';

        if (type == 'text') {
      value = map['value'] ?? map['text'] ?? '';
    } else if (type == 'image') {
      value = map['value'] ?? map['imageUrl'] ?? '';
    }

    return ContentBlock(
      type: type,
      value: value,
      caption: map['caption'] as String?,
    );
  }

    String? get text => type == 'text' ? value : null;
  String? get imageUrl => type == 'image' ? value : null;
}

typedef NewsModel = News;
typedef ContentItem = ContentBlock;