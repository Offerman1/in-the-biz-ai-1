import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Service to communicate with your Supabase backend
/// This keeps your Gemini API key secure on the server
class ApiService {
  // Supabase Project URL
  static const String _baseUrl =
      'https://bokdjidrybwxbomemmrg.supabase.co/functions/v1';

  // Supabase Anon Key
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJva2RqaWRyeWJ3eGJvbWVtbXJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2Mjc1MzcsImV4cCI6MjA4MjIwMzUzN30.SVdK-fKrQklp76pGozuaDyNsgp2vkwWfNYtdmDRjChs';

  /// Analyze an image (BEO, receipt, paycheck) using AI
  /// Returns extracted financial data
  static Future<Map<String, dynamic>> analyzeImage(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({
          'image': base64Image,
          'mimeType': 'image/jpeg',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['error'] ?? 'Analysis failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  /// Send a chat message to the AI assistant
  /// Returns the AI's response
  /// Optionally include context (user's shift data) for personalized responses
  static Future<String> chat(
    String message, {
    List<Map<String, String>>? history,
    String? context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({
          'message': message,
          'history': history ?? [],
          'context': context ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['reply'] as String;
        } else {
          throw Exception(data['error'] ?? 'Chat failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Analyze CSV/Excel import data using AI
  /// Returns smart column mappings and unmapped field insights
  static Future<Map<String, dynamic>> analyzeImport({
    required List<String> headers,
    required List<Map<String, dynamic>> sampleRows,
    String? preSelectedJobId,
    List<Map<String, dynamic>>? existingJobs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-import'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({
          'headers': headers,
          'sampleRows': sampleRows,
          'preSelectedJobId': preSelectedJobId,
          'existingJobs': existingJobs
              ?.map((j) => {
                    'id': j['id'],
                    'title': j['title'],
                  })
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['analysis'] as Map<String, dynamic>;
        } else {
          throw Exception(data['error'] ?? 'Import analysis failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze import: $e');
    }
  }
}
