import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static const String channelKey = 'ai_generation_channel';

  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      // null means use the default app icon
      null,
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'AI Generation Notifications',
          channelDescription: 'Notification channel for AI generation updates',
          defaultColor: const Color(0xFFFFD500), // Vibrant Yellow from rules.md
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
          criticalAlerts: true,
        )
      ],
      debug: true,
    );
  }

  static Future<void> requestPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> showAiGenerationCompleteNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: channelKey,
        title: 'Caption AI kamu udah jadi nih! 🧠✨',
        body: 'Cek hasilnya sekarang.',
        notificationLayout: NotificationLayout.Default,
        backgroundColor: const Color(0xFFFFD500),
        color: Colors.black,
      ),
    );
  }

  static Future<void> showAiGenerationErrorNotification(String errorMessage) async {
    // Simplify error message for notification display
    final isQuotaError = errorMessage.contains('batas') || errorMessage.contains('limit');
    final title = isQuotaError ? 'Kuota AI Habis 😔' : 'AI Gagal Berjalan ❌';
    final body = isQuotaError
        ? 'Kamu telah mencapai batas harian. Coba lagi besok!'
        : 'Terjadi kesalahan saat membuat meme. Silakan coba lagi.';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        backgroundColor: const Color(0xFFFF5555),
        color: Colors.white,
      ),
    );
  }
}
