// lib/models/trufi.dart
class Trufi {
  final int idtrufi;
  final String nomLinea;
  final double costo;
  final int frecuencia;
  final String tipo;
  final String? descripcion;
  final String nombreSindicato;
  final bool estado;

  Trufi({
    required this.idtrufi,
    required this.nomLinea,
    required this.costo,
    required this.frecuencia,
    required this.tipo,
    this.descripcion,
    required this.nombreSindicato,
    required this.estado,
  });

  factory Trufi.fromJson(Map<String, dynamic> json) {
    return Trufi(
      idtrufi: int.parse(json['idtrufi'].toString()),
      nomLinea: json['nombre'] ?? json['nom_linea'] ?? '',
      costo: double.parse(json['costo'].toString()),
      frecuencia: int.parse(json['frecuencia'].toString()),
      tipo: json['tipo'] ?? '',
      descripcion: json['descripcion'],
      nombreSindicato: json['nombre_sindicato'] ?? '',
      estado: json['estado'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idtrufi': idtrufi,
      'nombre': nomLinea,
      'costo': costo,
      'frecuencia': frecuencia,
      'tipo': tipo,
      'descripcion': descripcion,
      'nombre_sindicato': nombreSindicato,
      'estado': estado ? 1 : 0,
    };
  }
}