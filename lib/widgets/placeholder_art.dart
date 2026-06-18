import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// High-contrast procedural placeholder for shows, artists, and profiles
/// that are missing a network image. Draws a stylized performer silhouette
/// with diagonal hatch patterns in strict black-and-white.
class PlaceholderArt extends StatelessWidget {
  final String? label;
  final double size;

  const PlaceholderArt({
    super.key,
    this.label,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlaceholderPainter(label: label ?? ''),
      ),
    );
  }
}

class _PlaceholderPainter extends CustomPainter {
  final String label;

  _PlaceholderPainter({this.label = ''});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // -- Base fill --
    final bgPaint = Paint()..color = AppColors.surfaceAlt;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // -- Diagonal hatch pattern --
    final hatchPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = -h; i < w + h; i += 7) {
      canvas.drawLine(Offset(i, 0), Offset(i - h, h), hatchPaint);
    }

    // -- Dark border frame --
    final framePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), framePaint);

    // -- Stylised performer silhouette --
    final cx = w / 2;
    final cy = h / 2;
    final scale = math.min(w, h) / 80;
    final silhouettePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Head (circle)
    path.addOval(Rect.fromCircle(
      center: Offset(cx, cy - 14 * scale),
      radius: 10 * scale,
    ));

    // Body (trapezoid torso)
    path.moveTo(cx - 16 * scale, cy - 4 * scale);
    path.lineTo(cx + 16 * scale, cy - 4 * scale);
    path.lineTo(cx + 22 * scale, cy + 24 * scale);
    path.lineTo(cx - 22 * scale, cy + 24 * scale);
    path.close();

    // Left arm (raised)
    path.moveTo(cx - 16 * scale, cy - 2 * scale);
    path.lineTo(cx - 28 * scale, cy - 18 * scale);
    path.lineTo(cx - 26 * scale, cy - 20 * scale);
    path.lineTo(cx - 14 * scale, cy - 4 * scale);
    path.close();

    // Right arm (raised)
    path.moveTo(cx + 16 * scale, cy - 2 * scale);
    path.lineTo(cx + 28 * scale, cy - 18 * scale);
    path.lineTo(cx + 26 * scale, cy - 20 * scale);
    path.lineTo(cx + 14 * scale, cy - 4 * scale);
    path.close();

    // Microphone stand (vertical line)
    final micPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    canvas.drawLine(
      Offset(cx + 28 * scale, cy - 18 * scale),
      Offset(cx + 30 * scale, cy + 28 * scale),
      micPaint,
    );

    // Microphone head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 30 * scale, cy - 20 * scale),
        width: 5 * scale,
        height: 7 * scale,
      ),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    canvas.drawPath(path, silhouettePaint);

    // -- Initial letter (if provided) --
    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label[0].toUpperCase(),
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.13),
            fontSize: w * 0.45,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (w - textPainter.width) / 2,
          (h - textPainter.height) / 2 + 4 * scale,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helpful builder used everywhere a network image might be missing.
Widget buildShowThumbnail({double size = 44, String? label, String? imageUrl}) {
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider, width: 1),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
    );
  }
  return PlaceholderArt(label: label, size: size);
}
