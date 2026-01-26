// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // IMPORTANTE: Cambia esto por tu URL real
  static const String baseUrl = 'http://localhost:8000';
  
  // Headers para Laravel Sanctum (si usas autenticación)
  static Future<Map<String, String>> get headers async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      // Si usas Sanctum, necesitarás el CSRF token
    };
  }

  static Future<String> _getCsrfToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sanctum/csrf-cookie'),
        credentials: true,
      );
      // Extraer el token de las cookies
      final cookies = response.headers['set-cookie'];
      final match = RegExp(r'XSRF-TOKEN=([^;]+)').firstMatch(cookies ?? '');
      return match?.group(1) ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<Map<String, String>> getHeadersWithAuth() async {
    final headers = await headers;
    final csrfToken = await _getCsrfToken();
    
    if (csrfToken.isNotEmpty) {
      headers['X-XSRF-TOKEN'] = csrfToken;
    }
    
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      print('GET: $baseUrl/$endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await getHeadersWithAuth(),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('Error en GET: $e');
      throw Exception('Error en GET: $e');
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      print('POST: $baseUrl/$endpoint');
      print('Data: $data');
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await getHeadersWithAuth(),
        body: jsonEncode(data),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('Error en POST: $e');
      throw Exception('Error en POST: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    print('Handling response: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('Error parsing JSON: $e');
        return response.body;
      }
    } else if (response.statusCode == 401) {
      throw Exception('No autorizado. Por favor inicie sesión.');
    } else if (response.statusCode == 404) {
      throw Exception('Recurso no encontrado');
    } else {
      print('Error response body: ${response.body}');
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}