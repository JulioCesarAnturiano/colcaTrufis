import 'dart:io';

class AppConfig {
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');

  // URLs base
  static const String _devBaseUrl = "http://10.0.2.2:8000/api"; // Para emulador Android
  static const String _prodBaseUrl = "https://moviruta.colcapirhua.gob.bo/api";

  /// Obtiene la URL base según el entorno
  static String get baseUrl {
    // En producción (APK), siempre usar HTTPS
    if (_isProduction) {
      return _prodBaseUrl;
    }

    // En desarrollo, detectar si es emulador o dispositivo físico
    if (Platform.isAndroid) {
      return _devBaseUrl; // 10.0.2.2 for Android emulator
    }

    return _prodBaseUrl; // Fallback
  }

  /// Configuración para debugging
  static bool get isDebugMode => !_isProduction;

  /// Timeout para APIs pesadas (ubicaciones, referencias)
  static const int heavyApiTimeoutSeconds = 45;

  /// Timeout para APIs ligeras
  static const int normalApiTimeoutSeconds = 15;

  static void printConfig() {
    print("🔧 AppConfig:");
    print("   - Producción: $_isProduction");
    print("   - Base URL: $baseUrl");
    print("   - Platform: ${Platform.operatingSystem}");
    print("   - Debug: $isDebugMode");
  }
}