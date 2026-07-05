import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tw_stock_capital_flow/domain/services/signal_change_detector.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  static Future<void> showSignalChanges(List<SignalChange> changes) async {
    if (changes.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'signal_changes_v1',
      '訊號異動提醒',
      channelDescription: '觀察清單中板塊的買賣訊號變化通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      1001,
      '📊 觀察板塊訊號異動',
      _buildBody(changes),
      details,
    );
  }

  static String _buildBody(List<SignalChange> changes) {
    if (changes.length == 1) {
      final c = changes.first;
      if (c.isFirstTracking) {
        return '${c.category} 開始追蹤，當前訊號：${c.newLabel}';
      }
      final arrow = c.isUpgrade ? '↑' : (c.isDowngrade ? '↓' : '→');
      return '${c.category}：${c.previousLabel} $arrow ${c.newLabel}';
    }

    final upgrades = changes.where((c) => c.isUpgrade).length;
    final downgrades = changes.where((c) => c.isDowngrade).length;
    final firstTracks = changes.where((c) => c.isFirstTracking).length;

    final parts = <String>[];
    if (upgrades > 0) parts.add('$upgrades 個升級 ↑');
    if (downgrades > 0) parts.add('$downgrades 個降級 ↓');
    if (firstTracks > 0) parts.add('$firstTracks 個首次追蹤');

    return parts.isNotEmpty
        ? '${parts.join('、')}，共 ${changes.length} 個板塊異動'
        : '共 ${changes.length} 個板塊訊號異動，建議確認操作方向';
  }
}
