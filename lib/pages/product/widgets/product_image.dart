import 'dart:convert';
import 'package:flutter/material.dart';




class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder; 
  final bool showDebugInfo; 

  const ProductImage({
    super.key,
    this.imageUrl,
    this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.showDebugInfo = false,
  });

  bool _isBase64(String str) {
    if (str.isEmpty) return false;

    if (str.startsWith('data:image/')) {
      debugPrint('🟢 Detected as BASE64 (has data:image prefix)');
      return true;
    }

    try {
      if (str.length < 100) return false;
      base64Decode(str.contains(',') ? str.split(',')[1] : str);
      debugPrint('🟢 Detected as BASE64 (decoded successfully)');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imgSource = imageUrl ?? image;
    
    if (imgSource == null || imgSource.isEmpty) {
      debugPrint('⚠️ ProductImage: No image source provided');
      return _buildPlaceholder('No Image');
    }

    final img = imgSource.trim();
    debugPrint('🖼️ ProductImage input: ${img.substring(0, img.length > 50 ? 50 : img.length)}...');

    Widget imageWidget;

    if (_isBase64(img)) {
      imageWidget = _buildBase64Image(img);
    } else if (img.startsWith('http')) {
      imageWidget = _buildNetworkImage(img);
    } else if (img.startsWith('assets/')) {
      imageWidget = _buildAssetImage(img);
    } else {
      debugPrint('⚪ Unknown image type: $img');
      return _buildPlaceholder('Invalid Format');
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: imageWidget,
    );
  }

  Widget _buildBase64Image(String img) {
    try {
      final base64Data = img.split(',').last;
      final bytes = base64Decode(base64Data);
      debugPrint('✅ Rendering BASE64 image (${bytes.length} bytes)');
      
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error rendering base64: $error');
          return _buildPlaceholder('Load Error');
        },
      );
    } catch (e) {
      debugPrint('❌ Base64 decode failed: $e');
      return _buildPlaceholder('Decode Error');
    }
  }

  Widget _buildNetworkImage(String url) {
    debugPrint('🌐 Rendering network image: $url');
    
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
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
              color: Colors.grey[400],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Network image error: $error');
        return _buildPlaceholder('Network Error');
      },
    );
  }

  Widget _buildAssetImage(String path) {
    debugPrint('📦 Rendering asset image: $path');
    
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Asset not found: $path');
        return _buildPlaceholder('Asset Not Found');
      },
    );
  }

  Widget _buildPlaceholder(String? message) {
    if (placeholder != null) return placeholder!;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[600],
            size: 40,
          ),
          if (showDebugInfo && message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}