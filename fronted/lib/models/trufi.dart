// lib/models/trufi.dart
class Trufi {
  final int idtrufi;
  final String nomLinea;
  final double costo;
  final int frecuencia;
  final String? descripcion;
  final bool estado;
  final int? sindicatoId;
  
  Trufi({
    required this.idtrufi,
    required this.nomLinea,
    required this.costo,
    required this.frecuencia,
    this.descripcion,
    required this.estado,
    this.sindicatoId,
  });
  
  factory Trufi.fromJson(Map<String, dynamic> json) {
    return Trufi(
      idtrufi: json['idtrufi'],
      nomLinea: json['nom_linea'],
      costo: double.parse(json['costo'].toString()),
      frecuencia: json['frecuencia'],
      descripcion: json['descripcion'],
      estado: json['estado'] == 1,
      sindicatoId: json['sindicato_id'],
    );
  }
}
