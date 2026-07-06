import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;

  const GlassPanel({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    // Resolve background color: if Android (no blur), use a much higher opacity
    // to maintain readability and contrast against background elements.
    final resolvedColor = isAndroid
        ? (color != null
            ? color!.withValues(alpha: (color!.a * 1.8).clamp(0.0, 0.95))
            : const Color(0xB0201F1F))
        : (color ?? const Color(0x28201F1F));

    final panelContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(
              0x14F5F5F0), // Subtle white/beige border (rgba(245, 245, 240, 0.08))
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000), // Darker shadow
            blurRadius: 24,
            spreadRadius: -1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (isAndroid) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: panelContent,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: panelContent,
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  final Color color;

  DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double spacing = 40.0;
    for (double x = 20.0; x < size.width; x += spacing) {
      for (double y = 20.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
