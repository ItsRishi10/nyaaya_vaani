import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TranslationService {
  // ===== CONFIGURATION FOR PHYSICAL ANDROID DEVICE =====
  // If you're using a physical Android device (not emulator), 
  // set this to your computer's local IP address.
  // Leave as null to auto-detect (uses 10.0.2.2 for emulator, localhost for other platforms)
  // 
  // To find your computer's IP on Windows:
  //   1. Open PowerShell
  //   2. Run: ipconfig
  //   3. Look for "IPv4 Address" under your active network adapter (usually Wi-Fi or Ethernet)
  //   4. It will look like: 192.168.1.xxx or 192.168.0.xxx
  //
  // Example: '192.168.1.100'
  static const String? physicalDeviceIp = '192.168.1.9'; // Change this to your IP if using physical device
  
  // Automatically detect the correct base URL based on platform
  static String get baseUrl {
    // If physical device IP is configured, use it for Android
    if (Platform.isAndroid && physicalDeviceIp != null && physicalDeviceIp!.isNotEmpty) {
      return 'http://$physicalDeviceIp:8000';
    }
    
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    
    // Default fallback
    return 'http://localhost:8000';
  }
  
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
    } on SocketException catch (e) {
      print('Translation service error: Connection refused. Is the backend server running at $baseUrl?');
      print('Error details: $e');
      // Re-throw to let caller know connection failed
      throw Exception('Translation server is not available. Please start the backend server.');
    } catch (e) {
      print('Translation service error: $e');
      // Re-throw other exceptions too
      throw Exception('Translation failed: $e');
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
    } on SocketException catch (e) {
      print('Translation service error: Connection refused. Is the backend server running at $baseUrl?');
      print('Error details: $e');
      // Return original texts on error, but throw to notify caller
      for (final text in textsToTranslate) {
        result[text] = text;
      }
      throw Exception('Translation server is not available. Please start the backend server.');
    } catch (e) {
      print('Translation service error: $e');
      // Return original texts on error
      for (final text in textsToTranslate) {
        result[text] = text;
      }
      // Re-throw to notify caller
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Translation failed: $e');
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

