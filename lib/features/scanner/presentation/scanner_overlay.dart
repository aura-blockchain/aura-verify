import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Custom scanner overlay with Aura branding
class ScannerOverlay extends StatelessWidget {
  final double scanAreaSize;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color overlayColor;

  const ScannerOverlay({
    Key? key,
    this.scanAreaSize = 280.0,
    this.borderRadius = 16.0,
    this.borderWidth = 3.0,
    this.borderColor = AuraTheme.secondaryTeal,
    this.overlayColor = Colors.black54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    // Adjust scan area for landscape
    final effectiveScanAreaSize = isPortrait ? scanAreaSize : scanAreaSize * 0.7;

    return Stack(
      children: [
        // Dark overlay with cutout
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            overlayColor,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: effectiveScanAreaSize,
                  height: effectiveScanAreaSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Animated scanning line
        Center(
          child: SizedBox(
            width: effectiveScanAreaSize,
            height: effectiveScanAreaSize,
            child: const _ScanningLine(),
          ),
        ),

        // Corner brackets
        Center(
          child: SizedBox(
            width: effectiveScanAreaSize,
            height: effectiveScanAreaSize,
            child: CustomPaint(
              painter: _CornerBracketsPainter(
                borderColor: borderColor,
                borderWidth: borderWidth,
                borderRadius: borderRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated scanning line
class _ScanningLine extends StatefulWidget {
  const _ScanningLine({Key? key}) : super(key: key);

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, _animation.value * 2 - 1),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AuraTheme.secondaryTeal.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AuraTheme.secondaryTeal.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for corner brackets
class _CornerBracketsPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double bracketLength = 40.0;

  _CornerBracketsPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(borderRadius, 0)
        ..lineTo(bracketLength, 0)
        ..moveTo(0, borderRadius)
        ..lineTo(0, bracketLength),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - borderRadius, 0)
        ..lineTo(size.width - bracketLength, 0)
        ..moveTo(size.width, borderRadius)
        ..lineTo(size.width, bracketLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(borderRadius, size.height)
        ..lineTo(bracketLength, size.height)
        ..moveTo(0, size.height - borderRadius)
        ..lineTo(0, size.height - bracketLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - borderRadius, size.height)
        ..lineTo(size.width - bracketLength, size.height)
        ..moveTo(size.width, size.height - borderRadius)
        ..lineTo(size.width, size.height - bracketLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
