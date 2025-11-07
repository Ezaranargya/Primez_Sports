import 'package:flutter/material.dart';

class PurchaseOptionsButton extends StatelessWidget {
  final bool showOptions;
  final VoidCallback onTap;

  const PurchaseOptionsButton({
    super.key,
    required this.showOptions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE53E3E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Opsi pembelian\nbisa lewat link di Sini",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
            ),
            Icon(
              showOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}