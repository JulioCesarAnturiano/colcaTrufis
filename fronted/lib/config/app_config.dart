class AppConfig {
  // Cambia esta URL según tu entorno:
  // Local:      "http://localhost:8000/api"
  // Producción: "https://moviruta.colcapirhua.gob.bo/api"
  static const String baseUrl = "https://moviruta.colcapirhua.gob.bo/api";

  /// Timeout para APIs pesadas (ubicaciones, referencias)
  static const int heavyApiTimeoutSeconds = 45;

  /// Timeout para APIs ligeras
  static const int normalApiTimeoutSeconds = 15;
}
