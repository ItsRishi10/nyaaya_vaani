import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  // Cache for translations to avoid repeated translations
  final Map<String, String> _translationCache = {};
  // Manual overrides for specific phrases where ML translation isn't ideal
  // Key: English text, Value: Preferred Hindi translation
  final Map<String, String> _manualOverrides = {
    'Nyaaya Vaani': 'न्याय वाणी',
  };
  
  // ML Kit translator instance
  OnDeviceTranslator? _translator;
  bool _isInitialized = false;
  bool _isInitializing = false;

  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  /// Initialize the offline translator (downloads model on first use)
  Future<void> _ensureTranslator() async {
    if (_isInitialized && _translator != null) {
      return;
    }

    // Prevent multiple simultaneous initializations with better timeout
    if (_isInitializing) {
      // Wait and check multiple times with timeout
      for (int i = 0; i < 50; i++) { // Max 5 seconds wait
        await Future.delayed(const Duration(milliseconds: 100));
        if (_isInitialized && _translator != null) {
          return;
        }
        if (!_isInitializing) {
          // Another initialization completed/failed, try again
          break;
        }
      }
      // If still initializing after timeout, reset and try again
      if (_isInitializing) {
        print('Warning: Initialization timeout, resetting...');
        _isInitializing = false;
      }
    }

    _isInitializing = true;

    try {
      print('Initializing translator...');
      // Create translator for English to Hindi
      final modelManager = OnDeviceTranslatorModelManager();
      final sourceLanguage = TranslateLanguage.english;
      final targetLanguage = TranslateLanguage.hindi;

      // Check if source language model is downloaded, if not download it
      final isSourceDownloaded = await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
      if (!isSourceDownloaded) {
        print('Downloading source language model (English)...');
        await modelManager.downloadModel(sourceLanguage.bcpCode).timeout(
          const Duration(minutes: 10),
          onTimeout: () {
            throw TimeoutException('Source model download timed out');
          },
        );
        print('Source language model downloaded successfully!');
      }

      // Check if target language model is downloaded, if not download it
      final isTargetDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);
      if (!isTargetDownloaded) {
        print('Downloading target language model (Hindi)... This may take a few minutes on first use.');
        await modelManager.downloadModel(targetLanguage.bcpCode).timeout(
          const Duration(minutes: 15),
          onTimeout: () {
            throw TimeoutException('Target model download timed out');
          },
        );
        print('Target language model downloaded successfully!');
      }

      // Create the translator
      _translator = OnDeviceTranslator(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      _isInitialized = true;
      _isInitializing = false;
      print('Translator initialized successfully');
    } catch (e) {
      _isInitializing = false;
      _isInitialized = false;
      _translator = null;
      print('Error initializing translator: $e');
      throw Exception('Failed to initialize offline translator: $e');
    }
  }

  /// Translate a single text from English to Hindi
  Future<String> translateText(String text) async {
    if (text.trim().isEmpty) return text;
    
    // Respect manual overrides first
    if (_manualOverrides.containsKey(text)) {
      final overridden = _manualOverrides[text]!;
      _translationCache[text] = overridden; // cache it
      await _saveCacheToPrefs();
      return overridden;
    }

    // Check cache first
    if (_translationCache.containsKey(text)) {
      return _translationCache[text]!;
    }

    try {
      // Ensure translator is initialized
      await _ensureTranslator();

      if (_translator == null) {
        throw Exception('Translator not initialized');
      }

      // Translate using ML Kit
      final translatedText = await _translator!.translateText(text);
      
      // Cache the translation
      _translationCache[text] = translatedText;
      await _saveCacheToPrefs();
      
      return translatedText;
    } catch (e) {
      print('Translation error: $e');
      // Return original text on error but don't throw
      // This allows the app to continue working even if translation fails
      return text;
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
      // Apply manual overrides and skip translation for those
      if (_manualOverrides.containsKey(text)) {
        final overridden = _manualOverrides[text]!;
        _translationCache[text] = overridden;
        result[text] = overridden;
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
      // Ensure translator is initialized
      await _ensureTranslator();

      if (_translator == null) {
        throw Exception('Translator not initialized');
      }

      // Translate each text (ML Kit doesn't support batch, but we can do it sequentially)
      for (final text in textsToTranslate) {
        try {
          final translated = await _translator!.translateText(text).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('Translation timeout for: "$text"');
              return text; // Return original on timeout
            },
          );
          _translationCache[text] = translated;
          result[text] = translated;
          print('Translated: "$text" -> "$translated"'); // Debug log
        } catch (e) {
          print('Error translating "$text": $e');
          // Use original text if translation fails
          result[text] = text;
          _translationCache[text] = text;
        }
      }
      
      await _saveCacheToPrefs();
    } catch (e) {
      print('Batch translation error: $e');
      // Return original texts on error
      for (final text in textsToTranslate) {
        if (!result.containsKey(text)) {
          result[text] = text;
        }
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

  /// Dispose translator resources
  Future<void> dispose() async {
    await _translator?.close();
    _translator = null;
    _isInitialized = false;
  }
}

