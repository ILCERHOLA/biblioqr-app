import 'package:flutter/material.dart';

class LibroPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double iconSize;

  const LibroPlaceholder({
    super.key,
    this.width = 52,
    this.height = 68,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        color: const Color(0xFF1565C0),
        size: iconSize,
      ),
    );
  }
}
