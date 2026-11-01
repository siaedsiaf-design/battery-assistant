// ══════════════════════════════════════════════════════════
// BatteryLog — Single battery snapshot stored over 24 hours
// ══════════════════════════════════════════════════════════

class BatteryLog {
  final DateTime timestamp;
  final int level;           // 0–100 percent
  final double temperature;  // Celsius
  final bool isCharging;
  final int currentMa;       // milli-amperes (positive = charging in)

  const BatteryLog({
    required this.timestamp,
    required this.level,
    required this.temperature,
    required this.isCharging,
    required this.currentMa,
  });

  /// Serialise → JSON for SharedPreferences persistence.
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.millisecondsSinceEpoch,
        'level': level,
        'temperature': temperature,
        'isCharging': isCharging,
        'currentMa': currentMa,
      };

  /// Deserialise ← JSON from SharedPreferences.
  factory BatteryLog.fromJson(Map<String, dynamic> json) => BatteryLog(
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        level: json['level'] as int,
        temperature: (json['temperature'] as num).toDouble(),
        isCharging: json['isCharging'] as bool,
        currentMa: (json['currentMa'] as num?)?.toInt() ?? 0,
      );
}
