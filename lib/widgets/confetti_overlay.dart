import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../core/theme/app_theme.dart';

/// Bulmaca tamamlandığında ekranı şenlendiren hafif vektörel konfeti animasyonu.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.active,
  });

  final bool active;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  static const _palette = [
    AppPalette.brassBright,
    AppPalette.brass,
    Color(0xFFF3E2BA),
    AppPalette.correct,
    Color(0xFF9A6B3A),
    AppPalette.card,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    final rng = math.Random(42);
    _pieces = List.generate(64, (i) {
      return _ConfettiPiece(
        startX: rng.nextDouble(),
        driftX: (rng.nextDouble() - 0.5) * 0.35,
        startY: -0.05 - rng.nextDouble() * 0.35,
        speedY: 0.85 + rng.nextDouble() * 0.75,
        size: 6.0 + rng.nextDouble() * 6.5,
        rotationSpeed: (rng.nextDouble() - 0.5) * 10,
        color: _palette[i % _palette.length],
        isCircle: i % 4 == 0,
      );
    });
    if (widget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          if (_controller.isDismissed) return const SizedBox.shrink();
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: _controller.value,
              pieces: _pieces,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.startX,
    required this.driftX,
    required this.startY,
    required this.speedY,
    required this.size,
    required this.rotationSpeed,
    required this.color,
    required this.isCircle,
  });

  final double startX;
  final double driftX;
  final double startY;
  final double speedY;
  final double size;
  final double rotationSpeed;
  final Color color;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.pieces,
  });

  final double progress;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final fadeOut = progress > 0.75 ? (1.0 - (progress - 0.75) / 0.25) : 1.0;
    for (final p in pieces) {
      final y = (p.startY + p.speedY * progress) * size.height;
      if (y < -20 || y > size.height + 20) continue;
      final x = (p.startX + p.driftX * progress + math.sin(progress * 8 + p.startX * 10) * 0.025) *
          size.width;
      final paint = Paint()..color = p.color.withValues(alpha: fadeOut.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * progress);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
