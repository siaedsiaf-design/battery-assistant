// ══════════════════════════════════════════════════════════════════════
// TipsScreen — Charging Tips & Battery Education
// ══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  static const _tips = [
    _Tip(
      icon: Icons.battery_charging_full,
      title: 'Keep Between 20% – 80%',
      body:
          'Lithium-ion batteries degrade faster at very low or full charge. '
          'Topping up to 80% and recharging at 20% maximises cycle life.',
      color: Color(0xFF39FF14),
    ),
    _Tip(
      icon: Icons.power_off,
      title: 'Unplug After Full Charge',
      body:
          'Leaving the phone plugged in at 100% generates heat and keeps '
          'the battery in a high-stress state. Unplug once charged.',
      color: Color(0xFF39FF14),
    ),
    _Tip(
      icon: Icons.thermostat,
      title: 'Avoid Extreme Temperatures',
      body:
          'Heat above 40°C permanently damages battery chemistry. '
          'Do not leave the phone in direct sunlight or a hot car.',
      color: Color(0xFFFFD700),
    ),
    _Tip(
      icon: Icons.cable,
      title: 'Use Quality Cables & Chargers',
      body:
          'Cheap chargers can deliver unstable voltage, stressing the '
          'battery. Use the original or MFi/USB-IF certified accessories.',
      color: Color(0xFF00BFFF),
    ),
    _Tip(
      icon: Icons.nightlight,
      title: 'Do Not Charge Overnight',
      body:
          'Trickle charging at 100% overnight generates sustained heat. '
          'Use a timer plug or rely on this app\'s full-charge alarm.',
      color: Color(0xFFFF9500),
    ),
    _Tip(
      icon: Icons.flash_on,
      title: 'Fast Charging Heats the Battery',
      body:
          'Fast/super-fast charging is convenient but generates more heat. '
          'For daily top-ups, standard charging is gentler long-term.',
      color: Color(0xFFFF2020),
    ),
    _Tip(
      icon: Icons.wifi_off,
      title: 'Turn Off Unused Radios',
      body:
          'Bluetooth, Wi-Fi scanning, and mobile data drain the battery '
          'constantly. Disable what you are not using.',
      color: Color(0xFF39FF14),
    ),
    _Tip(
      icon: Icons.brightness_low,
      title: 'Lower Screen Brightness',
      body:
          'The display is the biggest battery consumer. Auto-brightness '
          'and dark mode together can extend screen-on time significantly.',
      color: Color(0xFF00BFFF),
    ),
    _Tip(
      icon: Icons.storage,
      title: 'Keep 10% Headroom',
      body:
          'Letting the battery drain to 0% before charging is a myth. '
          'Deep discharges stress the battery. Recharge at ~20%.',
      color: Color(0xFFFFD700),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Charging Tips',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),

      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _TipCard(tip: _tips[i])
            .animate()
            .fadeIn(delay: Duration(milliseconds: 60 * i), duration: 400.ms)
            .slideX(begin: 0.08),
      ),
    );
  }
}

// ── Tip data model ────────────────────────────────────────────────────

class _Tip {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _Tip({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

// ── Tip Card widget ───────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final _Tip tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tip.color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: tip.color.withOpacity(0.06), blurRadius: 12),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tip.icon, color: tip.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: TextStyle(
                        color: tip.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(tip.body,
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
