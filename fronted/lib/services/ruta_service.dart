// lib/services/ruta_service.dart
import 'package:colcatrufis/fronted/lib/models/ruta_trufi.dart';
import 'api_service.dart';

class RutaService {
  static Future<List<RutaTrufi>> getRutas() async {
    final response = await ApiService.get('api/trufi-rutas');
    
    if (response is List) {
      return response.map((json) => RutaTrufi.fromJson(json)).toList();
    } else if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        return data.map((json) => RutaTrufi.fromJson(json)).toList();
      }
    }
    
    throw Exception('Formato de respuesta inválido');
  }

  static Future<List<RutaTrufi>> getRutasPorTrufi(int idTrufi) async {
    final response = await ApiService.get('api/trufis/$idTrufi/rutas');
    
    if (response is List) {
      return response.map((json) => RutaTrufi.fromJson(json)).toList();
    } else if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        return data.map((json) => RutaTrufi.fromJson(json)).toList();
      }
    }
    
    throw Exception('Formato de respuesta inválido');
  }
}