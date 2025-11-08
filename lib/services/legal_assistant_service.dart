import 'dart:convert';
import 'package:http/http.dart' as http;

class LegalAssistantService {
  // Backend URL - adjust based on your setup
  // For Android emulator: http://10.0.2.2:8001
  // For iOS simulator: http://localhost:8001
  // For physical device: Use your computer's local IP (e.g., http://192.168.1.100:8001)
  static const String baseUrl = 'http://10.0.2.2:8001';
  
  /// Send a legal question to the AI assistant
  /// Returns the assistant's response
  static Future<String> askLegalQuestion(String question, {String? context}) async {
    try {
      final url = Uri.parse('$baseUrl/legal-query-simple');
      
      final body = jsonEncode({
        'question': question,
        if (context != null) 'context': context,
      });
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 60), // Legal queries might take longer
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'I apologize, but I could not generate a response.';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get response from legal assistant');
      }
    } catch (e) {
      print('Error calling legal assistant: $e');
      // Return a helpful error message
      if (e.toString().contains('timeout')) {
        return 'The request took too long. Please try again with a shorter question.';
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        return 'Unable to connect to the legal assistant service. Please ensure the backend is running on port 8001.';
      } else {
        return 'An error occurred: ${e.toString()}. Please try again.';
      }
    }
  }
  
  /// Check if the legal assistant service is available
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

