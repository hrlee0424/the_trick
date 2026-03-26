import 'package:flutter/material.dart';

class CupWidget extends StatelessWidget {
  final double size;
  final bool isOpened;
  final bool hasBall;
  final bool isSelected;

  const CupWidget({
    super.key,
    required this.size,
    required this.isOpened,
    required this.hasBall,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.local_cafe,
          size: size,
          color: isSelected ? Colors.brown[300] : Colors.brown[700],
        ),
        const SizedBox(height: 10),
        // 컵이 열렸거나 준비 중일 때 공 표시
        if (hasBall && isOpened)
          const Icon(Icons.circle, color: Colors.red, size: 24)
        else
          const SizedBox(height: 24), // 공간 유지용
      ],
    );
  }
}