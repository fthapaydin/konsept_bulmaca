import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../models/background_models.dart';

/// Seçili arka planı (veya konsept otomatik modunu) vektörel sanat dokusuyla
/// yüksek çözünürlükte çizen tam ekran arka plan sarmalayıcısı.
class BackgroundCanvas extends StatelessWidget {
  const BackgroundCanvas({
    super.key,
    required this.background,
    required this.child,
    this.conceptSurfaceColor,
    this.conceptPrimaryColor,
  });

  final AppBackground background;
  final Widget child;
  final Color? conceptSurfaceColor;
  final Color? conceptPrimaryColor;

  @override
  Widget build(BuildContext context) {
    final isConceptAuto =
        background.artwork == BackgroundArtworkType.conceptAuto;

    final colors = isConceptAuto && conceptSurfaceColor != null
        ? [
            conceptSurfaceColor!,
            Color.alphaBlend(
              (conceptPrimaryColor ?? background.accentColor)
                  .withValues(alpha: 0.08),
              conceptSurfaceColor!,
            ),
          ]
        : background.gradientColors;

    final accent = isConceptAuto && conceptPrimaryColor != null
        ? conceptPrimaryColor!
        : background.accentColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _BackgroundArtworkPainter(
                artwork: background.artwork,
                accentColor: accent,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackgroundArtworkPainter extends CustomPainter {
  const _BackgroundArtworkPainter({
    required this.artwork,
    required this.accentColor,
  });

  final BackgroundArtworkType artwork;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (artwork) {
      case BackgroundArtworkType.conceptAuto:
        _paintConceptAuto(canvas, size);
      case BackgroundArtworkType.newspaperCream:
        _paintNewspaper(canvas, size);
      case BackgroundArtworkType.midnightStars:
        _paintMidnightStars(canvas, size);
      case BackgroundArtworkType.yesilcamCinema:
        _paintYesilcam(canvas, size);
      case BackgroundArtworkType.iznikTiles:
        _paintIznikTiles(canvas, size);
      case BackgroundArtworkType.aegeanCoast:
        _paintAegeanCoast(canvas, size);
      case BackgroundArtworkType.cappadociaDawn:
        _paintCappadocia(canvas, size);
      case BackgroundArtworkType.autumnForest:
        _paintAutumnForest(canvas, size);
      case BackgroundArtworkType.auroraNight:
        _paintAurora(canvas, size);
      case BackgroundArtworkType.goldenGalaxy:
        _paintGoldenGalaxy(canvas, size);
    }
  }

  void _paintConceptAuto(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.12), size.width * 0.36, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.12), size.width * 0.24, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.06, size.height * 0.85), size.width * 0.30, ringPaint);
  }

  void _paintNewspaper(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF78716C).withValues(alpha: 0.07)
      ..strokeWidth = 1.0;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Subtle decorative corner squares like classic crossword margins
    final squarePaint = Paint()
      ..color = const Color(0xFF92400E).withValues(alpha: 0.055);
    for (var i = 0; i < 4; i++) {
      final offset = i * step;
      canvas.drawRect(
        Rect.fromLTWH(size.width - step * 2 - offset, offset, step - 2, step - 2),
        squarePaint,
      );
    }
  }

  void _paintMidnightStars(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white;
    const starCoords = [
      (0.12, 0.08, 1.8, 0.75),
      (0.28, 0.15, 1.2, 0.55),
      (0.45, 0.06, 2.2, 0.85),
      (0.66, 0.12, 1.4, 0.60),
      (0.84, 0.09, 2.0, 0.80),
      (0.91, 0.24, 1.3, 0.50),
      (0.08, 0.31, 1.5, 0.65),
      (0.22, 0.42, 1.1, 0.45),
      (0.75, 0.34, 1.8, 0.70),
      (0.88, 0.48, 1.5, 0.60),
      (0.14, 0.64, 2.0, 0.75),
      (0.36, 0.72, 1.2, 0.50),
      (0.62, 0.68, 1.6, 0.65),
      (0.82, 0.78, 2.1, 0.80),
      (0.24, 0.88, 1.5, 0.55),
      (0.54, 0.91, 1.3, 0.50),
      (0.93, 0.90, 1.7, 0.65),
    ];
    for (final s in starCoords) {
      starPaint.color = Colors.white.withValues(alpha: s.$4);
      canvas.drawCircle(Offset(size.width * s.$1, size.height * s.$2), s.$3, starPaint);
    }

    // Soft moonlight halo top-right
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF93C5FD).withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.84, size.height * 0.14),
          radius: size.width * 0.38,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.14),
      size.width * 0.38,
      glowPaint,
    );
  }

  void _paintYesilcam(Canvas canvas, Size size) {
    // Soft cinema projector light cone from top center
    final beamPath = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(size.width * 0.98, size.height * 0.78)
      ..lineTo(size.width * 0.02, size.height * 0.78)
      ..close();
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFDE68A).withValues(alpha: 0.18),
          const Color(0xFFF59E0B).withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.8));
    canvas.drawPath(beamPath, beamPaint);

    // Subtle classic 35mm film-strip sprockets on left & right edges
    final stripPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.10);
    const holeH = 12.0;
    const holeW = 8.0;
    const step = 28.0;
    for (double y = 12; y < size.height; y += step) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(6, y, holeW, holeH),
          const Radius.circular(2.5),
        ),
        stripPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width - holeW - 6, y, holeW, holeH),
          const Radius.circular(2.5),
        ),
        stripPaint,
      );
    }
  }

  void _paintIznikTiles(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF1D4ED8).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fill = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.06);

    const tile = 54.0;
    for (double y = 0; y < size.height + tile; y += tile) {
      for (double x = 0; x < size.width + tile; x += tile) {
        final cx = x + tile / 2;
        final cy = y + tile / 2;
        final diamond = Path()
          ..moveTo(cx, cy - tile * 0.36)
          ..lineTo(cx + tile * 0.36, cy)
          ..lineTo(cx, cy + tile * 0.36)
          ..lineTo(cx - tile * 0.36, cy)
          ..close();
        canvas.drawPath(diamond, stroke);
        canvas.drawCircle(Offset(cx, cy), 4.5, fill);
      }
    }
  }

  void _paintAutumnForest(Canvas canvas, Size size) {
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDBA74).withValues(alpha: 0.28),
          const Color(0xFFEA580C).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.75, size.height * 0.16),
          radius: size.width * 0.48,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.16),
      size.width * 0.48,
      sunGlow,
    );

    // Floating warm autumn leaf silhouettes
    const leaves = [
      (0.14, 0.16, 12.0, 0.4),
      (0.32, 0.28, 9.0, -0.6),
      (0.84, 0.34, 14.0, 0.9),
      (0.18, 0.56, 11.0, -0.3),
      (0.76, 0.64, 10.0, 0.5),
      (0.45, 0.80, 13.0, -0.8),
      (0.88, 0.84, 9.5, 0.2),
    ];
    final leafPaint = Paint()..color = const Color(0xFFFDBA74).withValues(alpha: 0.18);
    for (final l in leaves) {
      canvas.save();
      canvas.translate(size.width * l.$1, size.height * l.$2);
      canvas.rotate(l.$4);
      final p = Path()
        ..moveTo(0, -l.$3)
        ..quadraticBezierTo(l.$3 * 0.9, 0, 0, l.$3)
        ..quadraticBezierTo(-l.$3 * 0.9, 0, 0, -l.$3)
        ..close();
      canvas.drawPath(p, leafPaint);
      canvas.restore();
    }
  }

  void _paintAegeanCoast(Canvas canvas, Size size) {
    // Warm Mediterranean sun glow top-right
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFEF08A).withValues(alpha: 0.55),
          const Color(0xFFFDE047).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.12),
          radius: size.width * 0.42,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.12),
      size.width * 0.42,
      sunPaint,
    );

    // Layered smooth turquoise waves near bottom
    void drawWave(double baseY, double amp, double phase, Color color) {
      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, baseY);
      for (double x = 0; x <= size.width; x += 8) {
        final y = baseY + math.sin((x / size.width) * math.pi * 2.2 + phase) * amp;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    drawWave(size.height * 0.74, 14, 0.2, const Color(0xFF06B6D4).withValues(alpha: 0.18));
    drawWave(size.height * 0.82, 16, 1.7, const Color(0xFF0891B2).withValues(alpha: 0.22));
    drawWave(size.height * 0.90, 12, 3.1, const Color(0xFF0E7490).withValues(alpha: 0.22));
  }

  void _paintCappadocia(Canvas canvas, Size size) {
    // Rising sun
    final sunCenter = Offset(size.width * 0.50, size.height * 0.26);
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.55),
          const Color(0xFFFDE68A).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: sunCenter, radius: size.width * 0.48),
      );
    canvas.drawCircle(sunCenter, size.width * 0.48, sunGlow);

    // Silhouette hot-air balloons
    void drawBalloon(Offset center, double r, Color color) {
      final p = Paint()..color = color;
      canvas.drawCircle(center, r, p);
      final cone = Path()
        ..moveTo(center.dx - r * 0.65, center.dy + r * 0.55)
        ..lineTo(center.dx + r * 0.65, center.dy + r * 0.55)
        ..lineTo(center.dx + r * 0.26, center.dy + r * 1.25)
        ..lineTo(center.dx - r * 0.26, center.dy + r * 1.25)
        ..close();
      canvas.drawPath(cone, p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + r * 1.55),
            width: r * 0.48,
            height: r * 0.34,
          ),
          const Radius.circular(2),
        ),
        p,
      );
    }

    drawBalloon(
      Offset(size.width * 0.20, size.height * 0.22),
      16,
      const Color(0xFF9A3412).withValues(alpha: 0.22),
    );
    drawBalloon(
      Offset(size.width * 0.78, size.height * 0.18),
      20,
      const Color(0xFF9A3412).withValues(alpha: 0.18),
    );
    drawBalloon(
      Offset(size.width * 0.62, size.height * 0.31),
      11,
      const Color(0xFF9A3412).withValues(alpha: 0.15),
    );

    // Rolling canyon hills at bottom
    final hill1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.72,
        size.width * 0.55,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.90,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      hill1,
      Paint()..color = const Color(0xFF9A3412).withValues(alpha: 0.18),
    );

    final hill2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.82,
        size.width * 0.72,
        size.height * 0.90,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.94,
        size.width,
        size.height * 0.86,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      hill2,
      Paint()..color = const Color(0xFF7C2D12).withValues(alpha: 0.24),
    );
  }

  void _paintAurora(Canvas canvas, Size size) {
    // Flowing translucent aurora curtains
    void drawRibbon(double yRatio, double curve, Color c1, Color c2) {
      final path = Path()
        ..moveTo(-20, size.height * yRatio)
        ..cubicTo(
          size.width * 0.28,
          size.height * (yRatio - curve),
          size.width * 0.68,
          size.height * (yRatio + curve),
          size.width + 20,
          size.height * (yRatio - curve * 0.4),
        )
        ..lineTo(size.width + 20, size.height * (yRatio + 0.18))
        ..cubicTo(
          size.width * 0.68,
          size.height * (yRatio + curve + 0.16),
          size.width * 0.28,
          size.height * (yRatio - curve + 0.16),
          -20,
          size.height * (yRatio + 0.16),
        )
        ..close();

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [c1, c2, Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(path, paint);
    }

    drawRibbon(
      0.16,
      0.09,
      const Color(0xFF34D399).withValues(alpha: 0.28),
      const Color(0xFF22D3EE).withValues(alpha: 0.14),
    );
    drawRibbon(
      0.34,
      -0.08,
      const Color(0xFFA78BFA).withValues(alpha: 0.24),
      const Color(0xFF34D399).withValues(alpha: 0.12),
    );

    // Crisp arctic stars
    _paintMidnightStars(canvas, size);
  }

  void _paintGoldenGalaxy(Canvas canvas, Size size) {
    final nodes = [
      Offset(size.width * 0.14, size.height * 0.14),
      Offset(size.width * 0.34, size.height * 0.10),
      Offset(size.width * 0.52, size.height * 0.18),
      Offset(size.width * 0.78, size.height * 0.12),
      Offset(size.width * 0.88, size.height * 0.28),
      Offset(size.width * 0.18, size.height * 0.78),
      Offset(size.width * 0.44, size.height * 0.84),
      Offset(size.width * 0.72, size.height * 0.76),
      Offset(size.width * 0.86, size.height * 0.88),
    ];

    final linePaint = Paint()
      ..color = const Color(0xFFFCD34D).withValues(alpha: 0.18)
      ..strokeWidth = 1.1;

    final edges = [
      (0, 1), (1, 2), (2, 3), (3, 4),
      (5, 6), (6, 7), (7, 8),
    ];
    for (final (a, b) in edges) {
      canvas.drawLine(nodes[a], nodes[b], linePaint);
    }

    final dotPaint = Paint()..color = const Color(0xFFFDE68A).withValues(alpha: 0.82);
    final haloPaint = Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.22);
    for (final p in nodes) {
      canvas.drawCircle(p, 6.5, haloPaint);
      canvas.drawCircle(p, 2.3, dotPaint);
    }

    // Subtle cosmic golden glow
    final nebula = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.48),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.48), size.width * 0.55, nebula);
  }

  @override
  bool shouldRepaint(covariant _BackgroundArtworkPainter oldDelegate) =>
      oldDelegate.artwork != artwork || oldDelegate.accentColor != accentColor;
}
