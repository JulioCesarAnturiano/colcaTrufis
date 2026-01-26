// lib/services/trufi_service.dart
import 'package:colcatrufis/models/trufi.dart';
import 'api_service.dart';

class TrufiService {
  static const String endpoint = 'api/trufis';

  static Future<List<Trufi>> getTrufis() async {
    try {
      print('Obteniendo trufis...');
      final response = await ApiService.get(endpoint);
      print('Respuesta completa: $response');
      
      if (response is List) {
        final trufis = response.map((json) => Trufi.fromJson(json)).toList();
        print('Trufis parseados: ${trufis.length}');
        return trufis;
      } else if (response is Map && response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          final trufis = data.map((json) => Trufi.fromJson(json)).toList();
          print('Trufis parseados desde data: ${trufis.length}');
          return trufis;
        }
      }
      
      throw Exception('Formato de respuesta inválido: $response');
    } catch (e) {
      print('Error en getTrufis: $e');
      rethrow;
    }
  }

  static Future<Trufi> getTrufiById(int id) async {
    final response = await ApiService.get('$endpoint/$id');
    return Trufi.fromJson(response);
  }

  static Future<List<Trufi>> getTrufisDisponibles() async {
    final trufis = await getTrufis();
    return trufis.where((trufi) => trufi.estado).toList();
  }
}