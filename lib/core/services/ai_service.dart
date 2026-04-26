import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';

class LimitReachedException implements Exception {
  final String message;
  LimitReachedException(this.message);
  @override
  String toString() => message;
}

class AISuggestion {
  final String topText;
  final String bottomText;
  final String filter;
  final List<AISticker> stickers;
  final String fontFamily;
  final String textColor;
  final double fontSize;

  AISuggestion({
    required this.topText,
    required this.bottomText,
    required this.filter,
    required this.stickers,
    required this.fontFamily,
    required this.textColor,
    required this.fontSize,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      topText: json['topText'] ?? '',
      bottomText: json['bottomText'] ?? '',
      filter: json['filter'] ?? 'Normal',
      stickers: (json['stickers'] as List? ?? [])
          .map((s) => AISticker.fromJson(s))
          .toList(),
      fontFamily: json['fontFamily'] ?? 'Anton',
      textColor: json['textColor'] ?? 'White',
      fontSize: (json['fontSize'] as num? ?? 42).toDouble(),
    );
  }
}

class AISticker {
  final String emoji;
  final double x;
  final double y;

  AISticker({required this.emoji, required this.x, required this.y});

  factory AISticker.fromJson(Map<String, dynamic> json) {
    return AISticker(
      emoji: json['emoji'] ?? '🔥',
      x: (json['x'] as num? ?? 0.5).toDouble(),
      y: (json['y'] as num? ?? 0.5).toDouble(),
    );
  }
}

class AIService {
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<AISuggestion> getAutoEditSuggestions(File imageFile, String userId) async {
    await _checkAndIncrementUsage(userId);
    
    final bytes = await imageFile.readAsBytes();
    
    final prompt = [
      Content.multi([
        TextPart('''
          Act as a Viral Meme Specialist with deep knowledge of 2024-2025 internet culture. 
          Analyze this image and create a high-engagement meme.
          
          Humor Guidelines:
          - Use a mix of Gen-Z humor, irony, or relatable everyday struggles.
          - If the image is chaotic, use surreal humor. If it's a person/pet, use "inner thoughts" style.
          - Keep captions short and punchy. Use UPPERCASE for that classic meme feel.
          
          Instructions:
          1. Captions: Create witty top and bottom text relevant to the visual context.
          2. Filter: Choose from [Normal, Grayscale, Sepia, Cool Blue]. Use Grayscale for "wasted" or sad vibes, Sepia for "old/classic" vibes, and Cool Blue for "chill/modern" vibes. Default to "Normal".
          3. Stickers: Suggest 0-2 emojis with coordinates (x, y from 0.0 to 1.0). 
             - Position them to complement the subject (e.g., a crown on a head, fire on something cool).
             - CRITICAL: Do NOT cover the eyes or the main subject's face.
          4. Styling:
             - fontFamily from: [Anton, Oswald, Bebas Neue, Black Ops One].
             - textColor: Choose a color that has MAXIMUM contrast with the image background.
             - fontSize: Scale between 28.0 and 64.0 based on text length.
          
          Return ONLY a JSON object:
          {
            "topText": "CAPTION HERE",
            "bottomText": "CAPTION HERE",
            "filter": "Normal",
            "stickers": [
              {"emoji": "😂", "x": 0.5, "y": 0.5}
            ],
            "fontFamily": "Anton",
            "textColor": "White",
            "fontSize": 42.0
          }
        '''),
        DataPart('image/jpeg', bytes),
      ])
    ];

    final response = await _model.generateContent(prompt);
    final text = response.text;
    
    if (text == null) {
      throw Exception('AI returned empty response');
    }

    try {
      final json = jsonDecode(text);
      return AISuggestion.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }

  Future<DateTime> _getNetworkTimeUtc() async {
    
    try {
      
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.headUrl(Uri.parse('https://www.google.com'));
      final response = await request.close();
      final dateHeader = response.headers.value('date');
      
      if (dateHeader != null) {
        return HttpDate.parse(dateHeader).toUtc();
      }
    
    } catch (e) {
      // Fallback to local device time in UTC if network request fails

    }
    
    return DateTime.now().toUtc();

  }

  Future<void> _checkAndIncrementUsage(String userId) async {
    
    final docRef = FirebaseFirestore.instance.collection('ai_usage').doc(userId);
    final nowUtc = await _getNetworkTimeUtc();
    
    return FirebaseFirestore.instance.runTransaction((transaction) async {
    
      final doc = await transaction.get(docRef);
      
      if (!doc.exists) {
    
        transaction.set(docRef, {
          'count': 1,
          'lastReset': FieldValue.serverTimestamp(),
        });
    
        return;
    
      }

      final data = doc.data()!;
      final lastResetUtc = (data['lastReset'] as Timestamp?)?.toDate().toUtc() ?? nowUtc;
      int count = data['count'] ?? 0;

      final isSameDay = lastResetUtc.year == nowUtc.year && 
                        lastResetUtc.month == nowUtc.month && 
                        lastResetUtc.day == nowUtc.day;

      if (!isSameDay) {
        
        transaction.update(docRef, {
          'count': 1,
          'lastReset': FieldValue.serverTimestamp(),
        });

      } else {
        
        if (count >= 5) {
          throw LimitReachedException('Kamu telah mencapai batas 5 request AI hari ini. Coba lagi besok!');
        }
        
        transaction.update(docRef, {
          'count': count + 1,
        });
        
      }
      
    });
    
  }
}
