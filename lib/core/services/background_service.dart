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

// Fixed key for the singleton AI task to prevent duplicate parallel runs.
const _kAiTaskUniqueName = 'singleton_ai_task';
const _kAiTaskName = 'ai_generation_task';

// SharedPreferences keys shared with the foreground polling loop.
const kAiSuggestionKey = 'last_ai_suggestion';
const kAiErrorKey = 'last_ai_error';

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

      if (task == _kAiTaskName) {
        final String? imagePath = inputData?['imagePath'] as String?;
        final String? userId = inputData?['userId'] as String?;

        if (imagePath == null || imagePath.isEmpty || userId == null || userId.isEmpty) {
          debugPrint("Background Task: Invalid input data.");
          return false;
        }

        final File imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          debugPrint("Background Task: Image file not found at $imagePath.");
          return false;
        }

        // Clear any previous stale results before starting
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(kAiSuggestionKey);
        await prefs.remove(kAiErrorKey);

        final aiService = AIService();

        try {
          final suggestion = await aiService.getAutoEditSuggestions(imageFile, userId);

          // Save result including imagePath for UI validation
          await prefs.setString(kAiSuggestionKey, jsonEncode({
            'imagePath': imagePath,
            'topText': suggestion.topText,
            'bottomText': suggestion.bottomText,
            'filter': suggestion.filter,
            'fontFamily': suggestion.fontFamily,
            'textColor': suggestion.textColor,
            'fontSize': suggestion.fontSize,
            'stickers': suggestion.stickers.map((s) => {'emoji': s.emoji, 'x': s.x, 'y': s.y}).toList(),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));

          // Only notify user after successful AI generation
          await NotificationService.initializeNotification();
          await NotificationService.showAiGenerationCompleteNotification();

        } catch (aiError) {
          // Save the user-friendly error so the foreground UI can surface it
          debugPrint("Background Task AI Error: $aiError");
          await prefs.setString(kAiErrorKey, aiError.toString());

          // Show error notification
          await NotificationService.initializeNotification();
          await NotificationService.showAiGenerationErrorNotification(aiError.toString());
        }
      }
      return true;
    } catch (e) {
      debugPrint("Background Task Dispatcher Error: $e");
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
      _kAiTaskUniqueName, // Fixed name = singleton, prevents duplicates
      _kAiTaskName,
      inputData: {
        'imagePath': imagePath,
        'userId': userId,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace, // Replace pending task
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
