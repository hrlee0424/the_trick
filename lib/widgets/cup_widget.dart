import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────
// CupWidget — UFO 이미지 + 외계인 이미지
//   isOpened  : true  → UFO 들어올려져 외계인 보임
//             : false → UFO 내려와 외계인 숨김
//   isSelected: 정답(green) / 오답(red) 색상 오버레이
//   isBallGlowing: 공 공개 직전 glow 펄스
// ─────────────────────────────────────────────────────
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
    ]).animate(CurvedAnimation(
        parent: _glowController, curve: Curves.easeInOut));
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
    final double sz = widget.size;

    // 정답/오답 선택 시 UFO에 색상 오버레이
    Color? overlayColor;
    if (widget.isSelected) {
      overlayColor = widget.hasBall
          ? const Color(0xFF4DFF9E).withOpacity(0.45)
          : const Color(0xFFFF4D6D).withOpacity(0.45);
    }

    return SizedBox(
      width: sz * 1.3,
      height: sz * 2.2,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // ── 외계인 (UFO 아래, isOpened 일 때만 보임) ──
          if (widget.hasBall)
            Positioned(
              bottom: 0,
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (context, _) {
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: widget.isOpened ? 1.0 : 0.0,
                    child: Transform.translate(
                      offset: Offset(0, -_glowAnim.value * 6),
                      child: SizedBox(
                        width: sz * 0.65,
                        height: sz * 0.65,
                        child: Image.asset(
                          'assets/alien.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Positioned(
              bottom: 0,
              child: SizedBox(width: sz * 0.65, height: sz * 0.65),
            ),

          // ── UFO 이미지 ──
          Positioned(
            top: 0,
            child: ColorFiltered(
              colorFilter: overlayColor != null
                  ? ColorFilter.mode(overlayColor, BlendMode.srcATop)
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.asset(
                'assets/ufo.png',
                width: sz * 1.3,
                height: sz * 1.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}