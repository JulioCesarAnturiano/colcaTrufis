// lib/models/sindicato.dart
class Sindicato {
  final int id;
  final String nombre;
  final String? descripcion;
  
  Sindicato({
    required this.id,
    required this.nombre,
    this.descripcion,
  });
  
  factory Sindicato.fromJson(Map<String, dynamic> json) {
    return Sindicato(
      id: int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
    );
  }
}