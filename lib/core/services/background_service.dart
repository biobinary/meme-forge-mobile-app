import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import 'ai_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint("Warning: Could not load .env in background: $e");
      }

      if (task == "ai_generation_task") {
        final String imagePath = inputData?['imagePath'];
        final String userId = inputData?['userId'];

        if (imagePath.isEmpty || userId.isEmpty) return false;

        final File imageFile = File(imagePath);
        final aiService = AIService();
        
        final suggestion = await aiService.getAutoEditSuggestions(imageFile, userId);
      
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_ai_suggestion', jsonEncode({
          'topText': suggestion.topText,
          'bottomText': suggestion.bottomText,
          'filter': suggestion.filter,
          'fontFamily': suggestion.fontFamily,
          'textColor': suggestion.textColor,
          'fontSize': suggestion.fontSize,
          'stickers': suggestion.stickers.map((s) => {'emoji': s.emoji, 'x': s.x, 'y': s.y}).toList(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }));

        await NotificationService.initializeNotification();
        await NotificationService.showAiGenerationCompleteNotification();
      }
      return true;
    } catch (e) {
      debugPrint("Background Task Error: $e");
      return false;
    }
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static void scheduleAITask(String imagePath, String userId) {
    Workmanager().registerOneOffTask(
      "ai_task_${DateTime.now().millisecondsSinceEpoch}",
      "ai_generation_task",
      inputData: {
        'imagePath': imagePath,
        'userId': userId,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
