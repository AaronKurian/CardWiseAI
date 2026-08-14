import 'package:flutter/material.dart';

class DiagonalTexturePainter extends CustomPainter {
  const DiagonalTexturePainter({
    this.lineSpacing = 9,
    this.lineOpacity = 0.045,
  });

  final double lineSpacing;
  final double lineOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: lineOpacity)
      ..strokeWidth = 1
      ..blendMode = BlendMode.overlay;
    const angleRad = 0.4363;
    final diagonal = size.width + size.height;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-angleRad);
    canvas.translate(-diagonal / 2, -diagonal / 2);

    for (double x = 0; x <= diagonal; x += lineSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, diagonal), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DiagonalTexturePainter oldDelegate) => false;
}

class CardChip extends StatelessWidget {
  const CardChip({super.key, this.width = 38, this.height = 28});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3D98A), Color(0xFFC9A247), Color(0xFF8E6E23)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(painter: _ChipGridPainter()),
    );
  }
}

class _ChipGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    const inset = 4.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    canvas.drawRect(rect, paint..style = PaintingStyle.stroke);
    for (final fraction in [1 / 3, 2 / 3]) {
      final y = rect.top + rect.height * fraction;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
    final midX = rect.left + rect.width / 2;
    canvas.drawLine(Offset(midX, rect.top), Offset(midX, rect.bottom), paint);
  }

  @override
  bool shouldRepaint(covariant _ChipGridPainter oldDelegate) => false;
}

class ContactlessIcon extends StatelessWidget {
  const ContactlessIcon({super.key, required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ContactlessPainter(color: color)),
    );
  }
}

class _ContactlessPainter extends CustomPainter {
  const _ContactlessPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width * 0.3, size.height * 0.55);

    for (var i = 0; i < 3; i++) {
      final radius = size.width * (0.22 + i * 0.16);
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -0.95, 1.9, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContactlessPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class NetworkBadge extends StatelessWidget {
  const NetworkBadge({super.key, required this.network, required this.color});

  final String network;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = network.trim().toLowerCase();

    switch (normalized) {
      case 'visa':
        return Text(
          'VISA',
          style: TextStyle(
            color: color,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: 0.2,
          ),
        );
      case 'mastercard':
        return SizedBox(
          width: 40,
          height: 24,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEB001B),
                  ),
                ),
              ),
              Positioned(
                left: 13,
                child: Opacity(
                  opacity: 0.9,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF79E1B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'rupay':
        return Text(
          'RuPay',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        );
      default:
        if (normalized.isEmpty) return const SizedBox.shrink();
        return Text(
          network.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        );
    }
  }
}
