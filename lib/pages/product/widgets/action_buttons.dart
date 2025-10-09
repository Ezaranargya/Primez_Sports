import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isFavorite;
  final bool isLoadingFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onShareTap;

  const ActionButtons({
    super.key,
    required this.isFavorite,
    required this.isLoadingFavorite,
    required this.onFavoriteTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          onTap: isLoadingFavorite ? null : onFavoriteTap,
          child: isLoadingFavorite
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              : Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.black,
                  size: 24,
                ),
        ),
        const SizedBox(width: 16),
        _CircleButton(
          onTap: onShareTap,
          child: const Icon(Icons.share, color: Colors.black, size: 24),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _CircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }
}