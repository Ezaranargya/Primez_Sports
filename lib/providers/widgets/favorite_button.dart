import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/models/product_model.dart';

class FavoriteButton extends StatelessWidget {
  final Product product;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteButton({
    Key? key,
    required this.product,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFavorite = favoriteProvider.isFavorite(product.id);
        
        print('🎨 [BUTTON] Product ${product.id} - isFavorite: $isFavorite');

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite 
                ? (activeColor ?? Colors.red) 
                : (inactiveColor ?? Colors.grey),
            size: size,
          ),
          onPressed: () async {
            print('👆 [BUTTON] Favorite button pressed for ${product.name}');
            
            try {
              await favoriteProvider.toggleFavorite(product);
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite 
                        ? '${product.name} removed from favorites'
                        : '${product.name} added to favorites',
                  ),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              print('❌ [BUTTON] Error toggling favorite: $e');
              
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }
}



