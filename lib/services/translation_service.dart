import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  // Update this URL to match your backend server
  // For Android emulator: use 'http://10.0.2.2:8000'
  // For iOS simulator: use 'http://localhost:8000'
  // For physical device: use your computer's local IP (e.g., 'http://192.168.1.100:8000')
  static const String baseUrl = 'http://localhost:8000';
  
  // Cache for translations to avoid repeated API calls
  final Map<String, String> _translationCache = {};
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  /// Translate a single text from English to Hindi
  Future<String> translateText(String text) async {
    if (text.trim().isEmpty) return text;
    
    // Check cache first
    if (_translationCache.containsKey(text)) {
      return _translationCache[text]!;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/translate_one'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translation = data['translation'] as String;
        
        // Cache the translation
        _translationCache[text] = translation;
        await _saveCacheToPrefs();
        
        return translation;
      } else {
        print('Translation API error: ${response.statusCode} - ${response.body}');
        return text; // Return original text on error
      }
    } catch (e) {
      print('Translation service error: $e');
      return text; // Return original text on error
    }
  }

  /// Translate multiple texts at once (more efficient)
  Future<Map<String, String>> translateBatch(List<String> texts) async {
    // Filter out empty texts and already cached ones
    final textsToTranslate = <String>[];
    final result = <String, String>{};
    
    for (final text in texts) {
      if (text.trim().isEmpty) {
        result[text] = text;
        continue;
      }
      
      if (_translationCache.containsKey(text)) {
        result[text] = _translationCache[text]!;
      } else {
        textsToTranslate.add(text);
      }
    }

    if (textsToTranslate.isEmpty) return result;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'texts': textsToTranslate}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translations = List<String>.from(data['translations']);
        
        // Cache translations and add to result
        for (int i = 0; i < textsToTranslate.length; i++) {
          final original = textsToTranslate[i];
          final translated = i < translations.length ? translations[i] : original;
          _translationCache[original] = translated;
          result[original] = translated;
        }
        
        await _saveCacheToPrefs();
      } else {
        print('Translation API error: ${response.statusCode} - ${response.body}');
        // Return original texts on error
        for (final text in textsToTranslate) {
          result[text] = text;
        }
      }
    } catch (e) {
      print('Translation service error: $e');
      // Return original texts on error
      for (final text in textsToTranslate) {
        result[text] = text;
      }
    }

    return result;
  }

  /// Clear translation cache
  void clearCache() {
    _translationCache.clear();
    _clearCacheFromPrefs();
  }

  /// Get a copy of the translation cache (for syncing with AppLocalizations)
  Map<String, String> getCache() {
    return Map<String, String>.from(_translationCache);
  }

  /// Save cache to SharedPreferences for persistence
  Future<void> _saveCacheToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('translation_cache', jsonEncode(_translationCache));
    } catch (e) {
      print('Error saving translation cache: $e');
    }
  }

  /// Load cache from SharedPreferences
  Future<void> loadCacheFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString('translation_cache');
      if (cacheJson != null) {
        final cache = Map<String, dynamic>.from(jsonDecode(cacheJson));
        _translationCache.addAll(Map<String, String>.from(cache));
      }
    } catch (e) {
      print('Error loading translation cache: $e');
    }
  }

  /// Clear cache from SharedPreferences
  Future<void> _clearCacheFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('translation_cache');
    } catch (e) {
      print('Error clearing translation cache: $e');
    }
  }

  /// Check if backend is available
  Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

