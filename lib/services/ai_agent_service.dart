import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Agent Service - Communicates with the ai-agent edge function
/// This service handles all function calling - the AI can perform actions!
class AIAgentService {
  AIAgentService();

  /// Send a message to the AI agent
  /// The AI will analyze the message and execute any necessary functions
  Future<Map<String, dynamic>> sendMessage(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      debugPrint('[AI Agent] Sending message: $message');

      // Check if user is logged in
      final session = Supabase.instance.client.auth.currentSession;
      debugPrint('[AI Agent] User session exists: ${session != null}');
      if (session != null) {
        debugPrint('[AI Agent] User ID: ${session.user.id}');
        debugPrint(
            '[AI Agent] Access token length: ${session.accessToken.length}');
        debugPrint(
            '[AI Agent] Token type: ${session.accessToken.split('.').length} parts');
      } else {
        debugPrint('[AI Agent] WARNING: No user session found!');
      }

      // Get the user's local timezone info
      final now = DateTime.now();
      final timeZoneOffset = now.timeZoneOffset.inMinutes;
      final timeZoneName = now.timeZoneName;
      // Also send the user's current local date in YYYY-MM-DD format
      final localDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      debugPrint(
          '[AI Agent] User timezone: $timeZoneName (offset: $timeZoneOffset minutes)');
      debugPrint('[AI Agent] User local date: $localDate');

      // Use the Supabase client SDK to invoke the function
      // This automatically handles authentication headers (Authorization and apikey)
      final response = await Supabase.instance.client.functions.invoke(
        'ai-agent',
        body: {
          'message': message,
          'history': history,
          'timeZoneOffset': timeZoneOffset,
          'timeZoneName': timeZoneName,
          'localDate': localDate,
        },
      );

      debugPrint('[AI Agent] Response status: ${response.status}');
      debugPrint('[AI Agent] Raw response data: ${response.data}');

      // Check for success status (200-299)
      if (response.status >= 200 && response.status < 300) {
        final data = response.data;
        debugPrint(
            '[AI Agent] Functions executed: ${data['functionsExecuted']}');

        return {
          'success': true,
          'reply': data['reply'],
          'functionsExecuted': data['functionsExecuted'] ?? 0,
          'debugInfo': data['debugInfo'],
        };
      } else {
        // Handle non-success status codes
        debugPrint('[AI Agent] Error status: ${response.status}');
        // Try to parse error message from body if available
        String errorMessage = 'AI agent request failed';
        if (response.data is Map && response.data['error'] != null) {
          errorMessage = response.data['error'];
        }
        debugPrint('[AI Agent] ERROR MESSAGE: $errorMessage');
        throw Exception(errorMessage);
      }
    } on FunctionException catch (e) {
      // Supabase SDK specific exception for function errors
      debugPrint('[AI Agent] Function Error: ${e.details}');
      debugPrint('[AI Agent] Status: ${e.status}');
      debugPrint('[AI Agent] Full Exception: $e');

      // Try to extract error message from details
      String errorMessage = 'AI agent request failed';
      if (e.details is Map && e.details['error'] != null) {
        errorMessage = e.details['error'].toString();
      } else if (e.details is String) {
        errorMessage = e.details;
      } else {
        errorMessage = e.details.toString();
      }

      debugPrint('[AI Agent] FINAL ERROR: $errorMessage');
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('[AI Agent] Exception: $e');
      debugPrint('[AI Agent] Exception type: ${e.runtimeType}');
      debugPrint('[AI Agent] Exception toString: ${e.toString()}');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Clear chat history
  Future<void> clearHistory() async {
    // TODO: If we store chat history in database, clear it here
    debugPrint('[AI Agent] Chat history cleared (local)');
  }
}
