// ══════════════════════════════════════════════════════════════════════
// NotificationService
// Handles push notifications, full-charge alarm (bypasses silent),
// vibration patterns, and slow-charger detection.
// ══════════════════════════════════════════════════════════════════════

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  // ── Singleton ──────────────────────────────────────────────────────
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _alarm = AudioPlayer();

  // One-shot flags reset when battery returns above threshold.
  bool _fired20  = false;
  bool _fired10  = false;
  bool _fired5   = false;
  bool _fired100 = false;
  bool _firedSlow = false;
  int  _prevLevel = -1;

  // ── Initialise ─────────────────────────────────────────────────────

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await impl?.createNotificationChannel(const AndroidNotificationChannel(
      'battery_normal', 'Battery Alerts',
      description: 'General battery level warnings',
      importance: Importance.high,
    ));

    await impl?.createNotificationChannel(const AndroidNotificationChannel(
      'battery_critical', 'Critical Battery',
      description: 'Emergency low-battery alerts',
      importance: Importance.max,
      enableVibration: true,
    ));

    await impl?.createNotificationChannel(const AndroidNotificationChannel(
      'battery_full', 'Battery Full',
      description: 'Full charge alarm — rings on silent',
      importance: Importance.max,
      enableVibration: true,
    ));
  }

  // ── Core Evaluation (call on every battery tick) ───────────────────

  Future<void> evaluate({
    required int level,
    required bool isCharging,
    required double temperature,
    required int currentMa,
  }) async {
    // Reset flags as battery climbs back up.
    if (level > 25) _fired20   = false;
    if (level > 15) _fired10   = false;
    if (level > 8)  _fired5    = false;
    if (level < 98) _fired100  = false;
    if (!isCharging) _firedSlow = false;

    // ── Discharging alerts ──
    if (!isCharging) {
      if (level <= 20 && level > 10 && !_fired20) {
        _fired20 = true;
        await _notify(
          id: 1,
          channelId: 'battery_normal',
          title: '🔋 Battery at 20%',
          body: 'Please plug in your charger to protect your battery health.',
          importance: Importance.high,
          priority: Priority.high,
        );
      }

      if (level <= 10 && level > 5 && !_fired10) {
        _fired10 = true;
        await _notify(
          id: 2,
          channelId: 'battery_critical',
          title: '⚠️ Critical: Battery at 10%',
          body: 'Your phone will shut down soon! Connect charger immediately.',
          importance: Importance.max,
          priority: Priority.max,
        );
        _vibrate([0, 500, 200, 500, 200, 500]);
      }

      if (level <= 5 && !_fired5) {
        _fired5 = true;
        await _notify(
          id: 3,
          channelId: 'battery_critical',
          title: '🚨 EMERGENCY: 5% Left!',
          body: 'Connect the charger NOW or your phone will power off!',
          importance: Importance.max,
          priority: Priority.max,
        );
        _vibrate([0, 800, 100, 800, 100, 800, 100, 800]);
      }
    }

    // ── Full charge alarm (bypasses silent mode) ──
    if (isCharging && level >= 100 && !_fired100) {
      _fired100 = true;
      await _notify(
        id: 4,
        channelId: 'battery_full',
        title: '✅ Battery Full!',
        body: 'Unplug the charger to prevent overcharging and extend lifespan.',
        importance: Importance.max,
        priority: Priority.max,
      );
      _ringAlarm();
      _vibrate([0, 1000, 300, 1000, 300, 1000]);
    }

    // ── Slow charger detection ──
    if (isCharging && currentMa > 0 && currentMa < 500 && !_firedSlow) {
      _firedSlow = true;
      await _notify(
        id: 5,
        channelId: 'battery_normal',
        title: '🔌 Slow Charging Detected',
        body: 'Only ${currentMa}mA. Check your cable or use a faster charger.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
    }

    // ── Overheat warning ──
    if (temperature > 45) {
      await _notify(
        id: 6,
        channelId: 'battery_critical',
        title: '🌡️ Battery Overheating!',
        body:
            'Temperature is ${temperature.toStringAsFixed(1)}°C. Stop charging and cool device.',
        importance: Importance.max,
        priority: Priority.max,
      );
    }

    _prevLevel = level;
  }

  // ── Private Helpers ────────────────────────────────────────────────

  Future<void> _notify({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required Importance importance,
    required Priority priority,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId,
        importance: importance,
        priority: priority,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Rings alarm on Android RING stream — bypasses silent/vibrate mode.
  Future<void> _ringAlarm() async {
    await _alarm.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        audioFocus: AndroidAudioFocus.gainTransient,
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.alarm,
        audioMode: AndroidAudioMode.normal,
      ),
    ));
    await _alarm.play(AssetSource('sounds/alarm.mp3'));
  }

  void _vibrate(List<int> pattern) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: pattern);
    }
  }

  Future<void> dismiss(int id) => _plugin.cancel(id);
  Future<void> dismissAll() => _plugin.cancelAll();
}
