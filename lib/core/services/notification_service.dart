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
        // Using colors from rules.md
        backgroundColor: const Color(0xFFFFD500), 
        color: Colors.black,
      ),
    );
  }
}
