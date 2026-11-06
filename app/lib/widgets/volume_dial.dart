import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular Volume Dial matching Screenshot 2:
/// - Bold "180 ml" readout above the dial
/// - Scale markers around the outer ring: 0, 60, 120, 180, 240ml
/// - Thick coral active arc with white tick marks and an inward pointer arrow
/// - Inner cream circle with "Volume (ml)", "180 ml", and circular [-] [+] buttons.
class VolumeDial extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const VolumeDial({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 240,
    required this.onChanged,
  });

  void _step(int delta) {
    final next = (value + delta).clamp(min, max);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value ml',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1F1A17),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onPanUpdate: (details) => _handleTouch(context, details.localPosition),
          onTapDown: (details) => _handleTouch(context, details.localPosition),
          child: SizedBox(
            width: 240,
            height: 215,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(240, 215),
                  painter: _ScreenshotDialPainter(
                    value: value,
                    min: min,
                    max: max,
                    isDark: isDark,
                  ),
                ),
                // Inner cream circle with Volume (ml), value, and [-] [+]
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282238) : const Color(0xFFFAF5EA),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Volume (ml)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF2B2523),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$value ml',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1F1A17),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DialCircleBtn(
                            label: '−',
                            bgColor: const Color(0xFFFADBD4),
                            textColor: const Color(0xFF8C4A3B),
                            onTap: () => _step(-10),
                          ),
                          const SizedBox(width: 10),
                          _DialCircleBtn(
                            label: '+',
                            bgColor: const Color(0xFFF5AD9C),
                            textColor: const Color(0xFF59251A),
                            onTap: () => _step(10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleTouch(BuildContext context, Offset localPos) {
    final center = const Offset(120, 108);
    final offset = localPos - center;
    if (offset.distance < 48) return; // Let inner +/- buttons receive taps
    double angle = math.atan2(offset.dy, offset.dx);
    if (angle < 0) angle += 2 * math.pi;
    const startAngle = 0.75 * math.pi; // 135 deg (bottom-left)
    const sweep = 1.5 * math.pi; // 270 deg sweep
    double progress = angle - startAngle;
    if (progress < 0) progress += 2 * math.pi;
    if (progress <= sweep) {
      final ratio = (progress / sweep).clamp(0.0, 1.0);
      final raw = min + ratio * (max - min);
      final snapped = ((raw / 5).round() * 5).clamp(min, max);
      onChanged(snapped);
    }
  }
}

class _DialCircleBtn extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _DialCircleBtn({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _ScreenshotDialPainter extends CustomPainter {
  final int value;
  final int min;
  final int max;
  final bool isDark;

  _ScreenshotDialPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const ringRadius = 71.0;
    const strokeWidth = 22.0;
    const startAngle = 0.75 * math.pi; // 135 deg (bottom-left: 0)
    const totalSweep = 1.5 * math.pi; // 270 deg (bottom-right: 240ml)

    // Soft pink full circular background ring
    final bgRingPaint = Paint()
      ..color = isDark ? const Color(0xFF3A2E4C) : const Color(0xFFFCD9D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, ringRadius, bgRingPaint);

    // Active coral arc from startAngle up to current value
    final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final activeSweep = totalSweep * ratio;
    if (activeSweep > 0.01) {
      final activePaint = Paint()
        ..color = const Color(0xFFF6937E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }

    // White tick marks along the ring
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const tickSteps = 8;
    for (int i = 0; i <= tickSteps; i++) {
      final a = startAngle + (totalSweep * i / tickSteps);
      final innerR = ringRadius - strokeWidth / 2 + 3;
      final outerR = ringRadius - strokeWidth / 2 + 10;
      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(a), center.dy + innerR * math.sin(a)),
        Offset(center.dx + outerR * math.cos(a), center.dy + outerR * math.sin(a)),
        tickPaint,
      );
    }

    // Pointer triangle on the inner edge of the active arc (matching Screenshot 2)
    final pointerAngle = startAngle + activeSweep;
    final tipR = ringRadius - strokeWidth / 2 - 4;
    final baseR = ringRadius + 1;
    final halfSpread = 0.09;
    final pointerPath = Path()
      ..moveTo(
        center.dx + tipR * math.cos(pointerAngle),
        center.dy + tipR * math.sin(pointerAngle),
      )
      ..lineTo(
        center.dx + baseR * math.cos(pointerAngle - halfSpread),
        center.dy + baseR * math.sin(pointerAngle - halfSpread),
      )
      ..lineTo(
        center.dx + baseR * math.cos(pointerAngle + halfSpread),
        center.dy + baseR * math.sin(pointerAngle + halfSpread),
      )
      ..close();
    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = const Color(0xFFCF5840)
        ..style = PaintingStyle.fill,
    );

    // Outer scale labels: 0, 60, 120, 180, 240ml
    final labels = <MapEntry<double, String>>[
      const MapEntry(0.0, '0'),
      const MapEntry(0.25, '60'),
      const MapEntry(0.50, '120'),
      const MapEntry(0.75, '180'),
      const MapEntry(1.0, '240ml'),
    ];

    for (final item in labels) {
      final a = startAngle + totalSweep * item.key;
      final labelRadius = ringRadius + strokeWidth / 2 + 16;
      final pos = Offset(
        center.dx + labelRadius * math.cos(a),
        center.dy + labelRadius * math.sin(a),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: item.value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF2B2523),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ScreenshotDialPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.isDark != isDark;
  }
}
