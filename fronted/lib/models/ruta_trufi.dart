// lib/models/ruta_trufi.dart
class RutaTrufi {
  final int id;
  final int idtrufi;
  final double latitud;
  final double longitud;
  final int orden;
  final bool esParada;
  final bool estado;

  RutaTrufi({
    required this.id,
    required this.idtrufi,
    required this.latitud,
    required this.longitud,
    required this.orden,
    required this.esParada,
    required this.estado,
  });

  factory RutaTrufi.fromJson(Map<String, dynamic> json) {
    return RutaTrufi(
      id: int.parse(json['id'].toString()),
      idtrufi: int.parse(json['idtrufi'].toString()),
      latitud: double.parse(json['latitud'].toString()),
      longitud: double.parse(json['longitud'].toString()),
      orden: int.parse(json['orden'].toString()),
      esParada: json['es_parada'] == 1,
      estado: json['estado'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idtrufi': idtrufi,
      'latitud': latitud,
      'longitud': longitud,
      'orden': orden,
      'es_parada': esParada ? 1 : 0,
      'estado': estado ? 1 : 0,
    };
  }
}