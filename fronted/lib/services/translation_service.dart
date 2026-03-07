import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Translates Spanish strings to other languages using the MyMemory free API.
/// Results are cached in SharedPreferences so API is called only once per language.
class TranslationService {
  // Cache keys per language
  static const String _prefKeyEn = 'colcatrufi_transl_en_v2';
  static const String _prefKeyQu = 'colcatrufi_transl_qu_v2';

  // In-memory caches: translationKey → translated text
  static Map<String, String> _enCache = {};
  static Map<String, String> _quCache = {};
  static bool _loaded = false;

  /// Load all cached translations from SharedPreferences.
  static Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawEn = prefs.getString(_prefKeyEn);
      if (rawEn != null) {
        final decoded = jsonDecode(rawEn) as Map<String, dynamic>;
        _enCache = decoded.map((k, v) => MapEntry(k, v as String));
      }
      final rawQu = prefs.getString(_prefKeyQu);
      if (rawQu != null) {
        final decoded = jsonDecode(rawQu) as Map<String, dynamic>;
        _quCache = decoded.map((k, v) => MapEntry(k, v as String));
      }
    } catch (_) {}
  }

  /// Whether cached translations exist for [lang].
  static bool hasCache(String lang) {
    if (lang == 'en') return _enCache.isNotEmpty;
    if (lang == 'qu') return _quCache.isNotEmpty;
    return false;
  }

  /// Get the cached translation for [key] in [lang], falling back to [fallback].
  static String get(String lang, String key, String fallback) {
    if (lang == 'en') return _enCache[key] ?? fallback;
    if (lang == 'qu') return _quCache[key] ?? fallback;
    return fallback;
  }

  /// Fetch translations for [lang] given a map of key→spanishText.
  /// Uses MyMemory API (es→[lang]). No-op if already cached.
  /// Returns true if new translations were fetched.
  static Future<bool> fetchTranslations(String lang, Map<String, String> spanishMap) async {
    // Skip if already cached
    if (lang == 'en' && _enCache.isNotEmpty) return false;
    if (lang == 'qu' && _quCache.isNotEmpty) return false;
    if (lang == 'es') return false;

    final langCode = lang == 'qu' ? 'qu' : lang;
    final result = <String, String>{};

    // Parallel requests in chunks of 8
    final entries = spanishMap.entries.toList();
    const chunkSize = 8;
    for (int i = 0; i < entries.length; i += chunkSize) {
      final chunk = entries.skip(i).take(chunkSize);
      await Future.wait(chunk.map((e) async {
        final translated = await _translateOne(e.value, langCode);
        result[e.key] = translated ?? e.value;
      }));
      if (i + chunkSize < entries.length) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    if (lang == 'en') {
      _enCache = result;
    } else if (lang == 'qu') {
      _quCache = result;
    }
    await _persist(lang);
    return true;
  }

  static Future<String?> _translateOne(String text, String targetLang) async {
    try {
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}'
        '&langpair=es|$targetLang',
      );
      final resp = await http.get(url, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final translated = data['responseData']?['translatedText'] as String?;
        if (translated != null && translated.trim().isNotEmpty) {
          return translated;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _persist(String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (lang == 'en') {
        await prefs.setString(_prefKeyEn, jsonEncode(_enCache));
      } else if (lang == 'qu') {
        await prefs.setString(_prefKeyQu, jsonEncode(_quCache));
      }
    } catch (_) {}
  }

  /// Clear all cached translations.
  static Future<void> clearCache() async {
    _enCache = {};
    _quCache = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyEn);
      await prefs.remove(_prefKeyQu);
    } catch (_) {}
  }
}
