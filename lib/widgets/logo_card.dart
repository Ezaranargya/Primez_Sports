import 'package:flutter/material.dart';

Widget logoCard(String imagePath, String brandsName, Function(String) onTap) {
  return GestureDetector(
    onTap: () => onTap(brandsName),
    child: Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: imagePath.startsWith("http")
            ? Image.network(
                imagePath,
                fit: BoxFit.contain,
              )
            : Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
      ),
    ),
  );
}
