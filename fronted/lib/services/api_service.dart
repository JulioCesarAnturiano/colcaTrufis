import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> _get(String path) async {
    try {
      final res = await http
          .get(
            _u(path),
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final body = jsonDecode(res.body);

      // Soporta:
      // 1) [ ... ]
      // 2) { "data": [ ... ] }
      // 3) { "success": true, "data": [ ... ] }

      if (body is List) return body;
      if (body is Map && body['data'] is List) return body['data'];
      if (body is Map && body['success'] == true && body['data'] is List) {
        return body['data'];
      }
      return body; // En caso de que el formato sea inesperado
    } catch (e) {
      throw Exception('Error al obtener datos: $e');
    }
  }

  // =========================
  // ENDPOINTS (según tu api.php)
  // =========================

  Future<List<dynamic>> getSindicatos() async {
    final data = await _get('/sindicatos');
    return (data as List).cast<dynamic>();
  }

  Future<List<dynamic>> getRadioTaxis() async {
    final data = await _get('/sindicato-radiotaxis');
    return (data as List).cast<dynamic>();
  }

  Future<List<dynamic>> getTrufis() async {
    final data = await _get('/trufis');
    return (data as List).cast<dynamic>();
  }

  Future<List<dynamic>> getTrufiRutas(int idtrufi) async {
    final data = await _get('/trufis/$idtrufi/rutas');
    return (data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> getGeoJsonPorTrufi(int idtrufi) async {
    final data = await _get('/trufis/$idtrufi/rutas/geojson');
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Formato inesperado para GeoJSON');
  }
  Future<Map<String, dynamic>> getGeoJsonTodasRutas() async {
    final data = await _get('/trufis/rutas/geojson');
    if (data is Map<String, dynamic>) return data;
    throw Exception('Formato inesperado para GeoJSON Todas Rutas');
  }

  // Referencias
  Future<List<dynamic>> getReferencias() async {
    final data = await _get('/referencias');
    print("🔍 getReferencias() retornó: $data (tipo: ${data.runtimeType})");
    if (data is List) return data;
    print("⚠️ Esperaba List, recibí ${data.runtimeType}");
    return [];
  }

  Future<List<dynamic>> getReferenciasDestrufi(int idTrufi) async {
    final data = await _get('/trufis/$idTrufi/referencias');
    print("🔍 getReferenciasDestrufi($idTrufi) retornó: $data (tipo: ${data.runtimeType})");
    
    // Si es paginación Laravel con 'data' adentro
    if (data is Map && data['data'] is List) {
      final referencias = data['data'] as List;
      print("✅ Referencias extraídas del JSON paginado: ${referencias.length}");
      return referencias;
    }
    
    // Si es directo List
    if (data is List) return data;
    
    print("⚠️ Esperaba List o Map con 'data', recibí ${data.runtimeType}");
    return [];
  }

  Future<List<dynamic>> getReferenciasDeRadiotaxi(int idRadiotaxi) async {
    final data = await _get('/radiotaxis/$idRadiotaxi/referencias');
    print("🔍 getReferenciasDeRadiotaxi($idRadiotaxi) retornó: $data (tipo: ${data.runtimeType})");
    
    // Si es paginación Laravel con 'data' adentro
    if (data is Map && data['data'] is List) {
      final referencias = data['data'] as List;
      print("✅ Referencias extraídas del JSON paginado: ${referencias.length}");
      return referencias;
    }
    
    // Si es directo List
    if (data is List) return data;
    
    print("⚠️ Esperaba List o Map con 'data', recibí ${data.runtimeType}");
    return [];
  }

  // Ubicaciones
  Future<List<dynamic>> getUbicacionesPorTrufi(int idTrufi) async {
    final data = await _get('/trufis/$idTrufi/ubicaciones');
    print("🔍 getUbicacionesPorTrufi($idTrufi) retornó: $data (tipo: ${data.runtimeType})");
    if (data is List) return data;
    print("⚠️ Esperaba List, recibí ${data.runtimeType}");
    return [];
  }

  Future<List<dynamic>> getUbicacionesTodas() async {
    final data = await _get('/ubicaciones');
    print("🔍 getUbicacionesTodas() retornó: $data (tipo: ${data.runtimeType})");
    if (data is List) return data;
    print("⚠️ Esperaba List, recibí ${data.runtimeType}");
    return [];
  }

}
