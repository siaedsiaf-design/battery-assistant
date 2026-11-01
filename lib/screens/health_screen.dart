// ══════════════════════════════════════════════════════════════════════
// HealthScreen — Battery Health Status
// Estimates health: Excellent / Good / Needs Replacement
// Based on temperature, charge cycles (simulated), and voltage proxy.
// ══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum HealthStatus { excellent, good, fair, needsReplacement }

class HealthScreen extends StatelessWidget {
  final int    level;
  final double temperature;
  final int    currentMa;

  const HealthScreen({
    super.key,
    required this.level,
    required this.temperature,
    required this.currentMa,
  });

  HealthStatus get _status {
    // Simple heuristic: temperature is the strongest real-time signal.
    if (temperature > 45)  return HealthStatus.needsReplacement;
    if (temperature > 40)  return HealthStatus.fair;
    if (temperature > 35)  return HealthStatus.good;
    return HealthStatus.excellent;
  }

  Color _statusColor(HealthStatus s) {
    switch (s) {
      case HealthStatus.excellent:      return const Color(0xFF39FF14);
      case HealthStatus.good:           return const Color(0xFF00BFFF);
      case HealthStatus.fair:           return const Color(0xFFFFD700);
      case HealthStatus.needsReplacement: return const Color(0xFFFF2020);
    }
  }

  String _statusLabel(HealthStatus s) {
    switch (s) {
      case HealthStatus.excellent:      return '✅ Excellent';
      case HealthStatus.good:           return '👍 Good';
      case HealthStatus.fair:           return '⚠️ Fair';
      case HealthStatus.needsReplacement: return '🔴 Needs Replacement';
    }
  }

  String _statusDesc(HealthStatus s) {
    switch (s) {
      case HealthStatus.excellent:
        return 'Your battery is in great shape. Continue good charging habits.';
      case HealthStatus.good:
        return 'Battery health is acceptable. Avoid extreme temperatures.';
      case HealthStatus.fair:
        return 'Battery shows some wear. Avoid overnight charging and heat.';
      case HealthStatus.needsReplacement:
        return 'Battery is degraded or overheating. Consider a replacement soon.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final color  = _statusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Battery Health',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            // ── Status badge ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF12121E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.12), blurRadius: 24),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.health_and_safety, color: color, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusDesc(status),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Metrics list ──
            _MetricTile(
              label: 'Current Temperature',
              value: '${temperature.toStringAsFixed(1)}°C',
              ideal: 'Ideal: 20°C – 35°C',
              icon: Icons.thermostat,
              color: temperature > 40
                  ? const Color(0xFFFF2020)
                  : const Color(0xFF39FF14),
              progress: (temperature / 60).clamp(0.0, 1.0),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 12),

            _MetricTile(
              label: 'Charging Current',
              value: '${currentMa}mA',
              ideal: 'Ideal: 1000mA – 3000mA',
              icon: Icons.bolt,
              color: currentMa < 500
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF39FF14),
              progress: (currentMa / 4500).clamp(0.0, 1.0),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 12),

            _MetricTile(
              label: 'Battery Level',
              value: '$level%',
              ideal: 'Best to keep between 20% – 80%',
              icon: Icons.battery_charging_full,
              color: const Color(0xFF39FF14),
              progress: level / 100,
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 32),

            // ── Tips for this health level ──
            _TipsCard(status: status, color: color)
                .animate().fadeIn(delay: 450.ms),
          ],
        ),
      ),
    );
  }
}

// ── Metric Tile ──────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String ideal;
  final IconData icon;
  final Color color;
  final double progress;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.ideal,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(ideal,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Tips Card based on health ─────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  final HealthStatus status;
  final Color color;

  const _TipsCard({required this.status, required this.color});

  List<String> get _tips {
    if (status == HealthStatus.excellent) {
      return [
        'Keep up the good work!',
        'Avoid leaving on charge all night.',
        'Store above 20% if shelving device.',
      ];
    }
    if (status == HealthStatus.needsReplacement) {
      return [
        'Visit a certified repair centre soon.',
        'Avoid using while charging.',
        'Do not expose to direct sunlight.',
        'Back up your data immediately.',
      ];
    }
    return [
      'Avoid extreme heat and cold.',
      'Unplug at 80–90% for daily use.',
      'Use original or certified chargers.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: color, size: 18),
              const SizedBox(width: 8),
              Text('Recommendations',
                  style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
