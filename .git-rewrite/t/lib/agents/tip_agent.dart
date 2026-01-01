import 'package:google_generative_ai/google_generative_ai.dart';

class TipAgent {
  final GenerativeModel _flashModel;
  final GenerativeModel _proModel;

  TipAgent(String apiKey)
      : _flashModel = GenerativeModel(
          model: 'gemini-3-flash-preview',
          apiKey: apiKey,
        ),
        _proModel = GenerativeModel(
          model: 'gemini-3-pro-preview',
          apiKey: apiKey,
        );

  /// Quick chat with the assistant about income/history
  Future<String> chat(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await _flashModel.generateContent(content);
      return response.text ?? "I'm having trouble understanding that.";
    } catch (e) {
      return "Error communicating with AI: $e";
    }
  }

  /// Analyze an image (BEO, Paycheck, Receipt) and extract data
  Future<String> analyzeImage(List<int> imageBytes, String prompt) async {
    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(
              'image/jpeg',
              imageBytes
                  as dynamic), // Cast might need adjustment based on actual Uint8List
        ])
      ];

      final response = await _proModel.generateContent(content);
      return response.text ?? "Could not analyze image.";
    } catch (e) {
      return "Error analyzing image: $e";
    }
  }
}
