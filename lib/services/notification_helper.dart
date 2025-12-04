import 'package:belanja_praktis/data/models/pantry_item.dart';
import 'package:belanja_praktis/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();

  static Future<void> scheduleExpiryNotifications(PantryItem item) async {
    if (item.expiryDate == null) return;

    final now = DateTime.now();
    final expiryDate = item.expiryDate!;
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    // Batalkan notifikasi lama
    await _notificationService.cancelNotification(item.id.hashCode);

    // Jika sudah kadaluwarsa, tidak perlu jadwalkan notifikasi
    if (daysUntilExpiry < 0) return;

    // Notifikasi H-1
    if (daysUntilExpiry >= 1) {
      await _scheduleNotification(item: item, daysBefore: 1, idSuffix: 1);
    }

    // Notifikasi H-3
    if (daysUntilExpiry >= 3) {
      await _scheduleNotification(item: item, daysBefore: 3, idSuffix: 3);
    }

    // Notifikasi H-7
    if (daysUntilExpiry >= 7) {
      await _scheduleNotification(item: item, daysBefore: 7, idSuffix: 7);
    }
  }

  static Future<void> _scheduleNotification({
    required PantryItem item,
    required int daysBefore,
    required int idSuffix,
  }) async {
    if (item.expiryDate == null) return;

    final notificationDate = item.expiryDate!.subtract(
      Duration(days: daysBefore),
    );
    final formattedDate = DateFormat('d MMMM yyyy').format(item.expiryDate!);

    await _notificationService.scheduleExpiryNotification(
      id: '${item.id}_$idSuffix'.hashCode,
      title: '${item.name} Akan Kadaluwarsa',
      body:
          '${item.name} akan kadaluwarsa pada $formattedDate (${daysBefore} hari lagi)',
      scheduledDate: notificationDate,
    );
  }

  static Future<void> cancelExpiryNotifications(String itemId) async {
    for (var i = 1; i <= 3; i++) {
      await _notificationService.cancelNotification('${itemId}_$i'.hashCode);
    }
  }
}
