import 'package:flutter/material.dart';
import '../screens/game_screen.dart' show AppColors;

class CupWidget extends StatefulWidget {
  final double size;
  final bool isOpened;
  final bool hasBall;
  final bool isSelected;
  final bool isBallGlowing;

  const CupWidget({
    super.key,
    required this.size,
    required this.isOpened,
    required this.hasBall,
    this.isSelected = false,
    this.isBallGlowing = false,
  });

  @override
  State<CupWidget> createState() => _CupWidgetState();
}

class _CupWidgetState extends State<CupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(CupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBallGlowing && !oldWidget.isBallGlowing) {
      _glowController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 선택 결과에 따른 컵 색상
    Color cupColor;
    if (widget.isSelected) {
      cupColor = widget.hasBall ? AppColors.green : AppColors.red;
    } else {
      cupColor = AppColors.amber;
    }

    return Column(
      children: [
        Icon(
          Icons.local_cafe,
          size: widget.size,
          color: cupColor.withOpacity(widget.isOpened ? 0.9 : 1.0),
          shadows: [
            Shadow(
              color: cupColor.withOpacity(0.35),
              blurRadius: 12,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.hasBall && widget.isOpened)
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, -_glowAnim.value * 5),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.red.withOpacity(
                            0.4 + _glowAnim.value * 0.5),
                        blurRadius: 6 + _glowAnim.value * 16,
                        spreadRadius: _glowAnim.value * 6,
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          const SizedBox(height: 22),
      ],
    );
  }
}