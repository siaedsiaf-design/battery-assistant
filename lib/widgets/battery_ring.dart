// ══════════════════════════════════════════════════════════════════════
// BatteryRing — Animated circular battery indicator
// Neon green when safe, transitions to neon red when critical.
// ══════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BatteryRing extends StatefulWidget {
  final int level;
  final bool isCharging;
  final double temperature;
  final int currentMa;

  const BatteryRing({
    super.key,
    required this.level,
    required this.isCharging,
    required this.temperature,
    required this.currentMa,
  });

  @override
  State<BatteryRing> createState() => _BatteryRingState();
}

class _BatteryRingState extends State<BatteryRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Colour logic: green > 50%, yellow 20–50%, red < 20%.
  Color get _ringColor {
    if (widget.level > 50) return const Color(0xFF39FF14); // neon green
    if (widget.level > 20) return const Color(0xFFFFD700); // gold
    return const Color(0xFFFF2020);                        // neon red
  }

  String get _statusLabel {
    if (widget.isCharging) return '⚡ Charging';
    if (widget.level > 50) return '✅ Good';
    if (widget.level > 20) return '⚠️ Low';
    return '🚨 Critical';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        // Pulsing glow when critical or charging.
        final glow = (widget.level < 20 || widget.isCharging)
            ? 8.0 + _pulseCtrl.value * 16
            : 8.0;

        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Outer glow ring ──
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _ringColor.withOpacity(0.35),
                      blurRadius: glow * 2,
                      spreadRadius: glow / 2,
                    ),
                  ],
                ),
              ),

              // ── Arc painter ──
              CustomPaint(
                size: const Size(260, 260),
                painter: _ArcPainter(
                  level: widget.level,
                  color: _ringColor,
                  pulse: _pulseCtrl.value,
                ),
              ),

              // ── Centre content ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Percentage
                  Text(
                    '${widget.level}%',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: _ringColor,
                      shadows: [
                        Shadow(
                          color: _ringColor.withOpacity(0.8),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 4),

                  // Status label
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: _ringColor.withOpacity(0.9),
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Temp + mA row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InfoChip(
                        icon: Icons.thermostat,
                        label:
                            '${widget.temperature.toStringAsFixed(1)}°C',
                        color: widget.temperature > 40
                            ? const Color(0xFFFF2020)
                            : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.bolt,
                        label: '${widget.currentMa} mA',
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Arc Painter ────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final int level;
  final Color color;
  final double pulse;

  _ArcPainter({
    required this.level,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background track.
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Filled arc.
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2 + pulse * 2);

    final sweep = 2 * math.pi * (level / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start from top
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.level != level || old.color != color || old.pulse != pulse;
}

// ── Info Chip ──────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
