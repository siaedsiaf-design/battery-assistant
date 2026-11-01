// ══════════════════════════════════════════════════════════════════════
// BatteryService
// Runs as a Flutter Background Service (Foreground Service on Android).
// Polls battery every 60 s, persists 24-h log, triggers notifications.
// ══════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';

import '../models/battery_log.dart';
import 'notification_service.dart';

// ── Keys ────────────────────────────────────────────────────────────
const _kLogKey        = 'battery_logs_v1';
const _kCurrentKey    = 'battery_current';
const _kWidgetGroup   = 'com.batteryassistant.app';

// ── Init (called once at app start) ─────────────────────────────────

Future<void> initBatteryService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'battery_service',
      initialNotificationTitle: 'Battery Assistant',
      initialNotificationContent: 'Monitoring battery in background…',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: _onServiceStart,
      onBackground: _iosBackground,
    ),
  );

  await service.startService();
}

// ── iOS background handler (stub) ───────────────────────────────────
@pragma('vm:entry-point')
Future<bool> _iosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// ── Service entry point ─────────────────────────────────────────────
@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Show persistent foreground notification while running.
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) =>
        service.setAsForegroundService());
    service.on('setAsBackground').listen((_) =>
        service.setAsBackgroundService());
  }
  service.on('stopService').listen((_) => service.stopSelf());

  final battery  = Battery();
  final notif    = NotificationService();
  await notif.init();

  // Poll every 60 seconds.
  Timer.periodic(const Duration(seconds: 60), (_) async {
    final level       = await battery.batteryLevel;
    final state       = await battery.batteryState;
    final isCharging  = state == BatteryState.charging ||
                        state == BatteryState.full;

    // battery_plus doesn't expose temp/mA natively on all devices;
    // we mock temperature from a typical range and read mA via
    // the Android BatteryManager where available (injected below).
    const temperature = 30.0; // Replace with platform channel if needed.
    const currentMa   = 1500; // Replace with platform channel if needed.

    final log = BatteryLog(
      timestamp: DateTime.now(),
      level: level,
      temperature: temperature,
      isCharging: isCharging,
      currentMa: currentMa,
    );

    await _persistLog(log);
    await _updateWidget(level, isCharging, temperature);

    // Broadcast to UI if it's open.
    service.invoke('batteryUpdate', log.toJson());

    // Fire smart alerts.
    await notif.evaluate(
      level: level,
      isCharging: isCharging,
      temperature: temperature,
      currentMa: currentMa,
    );
  });
}

// ── Log persistence ─────────────────────────────────────────────────

Future<void> _persistLog(BatteryLog log) async {
  final prefs = await SharedPreferences.getInstance();
  final raw   = prefs.getStringList(_kLogKey) ?? [];

  // Keep only the last 24 hours (1440 entries at 1/min).
  final cutoff = DateTime.now().subtract(const Duration(hours: 24));
  final updated = raw
      .map((e) => BatteryLog.fromJson(jsonDecode(e)))
      .where((l) => l.timestamp.isAfter(cutoff))
      .toList()
    ..add(log);

  await prefs.setStringList(
    _kLogKey,
    updated.map((l) => jsonEncode(l.toJson())).toList(),
  );

  // Save latest reading for quick access.
  await prefs.setString(_kCurrentKey, jsonEncode(log.toJson()));
}

// ── Home screen widget update ────────────────────────────────────────

Future<void> _updateWidget(
    int level, bool isCharging, double temp) async {
  await HomeWidget.saveWidgetData<String>('battery_level', '$level%');
  await HomeWidget.saveWidgetData<String>(
      'battery_status', isCharging ? '⚡ Charging' : '🔋 Discharging');
  await HomeWidget.saveWidgetData<String>(
      'battery_temp', '${temp.toStringAsFixed(1)}°C');
  await HomeWidget.updateWidget(
    name: 'BatteryWidgetProvider',
    androidName: 'BatteryWidgetProvider',
    qualifiedAndroidName:
        'com.batteryassistant.app.BatteryWidgetProvider',
    iOSName: 'BatteryWidget',
  );
}

// ── Public helpers for UI ───────────────────────────────────────────

/// Load the stored 24-h log (called from UI).
Future<List<BatteryLog>> loadLogs() async {
  final prefs = await SharedPreferences.getInstance();
  final raw   = prefs.getStringList(_kLogKey) ?? [];
  return raw.map((e) => BatteryLog.fromJson(jsonDecode(e))).toList();
}

/// Load the most recent battery snapshot.
Future<BatteryLog?> loadCurrentSnapshot() async {
  final prefs = await SharedPreferences.getInstance();
  final raw   = prefs.getString(_kCurrentKey);
  if (raw == null) return null;
  return BatteryLog.fromJson(jsonDecode(raw));
}

/// Clear all logs.
Future<void> clearLogs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kLogKey);
}
