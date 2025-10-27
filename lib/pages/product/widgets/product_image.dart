import 'dart:convert';
import 'package:flutter/material.dart';

/// ============================================================
/// 🔹 REUSABLE PRODUCT IMAGE WIDGET
/// ============================================================
/// Widget ini bisa dipakai di:
/// - Product Card (Homepage)
/// - Product Detail Page
/// - Favorite List
/// - Search Results
/// ============================================================
class ProductImage extends StatelessWidget {
  final String? imageBase64;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    Key? key,
    this.imageBase64,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ DEBUG: Print what we receive
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      print('🖼️ ProductImage: Has imageBase64 (${imageBase64!.length} chars)');
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      print('🖼️ ProductImage: Has imageUrl: $imageUrl');
    } else {
      print('⚠️ ProductImage: No image available');
    }

    Widget imageWidget;

    // ✅ PRIORITY 1: Base64 image (dari admin upload)
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      imageWidget = _buildBase64Image();
    }
    // ✅ PRIORITY 2: Network image URL
    else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = _buildNetworkImage();
    }
    // ✅ PRIORITY 3: Placeholder
    else {
      imageWidget = _buildPlaceholder();
    }

    // Wrap with ClipRRect if borderRadius provided
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// ============================================================
  /// 🔹 Build Base64 Image
  /// ============================================================
  Widget _buildBase64Image() {
    try {
      // Remove data:image prefix if exists
      String base64String = imageBase64!;

      // Handle different base64 formats
      if (base64String.contains('base64,')) {
        base64String = base64String.split('base64,').last;
      } else if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      // Remove whitespace
      base64String = base64String.replaceAll(RegExp(r'\s+'), '');

      // Decode base64
      final bytes = base64Decode(base64String);

      print('✅ Successfully decoded base64 image (${bytes.length} bytes)');

      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error rendering base64 image: $error');
          return _buildPlaceholder(error: 'Error rendering image');
        },
      );
    } catch (e, stackTrace) {
      print('❌ Error decoding base64: $e');
      print('📋 Stack trace: $stackTrace');
      return _buildPlaceholder(error: 'Invalid image format');
    }
  }

  /// ============================================================
  /// 🔹 Build Network Image
  /// ============================================================
  Widget _buildNetworkImage() {
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingPlaceholder(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Error loading network image: $error');
        return _buildPlaceholder(error: 'Failed to load image');
      },
    );
  }

  /// ============================================================
  /// 🔹 Build Placeholder
  /// ============================================================
  Widget _buildPlaceholder({String? error}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error != null ? Icons.broken_image : Icons.image_outlined,
            size: width != null && width! < 100 ? 24 : 48,
            color: Colors.grey[400],
          ),
          if (width == null || width! > 100) ...[
            const SizedBox(height: 8),
            Text(
              error ?? 'No Image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// ============================================================
  /// 🔹 Build Loading Placeholder
  /// ============================================================
  Widget _buildLoadingPlaceholder(ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
          strokeWidth: 2,
        ),
      ),
    );
  }
}