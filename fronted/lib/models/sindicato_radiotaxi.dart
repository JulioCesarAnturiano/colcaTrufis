// lib/models/sindicato_radiotaxi.dart
class SindicatoRadiotaxi {
  final int id;
  final String nombreComercial;
  final String telefonoBase;
  
  SindicatoRadiotaxi({
    required this.id,
    required this.nombreComercial,
    required this.telefonoBase,
  });
  
  factory SindicatoRadiotaxi.fromJson(Map<String, dynamic> json) {
    return SindicatoRadiotaxi(
      id: int.parse(json['id'].toString()),
      nombreComercial: json['nombre_comercial'] ?? '',
      telefonoBase: json['telefono_base'] ?? '',
    );
  }
}