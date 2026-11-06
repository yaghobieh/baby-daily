import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Quick action circular button with label below, matching Screenshot 1:
/// Pastel circles (#F28B72 Feed, #C5B4E3 Sleep, #B6E2D3 Diaper, #B9D9EB Meds)
/// with dark-outlined custom icons inside.
class QuickActionButton extends StatelessWidget {
  final String type;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.type,
    required this.label,
    required this.onTap,
  });

  Color _circleColor(bool dark) {
    switch (type) {
      case 'FEED':
        return const Color(0xFFF28B72); // warm coral
      case 'SLEEP':
        return const Color(0xFFC5B4E3); // soft lavender
      case 'DIAPER':
        return const Color(0xFFB6E2D3); // pastel mint
      case 'MEDICINE':
        return const Color(0xFFB9D9EB); // pastel sky blue
      case 'GROWTH':
        return const Color(0xFFFDE68A); // pastel amber
      case 'NOTE':
        return const Color(0xFFA7F3D0); // pastel teal
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final color = _circleColor(dark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(42),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(36, 36),
                painter: _QuickIconPainter(type: type),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : const Color(0xFF2B2523),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickIconPainter extends CustomPainter {
  final String type;

  _QuickIconPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF2B2523)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case 'FEED':
        // Baby bottle with cream body & nipple
        final bodyFill = Paint()
          ..color = const Color(0xFFFAF3EB)
          ..style = PaintingStyle.fill;
        final bodyRect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, 14, 16, 18),
          const Radius.circular(3.5),
        );
        canvas.drawRRect(bodyRect, bodyFill);
        canvas.drawRRect(bodyRect, stroke);

        // Collar ring
        final collarRect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(11.5, 10.5, 13, 3.5),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(collarRect, bodyFill);
        canvas.drawRRect(collarRect, stroke);

        // Nipple top
        final nipplePath = Path()
          ..moveTo(14.5, 10.5)
          ..lineTo(14.5, 7.5)
          ..quadraticBezierTo(18, 3.5, 21.5, 7.5)
          ..lineTo(21.5, 10.5);
        canvas.drawPath(nipplePath, bodyFill);
        canvas.drawPath(nipplePath, stroke);

        // Measurement ticks
        canvas.drawLine(const Offset(13, 19), const Offset(17, 19), stroke);
        canvas.drawLine(const Offset(13, 23), const Offset(16, 23), stroke);
        canvas.drawLine(const Offset(13, 27), const Offset(17, 27), stroke);
        break;

      case 'SLEEP':
        // Crescent moon + 2 small stars
        final moonFill = Paint()
          ..color = const Color(0xFFA390D4)
          ..style = PaintingStyle.fill;
        final path = Path()
          ..addArc(const Rect.fromLTWH(6, 6, 22, 22), 0.35 * math.pi, 1.35 * math.pi)
          ..arcToPoint(
            const Offset(20, 26),
            radius: const Radius.circular(9),
            clockwise: false,
          )
          ..close();
        canvas.drawPath(path, moonFill);
        canvas.drawPath(path, stroke);

        // Little stars on top-right
        _drawSparkle(canvas, const Offset(25, 11), 3.2, stroke);
        _drawSparkle(canvas, const Offset(28, 17), 2.2, stroke);
        break;

      case 'DIAPER':
        // Diaper shape with side tabs
        final diaperFill = Paint()
          ..color = const Color(0xFFF4FBF7)
          ..style = PaintingStyle.fill;
        final dPath = Path()
          ..moveTo(7, 11)
          ..lineTo(29, 11)
          ..lineTo(29, 17)
          ..quadraticBezierTo(23, 18, 22, 25)
          ..lineTo(14, 25)
          ..quadraticBezierTo(13, 18, 7, 17)
          ..close();
        canvas.drawPath(dPath, diaperFill);
        canvas.drawPath(dPath, stroke);
        // Waistband line
        canvas.drawLine(const Offset(7, 14.5), const Offset(29, 14.5), stroke);
        // Left & right fastener tabs
        canvas.drawLine(const Offset(7, 16.5), const Offset(12, 16.5), stroke);
        canvas.drawLine(const Offset(24, 16.5), const Offset(29, 16.5), stroke);
        break;

      default:
        // Two-tone capsule pill tilted at -45 deg
        canvas.save();
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate(-math.pi / 4);
        final leftHalf = RRect.fromRectAndCorners(
          const Rect.fromLTWH(-12, -5.5, 12, 11),
          topLeft: const Radius.circular(6),
          bottomLeft: const Radius.circular(6),
        );
        final rightHalf = RRect.fromRectAndCorners(
          const Rect.fromLTWH(0, -5.5, 12, 11),
          topRight: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        );
        canvas.drawRRect(
          leftHalf,
          Paint()
            ..color = const Color(0xFFFAF3EB)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(
          rightHalf,
          Paint()
            ..color = const Color(0xFF9AC2DC)
            ..style = PaintingStyle.fill,
        );
        final fullPill = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -5.5, 24, 11),
          const Radius.circular(6),
        );
        canvas.drawRRect(fullPill, stroke);
        canvas.drawLine(const Offset(0, -5.5), const Offset(0, 5.5), stroke);
        canvas.restore();
        break;
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
  }

  @override
  bool shouldRepaint(covariant _QuickIconPainter oldDelegate) => oldDelegate.type != type;
}
