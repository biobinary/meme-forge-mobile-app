import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';

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

  Future<AISuggestion> getAutoEditSuggestions(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    
    final prompt = [
      Content.multi([
        TextPart('''
          Act as a professional meme creator. Analyze this image and create a funny meme. 
          
          Instructions:
          1. Create witty top and bottom captions relevant to the image content. Use UPPERCASE.
          2. Suggest a filter from: [Normal, Grayscale, Sepia, Cool Blue]. ONLY use a filter if it enhances the meme's humor or mood. Otherwise, use "Normal".
          3. Suggest 0-2 stickers (emojis) with coordinates (x, y from 0.0 to 1.0). ONLY add stickers if they significantly increase the humor.
          4. Suggest the best text styling:
             - fontFamily from: [Anton, Oswald, Bebas Neue, Black Ops One].
             - textColor from: [White, Vibrant Yellow, Orange, Red, Lime, Electric Indigo, Black].
             - fontSize between 24.0 and 72.0 based on text length and image space.

          Return ONLY a JSON object in this format:
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
}
