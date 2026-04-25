import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';

class AISuggestion {
  final String topText;
  final String bottomText;
  final String filter;
  final List<AISticker> stickers;

  AISuggestion({
    required this.topText,
    required this.bottomText,
    required this.filter,
    required this.stickers,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      topText: json['topText'] ?? '',
      bottomText: json['bottomText'] ?? '',
      filter: json['filter'] ?? 'Normal',
      stickers: (json['stickers'] as List? ?? [])
          .map((s) => AISticker.fromJson(s))
          .toList(),
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
          Suggest:
          1. A witty top caption and bottom caption.
          2. A recommended filter from this list: [Normal, Grayscale, Sepia, Cool Blue].
          3. 1-2 emojis to place as stickers, including suggested coordinates (x and y from 0.0 to 1.0).
          
          Return ONLY a JSON object in this format:
          {
            "topText": "CAPTION HERE",
            "bottomText": "CAPTION HERE",
            "filter": "Normal",
            "stickers": [
              {"emoji": "😂", "x": 0.5, "y": 0.5}
            ]
          }
          Make the captions relevant to the image content. Use Uppercase for captions.
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
