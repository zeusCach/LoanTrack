import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationDetails _androidBaseDetails =
      AndroidNotificationDetails(
    'loantrack_notifications',
    'LoanTrack notifications',
    channelDescription: 'Recordatorios y eventos de préstamos',
    importance: Importance.max,
    priority: Priority.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await requestPermissions();
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> schedulePaymentDueReminder({
    required String loanId,
    required String clientName,
    required int paymentNumber,
    required DateTime expectedDate,
    required double amount,
  }) async {
    await initialize();

    final scheduleDate = expectedDate.subtract(const Duration(days: 1));
    final now = DateTime.now();

    if (!scheduleDate.isAfter(now)) return;

    await _plugin.zonedSchedule(
      _notificationIdForReminder(loanId, paymentNumber),
      'Cuota próxima a vencer',
      'Cliente $clientName: la cuota #$paymentNumber (\$${amount.toStringAsFixed(2)}) vence mañana.',
      tz.TZDateTime.from(scheduleDate, tz.local),
      const NotificationDetails(
        android: _androidBaseDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'loan:$loanId:payment:$paymentNumber',
    );
  }

  Future<void> showPaymentRegistered({
    required String paymentId,
    required int paymentNumber,
    required double amount,
  }) async {
    await initialize();
    await _plugin.show(
      _notificationIdFromString('paid_$paymentId'),
      'Pago registrado',
      'Se registró el pago de la cuota #$paymentNumber por \$${amount.toStringAsFixed(2)}.',
      const NotificationDetails(
        android: _androidBaseDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'payment:$paymentId',
    );
  }

  Future<void> showPenaltyApplied({
    required String paymentId,
    required int paymentNumber,
    required double penaltyAmount,
  }) async {
    await initialize();
    await _plugin.show(
      _notificationIdFromString('penalty_$paymentId'),
      'Sanción aplicada',
      'Se aplicó una sanción de \$${penaltyAmount.toStringAsFixed(2)} a la cuota #$paymentNumber.',
      const NotificationDetails(
        android: _androidBaseDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'penalty:$paymentId',
    );
  }

  int _notificationIdForReminder(String loanId, int paymentNumber) {
    return _notificationIdFromString('reminder_${loanId}_$paymentNumber');
  }

  int _notificationIdFromString(String input) {
    var hash = 0;
    for (final code in input.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      if (kDebugMode) {
        debugPrint('No se pudo obtener zona horaria local, se usa UTC.');
      }
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}
