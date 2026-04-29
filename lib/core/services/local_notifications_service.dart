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

  static const String _channelId = 'loantrack_channel';
  static const String _channelName = 'LoanTrack notifications';
  static const String _channelDescription =
      'Recordatorios y eventos de préstamos';

  static const AndroidNotificationDetails _androidBaseDetails =
      AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDescription,
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
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _createAndroidChannel();
    await requestPermissions();
    _initialized = true;
    _log('initialized OK (channel=$_channelId, tz=${tz.local.name})');
  }

  Future<void> _createAndroidChannel() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    _log('android POST_NOTIFICATIONS permission granted=$granted');

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showLoanCreated({
    required String loanId,
    required String clientName,
    required double totalAmount,
    required int totalPayments,
  }) async {
    await initialize();
    _log('showLoanCreated loan=$loanId client=$clientName');
    await _plugin.show(
      _notificationIdFromString('loan_$loanId'),
      'Préstamo creado',
      'Préstamo de \$${totalAmount.toStringAsFixed(2)} para $clientName ($totalPayments cuotas).',
      const NotificationDetails(
        android: _androidBaseDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'loan:$loanId',
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

    if (!scheduleDate.isAfter(now)) {
      _log(
          'skip schedule reminder loan=$loanId #$paymentNumber (date $scheduleDate not in future)');
      return;
    }

    _log('scheduling reminder loan=$loanId #$paymentNumber at $scheduleDate');
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
    _log('showPaymentRegistered payment=$paymentId #$paymentNumber');
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
    _log('showPenaltyApplied payment=$paymentId #$paymentNumber');
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
      _log('No se pudo obtener zona horaria local, se usa UTC.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LocalNotifications] $message');
    }
  }
}
