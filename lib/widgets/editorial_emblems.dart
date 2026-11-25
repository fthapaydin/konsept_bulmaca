import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';

enum EmblemKind {
  yesilcam,
  ingilizce,
  turkiye,
  genelKultur,
  sprint,
  dictionary,
  megaGrid,
  daily,
}

EmblemKind emblemKindForPack(String packId) {
  switch (packId) {
    case 'yesilcam':
      return EmblemKind.yesilcam;
    case 'ingilizce':
      return EmblemKind.ingilizce;
    case 'turkiye':
      return EmblemKind.turkiye;
    case 'genel_kultur':
      return EmblemKind.genelKultur;
    default:
      return EmblemKind.daily;
  }
}

/// Standart Material ikonları yerine eKare Bulmaca için özel çizilmiş minimal
/// geometrik editoryal amblemler.
class EditorialEmblem extends StatelessWidget {
  const EditorialEmblem({
    super.key,
    required this.kind,
    this.size = 44,
    this.accentColor = AppPalette.brass,
    this.backgroundColor = AppPalette.cardMuted,
    this.borderColor = AppPalette.hairline,
    this.onDark = false,
  });

  final EmblemKind kind;
  final double size;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Center(
        child: kind == EmblemKind.ingilizce
            ? _buildBilingualMonogram()
            : CustomPaint(
                size: Size.square(size * 0.56),
                painter: _EmblemPainter(
                  kind: kind,
                  strokeColor: onDark ? Colors.white : AppPalette.ink,
                  accentColor: accentColor,
                ),
              ),
      ),
    );
  }

  Widget _buildBilingualMonogram() {
    final primary = onDark ? Colors.white : AppPalette.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'A',
          style: TextStyle(
            fontSize: size * 0.31,
            fontWeight: FontWeight.w900,
            color: primary,
            height: 1.0,
          ),
        ),
        Container(
          width: 1.2,
          height: size * 0.34,
          margin: EdgeInsets.symmetric(horizontal: size * 0.06),
          color: accentColor,
        ),
        Text(
          'Z',
          style: TextStyle(
            fontSize: size * 0.31,
            fontWeight: FontWeight.w900,
            color: accentColor,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter({
    required this.kind,
    required this.strokeColor,
    required this.accentColor,
  });

  final EmblemKind kind;
  final Color strokeColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentFill = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final accentStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);

    switch (kind) {
      case EmblemKind.yesilcam:
        // Zarif sinema film şeridi çerçevesi + vizör noktası
        final outer = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.08, h * 0.14, w * 0.84, h * 0.72),
          Radius.circular(w * 0.12),
        );
        canvas.drawRRect(outer, stroke);
        canvas.drawLine(
          Offset(w * 0.28, h * 0.14),
          Offset(w * 0.28, h * 0.86),
          stroke,
        );
        canvas.drawLine(
          Offset(w * 0.72, h * 0.14),
          Offset(w * 0.72, h * 0.86),
          stroke,
        );
        for (final yFrac in [0.34, 0.5, 0.66]) {
          canvas.drawCircle(Offset(w * 0.18, h * yFrac), w * 0.032, accentFill);
          canvas.drawCircle(Offset(w * 0.82, h * yFrac), w * 0.032, accentFill);
        }
        // Merkez oynat/sahne üçgeni
        final tri = Path()
          ..moveTo(w * 0.44, h * 0.36)
          ..lineTo(w * 0.61, h * 0.50)
          ..lineTo(w * 0.44, h * 0.64)
          ..close();
        canvas.drawPath(tri, accentFill);

      case EmblemKind.turkiye:
        // Minimal geometrik pusula & yıldız
        canvas.drawCircle(c, w * 0.40, stroke);
        final diamond = Path()
          ..moveTo(c.dx, h * 0.14)
          ..lineTo(c.dx + w * 0.10, c.dy)
          ..lineTo(c.dx, h * 0.86)
          ..lineTo(c.dx - w * 0.10, c.dy)
          ..close();
        canvas.drawPath(diamond, stroke);
        final topNeedle = Path()
          ..moveTo(c.dx, h * 0.14)
          ..lineTo(c.dx + w * 0.10, c.dy)
          ..lineTo(c.dx - w * 0.10, c.dy)
          ..close();
        canvas.drawPath(topNeedle, accentFill);
        canvas.drawCircle(c, w * 0.055, Paint()..color = AppPalette.card);

      case EmblemKind.genelKultur:
        // Minimal yörünge & atom çizgileri
        canvas.save();
        canvas.translate(c.dx, c.dy);
        for (final angle in [math.pi / 6, -math.pi / 6, math.pi / 2]) {
          canvas.save();
          canvas.rotate(angle);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: w * 0.84, height: h * 0.34),
            stroke,
          );
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, w * 0.10, accentFill);
        canvas.restore();

      case EmblemKind.sprint:
        // Zarif kronometre kadranı + 90 derece hızlı kadran yayı
        canvas.drawCircle(Offset(c.dx, c.dy + h * 0.05), w * 0.36, stroke);
        canvas.drawLine(
          Offset(c.dx - w * 0.12, h * 0.07),
          Offset(c.dx + w * 0.12, h * 0.07),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx, h * 0.07),
          Offset(c.dx, h * 0.19),
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(c.dx, c.dy + h * 0.05),
            radius: w * 0.25,
          ),
          -math.pi / 2,
          math.pi * 0.72,
          false,
          accentStroke,
        );
        canvas.drawLine(
          Offset(c.dx, c.dy + h * 0.05),
          Offset(c.dx + w * 0.16, c.dy - h * 0.07),
          accentStroke,
        );
        canvas.drawCircle(Offset(c.dx, c.dy + h * 0.05), w * 0.055, accentFill);

      case EmblemKind.dictionary:
        // Karşılıklı iki sayfalı sözlük çizimi
        final leftPage = Path()
          ..moveTo(c.dx, h * 0.22)
          ..quadraticBezierTo(w * 0.30, h * 0.14, w * 0.10, h * 0.22)
          ..lineTo(w * 0.10, h * 0.80)
          ..quadraticBezierTo(w * 0.30, h * 0.73, c.dx, h * 0.82);
        final rightPage = Path()
          ..moveTo(c.dx, h * 0.22)
          ..quadraticBezierTo(w * 0.70, h * 0.14, w * 0.90, h * 0.22)
          ..lineTo(w * 0.90, h * 0.80)
          ..quadraticBezierTo(w * 0.70, h * 0.73, c.dx, h * 0.82);
        canvas.drawPath(leftPage, stroke);
        canvas.drawPath(rightPage, stroke);
        canvas.drawLine(Offset(c.dx, h * 0.22), Offset(c.dx, h * 0.82), stroke);
        // Satırlar (sol İngilizce, sağ Türkçe vurgulu)
        for (final y in [0.40, 0.56]) {
          canvas.drawLine(
            Offset(w * 0.20, h * y),
            Offset(w * 0.40, h * y),
            stroke,
          );
          canvas.drawLine(
            Offset(w * 0.60, h * y),
            Offset(w * 0.80, h * y),
            accentStroke,
          );
        }

      case EmblemKind.megaGrid:
      case EmblemKind.daily:
      case EmblemKind.ingilizce:
        // 3×3 minimal kare bulmaca ızgarası
        final cell = w * 0.26;
        final gap = w * 0.05;
        final start = (w - (cell * 3 + gap * 2)) / 2;
        for (var r = 0; r < 3; r++) {
          for (var col = 0; col < 3; col++) {
            final rect = RRect.fromRectAndRadius(
              Rect.fromLTWH(
                start + col * (cell + gap),
                start + r * (cell + gap),
                cell,
                cell,
              ),
              Radius.circular(w * 0.05),
            );
            final isBlocked = (r == 0 && col == 2) || (r == 2 && col == 0);
            final isCenter = r == 1 && col == 1;
            if (isCenter) {
              canvas.drawRRect(rect, accentFill);
            } else if (isBlocked) {
              canvas.drawRRect(
                rect,
                Paint()..color = strokeColor.withValues(alpha: 0.28),
              );
            } else {
              canvas.drawRRect(rect, stroke);
            }
          }
        }
    }
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.accentColor != accentColor;
}

/// Koyu editoryal kartların sağ üstünde çok hafif geometrik kare bulmaca dokusu.
class CrosswordWatermarkPainter extends CustomPainter {
  const CrosswordWatermarkPainter({
    this.color = Colors.white,
    this.opacity = 0.06,
  });

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fill = Paint()
      ..color = color.withValues(alpha: opacity * 1.4)
      ..style = PaintingStyle.fill;

    const cell = 24.0;
    const gap = 4.0;
    final startX = size.width - (cell + gap) * 4 - 8;
    const startY = -6.0;

    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + c * (cell + gap),
            startY + r * (cell + gap),
            cell,
            cell,
          ),
          const Radius.circular(5),
        );
        if ((r + c) % 3 == 0) {
          canvas.drawRRect(rect, fill);
        } else {
          canvas.drawRRect(rect, stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CrosswordWatermarkPainter oldDelegate) => false;
}
