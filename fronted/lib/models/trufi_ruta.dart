// lib/models/trufi_ruta.dart
import 'package:latlong2/latlong.dart';
class TrufiRuta {
  final int idtrufi;
  final int? sindicatoRadiotaxiId;
  final double latitud;
  final double longitud;
  final int orden;
  final bool puntos;
  final bool esParada;
  final bool estado;
  
  TrufiRuta({
    required this.idtrufi,
    this.sindicatoRadiotaxiId,
    required this.latitud,
    required this.longitud,
    required this.orden,
    required this.puntos,
    required this.esParada,
    required this.estado,
  });
  
  factory TrufiRuta.fromJson(Map<String, dynamic> json) {
    return TrufiRuta(
      idtrufi: int.parse(json['idtrufi'].toString()),
      sindicatoRadiotaxiId: json['sindicato_radiotaxi_id'] != null 
          ? int.parse(json['sindicato_radiotaxi_id'].toString())
          : null,
      latitud: double.parse(json['latitud'].toString()),
      longitud: double.parse(json['longitud'].toString()),
      orden: int.parse(json['orden'].toString()),
      puntos: json['puntos'] == 1 || json['puntos'] == true,
      esParada: json['es_parada'] == 1 || json['es_parada'] == true,
      estado: json['estado'] == 1 || json['estado'] == true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'idtrufi': idtrufi,
      'sindicato_radiotaxi_id': sindicatoRadiotaxiId,
      'latitud': latitud,
      'longitud': longitud,
      'orden': orden,
      'puntos': puntos,
      'es_parada': esParada,
      'estado': estado,
    };
  }
  
  LatLng toLatLng() {
    return LatLng(latitud, longitud);
  }
  
  bool get isRadiotaxi => sindicatoRadiotaxiId != null;
}