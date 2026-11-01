// ══════════════════════════════════════════════════════════════════════
// HomeScreen — Main dashboard
// Battery ring, live stats, 24-h chart, quick nav buttons.
// ══════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/battery_log.dart';
import '../services/battery_service.dart';
import '../widgets/battery_ring.dart';
import '../widgets/battery_chart.dart';
import 'health_screen.dart';
import 'tips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Live values.
  int    _level       = 0;
  bool   _isCharging  = false;
  double _temperature = 0;
  int    _currentMa   = 0;
  List<BatteryLog> _logs = [];

  StreamSubscription? _serviceSub;
  StreamSubscription? _batterySub;
  final _battery = Battery();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listenToService();
    _listenToBattery();
  }

  Future<void> _loadInitialData() async {
    final snapshot = await loadCurrentSnapshot();
    final logs     = await loadLogs();
    final level    = await _battery.batteryLevel;
    final state    = await _battery.batteryState;

    if (!mounted) return;
    setState(() {
      _level      = snapshot?.level ?? level;
      _isCharging = snapshot?.isCharging ??
                    (state == BatteryState.charging ||
                     state == BatteryState.full);
      _temperature = snapshot?.temperature ?? 0;
      _currentMa   = snapshot?.currentMa ?? 0;
      _logs        = logs;
    });
  }

  /// Listen to background service broadcasts for live updates.
  void _listenToService() {
    final service = FlutterBackgroundService();
    _serviceSub = service.on('batteryUpdate').listen((event) {
      if (event == null || !mounted) return;
      final log = BatteryLog.fromJson(Map<String, dynamic>.from(event));
      setState(() {
        _level       = log.level;
        _isCharging  = log.isCharging;
        _temperature = log.temperature;
        _currentMa   = log.currentMa;
        _logs        = [..._logs, log];
        // Keep only 24 h worth.
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        _logs.removeWhere((l) => l.timestamp.isBefore(cutoff));
      });
    });
  }

  /// Also listen directly to battery state changes for instant UI refresh.
  void _listenToBattery() {
    _batterySub = _battery.onBatteryStateChanged.listen((state) async {
      final level = await _battery.batteryLevel;
      if (!mounted) return;
      setState(() {
        _level      = level;
        _isCharging = state == BatteryState.charging ||
                      state == BatteryState.full;
      });
    });
  }

  @override
  void dispose() {
    _serviceSub?.cancel();
    _batterySub?.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Battery Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _loadInitialData,
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Battery Ring ──
            Center(
              child: BatteryRing(
                level: _level,
                isCharging: _isCharging,
                temperature: _temperature,
                currentMa: _currentMa,
              ),
            ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.85, 0.85),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 32),

            // ── Quick stat cards ──
            _StatsRow(
              level: _level,
              isCharging: _isCharging,
              temperature: _temperature,
              currentMa: _currentMa,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // ── 24-h chart ──
            _SectionHeader(
              title: '24-Hour Battery History',
              icon: Icons.show_chart,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BatteryChart(logs: _logs),
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

            const SizedBox(height: 32),

            // ── Navigation cards ──
            _NavCard(
              title: 'Battery Health',
              subtitle: 'Check if your battery needs replacement',
              icon: Icons.health_and_safety,
              color: const Color(0xFF39FF14),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => HealthScreen(
                    level: _level,
                    temperature: _temperature,
                    currentMa: _currentMa,
                  ))),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 12),

            _NavCard(
              title: 'Charging Tips',
              subtitle: 'Make your battery last longer',
              icon: Icons.tips_and_updates,
              color: const Color(0xFF00BFFF),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TipsScreen())),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Widget pieces ─────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int level;
  final bool isCharging;
  final double temperature;
  final int currentMa;

  const _StatsRow({
    required this.level,
    required this.isCharging,
    required this.temperature,
    required this.currentMa,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Status',
          value: isCharging ? 'Charging' : 'Discharging',
          icon: isCharging ? Icons.bolt : Icons.battery_5_bar,
          color: const Color(0xFF39FF14),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: 'Temp',
          value: '${temperature.toStringAsFixed(1)}°C',
          icon: Icons.thermostat,
          color: temperature > 40
              ? const Color(0xFFFF2020)
              : const Color(0xFF39FF14),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: 'Current',
          value: '${currentMa}mA',
          icon: Icons.electrical_services,
          color: const Color(0xFF39FF14),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF39FF14), size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 16),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color.withOpacity(0.6), size: 16),
          ],
        ),
      ),
    );
  }
}
