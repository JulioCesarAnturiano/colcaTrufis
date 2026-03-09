import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';

const Color kPrimary = Color(0xFF09596E);
const Color kPrimaryDark = Color(0xFF064656);

const Color kAqua = Color(0xFF19B7B0);

class AppSettings {
  static final ValueNotifier<String> language = ValueNotifier<String>("es");
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);

  static final ValueNotifier<String> centerMode = ValueNotifier<String>("colcapirhua");

  static final ValueNotifier<double> radiusMeters = ValueNotifier<double>(250.0);
}

enum RouteFilterMode { nearby, all }

class HistorialItem {
  final int id;
  final String nombre;
  final String tipo;
  final String? telefono;
  final DateTime fechaUso;

  HistorialItem({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.telefono,
    required this.fechaUso,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'telefono': telefono,
        'fechaUso': fechaUso.toIso8601String(),
      };

  factory HistorialItem.fromJson(Map<String, dynamic> json) => HistorialItem(
        id: json['id'],
        nombre: json['nombre'],
        tipo: json['tipo'],
        telefono: json['telefono'],
        fechaUso: DateTime.parse(json['fechaUso']),
      );
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isTrufiSelected = true;
  final MapController _mapController = MapController();

  final ApiService _apiService = ApiService(baseUrl: "https://moviruta.colcapirhua.gob.bo/api");

  static const String _apiBase = "https://moviruta.colcapirhua.gob.bo/api";

  Position? _currentPosition;

  List<Map<String, dynamic>> _sindicatos = [];
  List<Map<String, dynamic>> _radioTaxis = [];
  List<Map<String, dynamic>> _trufis = [];

  List<Map<String, dynamic>> _paradasRadiotaxis = [];

  List<Polygon> colcapirhuaPolygons = [];
  List<Polyline> colcapirhuaLines = [];

  List<Polyline> _todasRutas = [];
  List<Polyline> _rutasVisibles = [];
  List<Marker> _inicioFinMarkers = [];

  List<Marker> _routeLabelMarkers = [];

  List<Marker> _selectedRoutePermanentLabels = [];

  List<Marker> _paradasMarkers = [];
  List<Marker> _paradasLabelMarkers = [];

  int? _selectedTrufiId;
  String? _selectedTrufiName;
  Map<String, dynamic>? _selectedTrufiHorario;

  List<Map<String, dynamic>> _rutasVias = [];
  List<Map<String, dynamic>> _referenciasSelectedTrufi = [];
  List<Map<String, dynamic>> _referenciasSelectedRadiotaxi = [];

  final Map<int, String> _trufiNameById = {};

  final Map<int, String> _radiotaxiNameById = {};

  double _circleRadiusPx = 30.0;
  double? _lastZoomForCircle;

  bool _alreadyInit = false;
  bool _isLoadingTranslations = false;
  VoidCallback? _langChangeListener;

  RouteFilterMode _routeFilterMode = RouteFilterMode.nearby;

  static const LatLng _colcapirhuaCenter = LatLng(-17.3860, -66.2340);
  static const double _colcapirhuaZoom = 13;

  VoidCallback? _radiusListener;

  StreamSubscription<Position>? _positionStream;

  bool _isLoadingRutas = false;
  bool _isLoadingParadas = false;
  bool _isLoadingRutaTrufi = false;
  bool _isLoadingGPS = false;
  bool _isLoadingNormativas = false;
  bool _isLoadingDatos = false;
  bool _isLoadingGeoJSON = false;
  bool _isLoadingTrufis = false;
  bool _isLoadingRadiotaxis = false;
  bool _isLoadingSindicatos = false;

  List<HistorialItem> _historialTrufis = [];
  List<HistorialItem> _historialRadiotaxis = [];
  static const String _kHistorialTrufisKey = 'historial_trufis_v1';
  static const String _kHistorialRadiotaxisKey = 'historial_radiotaxis_v1';
  static const int _kMaxHistorial = 20;

  List<Map<String, dynamic>> _reclamos = [];
  bool _isLoadingReclamos = false;

  bool _isOutsideColcapirhua = false;
  bool _outsideBannerDismissed = false;
  bool _gpsOffBannerDismissed = false;
  double? _colcaBoundsMinLat;
  double? _colcaBoundsMaxLat;
  double? _colcaBoundsMinLng;
  double? _colcaBoundsMaxLng;

  // Diccionario de traducciones: idioma → clave → texto.
  // El español está hardcodeado; inglés y quechua se obtienen del API y se cachean.
  // Cada llamada a t() es una simple búsqueda en este mapa.
  static final Map<String, Map<String, String>> _tDict = {
    'es': {
      "menu": "Menú",
      "sindicatos": "Sindicatos",
      "radiotaxis": "Radiotaxis",
      "language": "Idioma",
      "darkmode": "Modo oscuro",
      "center_title": "Centrar",
      "center_colcapirhua": "Centrar Colcapirhua",
      "center_location": "Centrar ubicación",
      "radius_title": "Distancia de rutas",
      "radius_sub": "Radio (metros)",
      "base": "Base",
      "selected": "Seleccionaste",
      "id": "ID",
      "of_colcapirhua": "de Colcapirhua",
      "trufi": "Trufi",
      "radiotaxi": "Radiotaxi",
      "routes_filter": "Rutas",
      "routes_nearby": "Cerca",
      "routes_all": "Todas",
      "gps_off": "GPS apagado: mostrando todas",
      "no_route": "No se encontró ruta",
      "no_data": "Sin datos",
      "call_confirm": "¿Deseas llamar a este radiotaxi?",
      "cancel": "Cancelar",
      "call": "Llamar",
      "normativas": "Normativas",
      "open_pdf": "Abrir PDF",
      "close": "Cerrar",
      "details": "Detalle",
      "category": "Categoría",
      "title": "Título",
      "description": "Descripción",
      "about": "Acerca de nosotros",
      "about_title": "ColcaTrufis",
      "about_body":
          "ColcaTrufis te ayuda a visualizar rutas de trufis y radiotaxis en Colcapirhua. Puedes ver rutas cercanas a tu ubicación (según el radio configurado) o todas las rutas disponibles, y seleccionar una línea para ver su recorrido con inicio y fin.",
      "stops": "Paradas",
      "social_networks": "Redes Sociales",
      "official_page": "Página Oficial",
      "route_points": "Recorrido de la ruta",
      "stop_address": "Dirección de parada",
      "point": "Punto",
      "history": "Historial",
      "history_trufis": "Trufis recientes",
      "history_radiotaxis": "Radiotaxis recientes",
      "history_empty": "Sin historial",
      "history_clear": "Limpiar historial",
      "history_clear_confirm": "¿Limpiar historial?",
      "used_at": "Usado",
      "loading_route": "Cargando ruta...",
      "loading_data": "Cargando datos...",
      "loading_gps": "Obteniendo ubicación...",
      "loading_stops": "Cargando paradas...",
      "loading_norms": "Cargando normativas...",
      "loading_geojson": "Cargando mapa...",
      "reclamos": "Números de Reclamos",
      "reclamos_call": "Llamar a Reclamos",
      "reclamos_phone": "Teléfono de reclamos",
      "reclamos_whatsapp": "WhatsApp de reclamos",
      "reclamos_inactive": "No disponible",
      "outside_title": "Estás fuera de Colcapirhua",
      "outside_body": "Esta app muestra trufis y radiotaxis de Colcapirhua. Puedes seguir usándola normalmente.",
      "outside_dismiss": "Entendido",
      "references_location": "Referencias",
      "no_references": "No hay referencias",
      "ubicacion": "Ubicación",
      "no_ubicaciones": "No hay ubicaciones",
      "schedule": "Horario de atención",
      "schedule_from": "Desde",
      "schedule_to": "hasta",
      "no_schedule": "Sin horario registrado",
      "phone": "Teléfono",
      "translating": "Traduciendo...",
    },
    'en': {
      "menu": "Menu",
      "sindicatos": "Unions",
      "radiotaxis": "Radiotaxis",
      "language": "Language",
      "darkmode": "Dark mode",
      "center_title": "Center",
      "center_colcapirhua": "Center Colcapirhua",
      "center_location": "Center location",
      "radius_title": "Route distance",
      "radius_sub": "Radius (meters)",
      "base": "Base",
      "selected": "You selected",
      "id": "ID",
      "of_colcapirhua": "of Colcapirhua",
      "trufi": "Trufi",
      "radiotaxi": "Radiotaxi",
      "routes_filter": "Routes",
      "routes_nearby": "Nearby",
      "routes_all": "All",
      "gps_off": "GPS off: showing all",
      "no_route": "Route not found",
      "no_data": "No data",
      "call_confirm": "Do you want to call this radiotaxi?",
      "cancel": "Cancel",
      "call": "Call",
      "normativas": "Regulations",
      "open_pdf": "Open PDF",
      "close": "Close",
      "details": "Detail",
      "category": "Category",
      "title": "Title",
      "description": "Description",
      "about": "About us",
      "about_title": "ColcaTrufis",
      "about_body":
          "ColcaTrufis helps you visualize trufi and radiotaxi routes in Colcapirhua. You can see routes near your location (based on the configured radius) or all available routes, and select a line to see its journey with start and end points.",
      "stops": "Stops",
      "social_networks": "Social Networks",
      "official_page": "Official Page",
      "route_points": "Route journey",
      "stop_address": "Stop address",
      "point": "Point",
      "history": "History",
      "history_trufis": "Recent trufis",
      "history_radiotaxis": "Recent radiotaxis",
      "history_empty": "No history",
      "history_clear": "Clear history",
      "history_clear_confirm": "Clear history?",
      "used_at": "Used",
      "loading_route": "Loading route...",
      "loading_data": "Loading data...",
      "loading_gps": "Getting location...",
      "loading_stops": "Loading stops...",
      "loading_norms": "Loading regulations...",
      "loading_geojson": "Loading map...",
      "reclamos": "Complaint Numbers",
      "reclamos_call": "Call Complaints",
      "reclamos_phone": "Complaints phone",
      "reclamos_whatsapp": "Complaints WhatsApp",
      "reclamos_inactive": "Not available",
      "outside_title": "You are outside Colcapirhua",
      "outside_body":
          "This app shows trufis and radiotaxis from Colcapirhua. You can continue using it normally.",
      "outside_dismiss": "Understood",
      "references_location": "References",
      "no_references": "No references",
      "ubicacion": "Location",
      "no_ubicaciones": "No locations",
      "schedule": "Service hours",
      "schedule_from": "From",
      "schedule_to": "to",
      "no_schedule": "No schedule registered",
      "phone": "Phone",
      "translating": "Translating...",
    },
    'qu': {
      "menu": "Menú",
      "sindicatos": "Sindicatokuna",
      "radiotaxis": "Radiotaxikuna",
      "language": "Simi",
      "darkmode": "Tutayaq rikuchiy",
      "center_title": "Chawpiman",
      "center_colcapirhua": "Colcapirhuata chawpiman",
      "center_location": "Kaypi kasqata chawpiman",
      "radius_title": "Ñan karuyninmanta",
      "radius_sub": "Muyu (metrokunapi)",
      "base": "Saphi",
      "selected": "Akllarqanki",
      "id": "ID",
      "of_colcapirhua": "Colcapirhua ukhupi",
      "trufi": "Trufi",
      "radiotaxi": "Radiotaxi",
      "routes_filter": "Ñankuna",
      "routes_nearby": "Qayllapi",
      "routes_all": "Llapan",
      "gps_off": "GPS wañuq: llapan ñankuna rikuchikun",
      "no_route": "Mana ñan tarikunchu",
      "no_data": "Mana willaychu",
      "call_confirm": "Kay radiotaxita waqyankichu?",
      "cancel": "Mana",
      "call": "Waqyay",
      "normativas": "Kamachikuna",
      "open_pdf": "PDF kichariy",
      "close": "Wischuy",
      "details": "Chikan willakuy",
      "category": "Rikch'aqkuna",
      "title": "Sutiy",
      "description": "Willakuy",
      "about": "Noqaykumanta",
      "about_title": "ColcaTrufis",
      "about_body":
          "ColcaTrufis yanapan Colcapirhua ukhupi trufi ñankuna qhawariyta. Qayllapi ñankunata icha llapan ñankunata rikuyta atinki, hinallataq huk ñanta akllaspaqa puriyninta qhawanki.",
      "stops": "Samariy sitiokuna",
      "social_networks": "Yachachiy llika",
      "official_page": "Qhawarikunapaq llikha",
      "route_points": "Ñan puriy",
      "stop_address": "Samariy sitiopa ñannin",
      "point": "Punto",
      "history": "Qhipa llamk'asqakuna",
      "history_trufis": "Qhipa trufis",
      "history_radiotaxis": "Qhipa radiotaxis",
      "history_empty": "Mana historialniyoqchu",
      "history_clear": "Historial pichay",
      "history_clear_confirm": "Historialniyta pichayta munankichu?",
      "used_at": "Llamk'asqa",
      "loading_route": "Ñan apaykashan...",
      "loading_data": "Willakuykuna apaykashan...",
      "loading_gps": "Kaypi kasqata mashkashan...",
      "loading_stops": "Samariy sitiokuna apaykashan...",
      "loading_norms": "Kamachikuna apaykashan...",
      "loading_geojson": "Mapa apaykashan...",
      "reclamos": "Qhaparikuna numerokuna",
      "reclamos_call": "Qhaparikunaman waqyay",
      "reclamos_phone": "Qhaparikuna teléfono",
      "reclamos_whatsapp": "Qhaparikuna WhatsApp",
      "reclamos_inactive": "Mana kanchu",
      "outside_title": "Colcapirhua hawapi kanki",
      "outside_body":
          "Kay app Colcapirhua ukhupi taxis ñankunata rikuchin. Allinllata llamk'achiy atinkim.",
      "outside_dismiss": "Yachasqani",
      "references_location": "Qhawaykunakuna",
      "no_references": "Mana qhawaykunachu",
      "ubicacion": "Kaypi kasqay",
      "no_ubicaciones": "Mana kasqaykunachu",
      "schedule": "Yanapanakuy pachay",
      "schedule_from": "Hamuymanta",
      "schedule_to": "kama",
      "no_schedule": "Mana pachay qelqasqachu",
      "phone": "Teléfono",
      "translating": "Tirakushan...",
    },
  };

  String t(String key) {
    final lang = AppSettings.language.value;
    return _tDict[lang]?[key] ?? _tDict['es']?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    if (_alreadyInit) return;
    _alreadyInit = true;

    _radiusListener = () {
      if (!mounted) return;
      if (_currentPosition != null) {
        _recalcCircleRadiusPx(_mapController.camera.zoom, force: true);
      }
      _aplicarFiltroRutas();
      _aplicarFiltroParadas();
    };
    AppSettings.radiusMeters.addListener(_radiusListener!);

    // Language change: traducciones hardcodeadas en _tDict — cambio instantáneo
    _langChangeListener = () {
      if (mounted) setState(() {});
    };
    AppSettings.language.addListener(_langChangeListener!);

    _initAll();
  }

  @override
  void dispose() {
    if (_radiusListener != null) {
      AppSettings.radiusMeters.removeListener(_radiusListener!);
    }
    if (_langChangeListener != null) {
      AppSettings.language.removeListener(_langChangeListener!);
    }
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initAll() async {
    await _cargarHistorial();

    await _loadGeoJsonZona();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _fetchSindicatos(),
        _fetchRadioTaxis(),
        _fetchTrufis(),
        _fetchParadasRadiotaxis(),
      ]);

      await _cargarTodasLasRutas();

      await _getCurrentLocation();

      _mapController.move(_colcapirhuaCenter, _colcapirhuaZoom);

      _aplicarFiltroRutas();
      _aplicarFiltroParadas();
    });
  }

  Future<void> _cargarHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final trufisJson = prefs.getStringList(_kHistorialTrufisKey) ?? [];
      final radiotaxisJson = prefs.getStringList(_kHistorialRadiotaxisKey) ?? [];

      if (!mounted) return;
      setState(() {
        _historialTrufis = trufisJson
            .map((e) => HistorialItem.fromJson(jsonDecode(e)))
            .toList();
        _historialRadiotaxis = radiotaxisJson
            .map((e) => HistorialItem.fromJson(jsonDecode(e)))
            .toList();
      });
    } catch (e) {
      print("Error cargando historial: $e");
    }
  }

  Future<void> _guardarHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _kHistorialTrufisKey,
        _historialTrufis.map((e) => jsonEncode(e.toJson())).toList(),
      );
      await prefs.setStringList(
        _kHistorialRadiotaxisKey,
        _historialRadiotaxis.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (e) {
      print("Error guardando historial: $e");
    }
  }

  Future<void> _agregarAlHistorial(HistorialItem item) async {
    if (!mounted) return;
    setState(() {
      if (item.tipo == 'trufi') {
        _historialTrufis.removeWhere((h) => h.id == item.id);
        _historialTrufis.insert(0, item);
        if (_historialTrufis.length > _kMaxHistorial) {
          _historialTrufis = _historialTrufis.sublist(0, _kMaxHistorial);
        }
      } else {
        _historialRadiotaxis.removeWhere((h) => h.id == item.id);
        _historialRadiotaxis.insert(0, item);
        if (_historialRadiotaxis.length > _kMaxHistorial) {
          _historialRadiotaxis = _historialRadiotaxis.sublist(0, _kMaxHistorial);
        }
      }
    });
    await _guardarHistorial();
  }

  Future<void> _limpiarHistorial(String tipo) async {
    if (!mounted) return;
    setState(() {
      if (tipo == 'trufi') {
        _historialTrufis.clear();
      } else {
        _historialRadiotaxis.clear();
      }
    });
    await _guardarHistorial();
  }

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inMinutes < 1) return "Ahora mismo";
    if (diff.inMinutes < 60) return "Hace ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Hace ${diff.inHours}h";
    if (diff.inDays < 7) return "Hace ${diff.inDays} días";
    return "${fecha.day}/${fecha.month}/${fecha.year}";
  }

  // ==========================
// FETCH SINDICATOS (CORREGIDO - usa http.get directo)
// ==========================
Future<void> _fetchSindicatos() async {
  try {
    if (!mounted) return;
    setState(() { _isLoadingDatos = true; _isLoadingSindicatos = true; });

    final res = await http.get(
      Uri.parse("$_apiBase/sindicatos"),
      headers: const {"Accept": "application/json"},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("HTTP ${res.statusCode}");
    }

    final body = jsonDecode(res.body);
    List<dynamic> data = [];

    if (body is List) {
      data = body;
    } else if (body is Map) {
      if (body["data"] is Map && body["data"]["sindicatos"] is List) {
        data = body["data"]["sindicatos"] as List;
      } else if (body["sindicatos"] is List) {
        data = body["sindicatos"] as List;
      } else if (body["data"] is List) {
        data = body["data"] as List;
      } else if (body["success"] == true && body["data"] is List) {
        data = body["data"] as List;
      }
    }

    if (!mounted) return;
    setState(() {
      _sindicatos = data.map((e) => e as Map<String, dynamic>).toList();
      _isLoadingDatos = false;
      _isLoadingSindicatos = false;
    });
  } catch (e) {
    print("Error fetching sindicatos: $e");
    if (!mounted) return;
    setState(() { _isLoadingDatos = false; _isLoadingSindicatos = false; });
  }
}

// ==========================
// FETCH RADIOTAXIS (CORREGIDO - usa http.get directo)
// ==========================
Future<void> _fetchRadioTaxis() async {
  try {
    if (!mounted) return;
    setState(() => _isLoadingRadiotaxis = true);

    final res = await http.get(
      Uri.parse("$_apiBase/radiotaxis"),
      headers: const {"Accept": "application/json"},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("HTTP ${res.statusCode}");
    }

    final body = jsonDecode(res.body);
    List<dynamic> data = [];

    if (body is List) {
      data = body;
    } else if (body is Map) {
      if (body["data"] is Map && body["data"]["radiotaxis"] is List) {
        data = body["data"]["radiotaxis"] as List;
      } else if (body["radiotaxis"] is List) {
        data = body["radiotaxis"] as List;
      } else if (body["data"] is List) {
        data = body["data"] as List;
      } else if (body["success"] == true && body["data"] is List) {
        data = body["data"] as List;
      }
    }

    final radioTaxis = data.map((e) => e as Map<String, dynamic>).toList();

    // Actualizar caché de nombres
    _radiotaxiNameById.clear();
    for (final it in radioTaxis) {
      final id = int.tryParse((it["id"] ?? "").toString());
      final name = (it["nombre_comercial"] ?? "").toString();
      if (id != null && name.trim().isNotEmpty) {
        _radiotaxiNameById[id] = name;
      }
    }

    if (!mounted) return;
    setState(() {
      _radioTaxis = radioTaxis;
      _isLoadingRadiotaxis = false;
    });

    // Si ya hay paradas cargadas, reconstruir sus labels
    if (_paradasRadiotaxis.isNotEmpty) {
      _aplicarFiltroParadas();
    }
  } catch (e) {
    print("Error fetching radiotaxis: $e");
    if (!mounted) return;
    setState(() => _isLoadingRadiotaxis = false);
  }
}

// ==========================
// FETCH TRUFIS (CORREGIDO - usa http.get directo)
// ==========================
Future<void> _fetchTrufis() async {
  try {
    if (!mounted) return;
    setState(() => _isLoadingTrufis = true);

    final res = await http.get(
      Uri.parse("$_apiBase/trufis"),
      headers: const {"Accept": "application/json"},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("HTTP ${res.statusCode}");
    }

    final body = jsonDecode(res.body);
    List<dynamic> data = [];

    if (body is List) {
      data = body;
    } else if (body is Map) {
      if (body["data"] is Map && body["data"]["trufis"] is List) {
        data = body["data"]["trufis"] as List;
      } else if (body["trufis"] is List) {
        data = body["trufis"] as List;
      } else if (body["data"] is List) {
        data = body["data"] as List;
      } else if (body["success"] == true && body["data"] is List) {
        data = body["data"] as List;
      }
    }

    final trufis = data.map((e) => e as Map<String, dynamic>).toList();

    // Actualizar caché de nombres de líneas
    _trufiNameById.clear();
    for (final it in trufis) {
      final id = int.tryParse((it["idtrufi"] ?? "").toString());
      final name = (it["nom_linea"] ?? "").toString();
      if (id != null && name.trim().isNotEmpty) {
        _trufiNameById[id] = name;
      }
    }

    if (!mounted) return;
    setState(() {
      _trufis = trufis;
      _isLoadingTrufis = false;
    });

    // Si ya hay rutas visibles, reconstruir labels
    if (_rutasVisibles.isNotEmpty) {
      _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
    }
    if (mounted) setState(() {});
  } catch (e) {
    print("Error fetching trufis: $e");
    if (!mounted) return;
    setState(() => _isLoadingTrufis = false);
  }
}

  Future<void> _fetchParadasRadiotaxis() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingParadas = true);

      final res = await http.get(
        Uri.parse("$_apiBase/radiotaxis/paradas"),
        headers: const {"Accept": "application/json"},
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception("HTTP ${res.statusCode}");
      }

      final body = jsonDecode(res.body);
      List<dynamic> data = [];

      if (body is List) {
        data = body;
      } else if (body is Map && body["data"] is List) {
        data = body["data"] as List;
      }

      if (!mounted) return;
      setState(() {
        _paradasRadiotaxis = data.map((e) => e as Map<String, dynamic>).toList();
        _isLoadingParadas = false;
      });

      _aplicarFiltroParadas();
    } catch (e) {
      print("Error fetching paradas: $e");
      if (!mounted) return;
      setState(() {
        _paradasRadiotaxis = [];
        _isLoadingParadas = false;
      });
    }
  }

  Future<void> _loadGeoJsonZona() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingGeoJSON = true);

      final String response = await rootBundle.loadString('assets/geojson/colcapirhua.geojson');

      // Parsear manualmente para unir todos los LineStrings en un solo polígono cerrado
      final geo = jsonDecode(response) as Map<String, dynamic>;
      final features = (geo['features'] as List?) ?? [];

      // Extraer las líneas como listas de LatLng
      final segments = <List<LatLng>>[];
      for (final f in features) {
        if (f is! Map) continue;
        final geom = f['geometry'];
        if (geom is! Map || geom['type'] != 'LineString') continue;
        final coords = geom['coordinates'];
        if (coords is! List) continue;
        final pts = <LatLng>[];
        for (final c in coords) {
          if (c is! List || c.length < 2) continue;
          pts.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
        if (pts.length >= 2) segments.add(pts);
      }

      // Encadenar segmentos para formar un contorno cerrado
      final allPoints = <LatLng>[];
      if (segments.isNotEmpty) {
        final used = List<bool>.filled(segments.length, false);
        // Empezar con el primer segmento
        used[0] = true;
        allPoints.addAll(segments[0]);

        for (int pass = 1; pass < segments.length; pass++) {
          final tail = allPoints.last;
          int bestIdx = -1;
          double bestDist = double.infinity;
          bool bestReverse = false;

          for (int i = 0; i < segments.length; i++) {
            if (used[i]) continue;
            final seg = segments[i];
            final dStart = _distSq(tail, seg.first);
            final dEnd = _distSq(tail, seg.last);
            if (dStart < bestDist) {
              bestDist = dStart;
              bestIdx = i;
              bestReverse = false;
            }
            if (dEnd < bestDist) {
              bestDist = dEnd;
              bestIdx = i;
              bestReverse = true;
            }
          }

          if (bestIdx == -1) break;
          used[bestIdx] = true;
          final seg = bestReverse ? segments[bestIdx].reversed.toList() : segments[bestIdx];
          allPoints.addAll(seg);
        }
      }

      if (!mounted) return;
      setState(() {
        if (allPoints.length >= 3) {
          colcapirhuaPolygons = [
            Polygon(
              points: allPoints,
              color: kPrimary.withOpacity(0.13),
              borderColor: kPrimaryDark.withOpacity(0.92),
              borderStrokeWidth: 3.0,
              isFilled: true,
            ),
          ];
        } else {
          colcapirhuaPolygons = [];
        }

        // Mantener las líneas del contorno
        colcapirhuaLines = segments.map((pts) {
          return Polyline(
            points: pts,
            strokeWidth: 3.5,
            color: kPrimaryDark.withOpacity(0.92),
          );
        }).toList();

        _isLoadingGeoJSON = false;
      });

      _calcularBoundingBoxColca(response);

    } catch (e) {
      print("Error loading zona: $e");
      if (!mounted) return;
      setState(() {
        colcapirhuaPolygons = [];
        colcapirhuaLines = [];
        _isLoadingGeoJSON = false;
      });
    }
  }

  double _distSq(LatLng a, LatLng b) {
    final dlat = a.latitude - b.latitude;
    final dlng = a.longitude - b.longitude;
    return dlat * dlat + dlng * dlng;
  }

  void _calcularBoundingBoxColca(String geoJsonStr) {
    try {
      final geo = jsonDecode(geoJsonStr);
      final features = geo['features'] as List? ?? [];
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

      for (final f in features) {
        final geom = f['geometry'];
        if (geom == null) continue;
        final coords = _extractAllCoords(geom);
        for (final c in coords) {
          if (c[1] < minLat) minLat = c[1].toDouble();
          if (c[1] > maxLat) maxLat = c[1].toDouble();
          if (c[0] < minLng) minLng = c[0].toDouble();
          if (c[0] > maxLng) maxLng = c[0].toDouble();
        }
      }

      _colcaBoundsMinLat = minLat - 0.01;
      _colcaBoundsMaxLat = maxLat + 0.01;
      _colcaBoundsMinLng = minLng - 0.01;
      _colcaBoundsMaxLng = maxLng + 0.01;
    } catch (e) {
      print("Error calculando bounding box: $e");
    }
  }

  List<List<num>> _extractAllCoords(Map geom) {
    final type = geom['type'];
    final result = <List<num>>[];
    if (type == 'Point') {
      final c = geom['coordinates'];
      if (c is List && c.length >= 2) result.add([c[0] as num, c[1] as num]);
    } else if (type == 'LineString' || type == 'MultiPoint') {
      for (final c in (geom['coordinates'] as List? ?? [])) {
        if (c is List && c.length >= 2) result.add([c[0] as num, c[1] as num]);
      }
    } else if (type == 'Polygon' || type == 'MultiLineString') {
      for (final ring in (geom['coordinates'] as List? ?? [])) {
        for (final c in (ring as List? ?? [])) {
          if (c is List && c.length >= 2) result.add([c[0] as num, c[1] as num]);
        }
      }
    } else if (type == 'MultiPolygon') {
      for (final poly in (geom['coordinates'] as List? ?? [])) {
        for (final ring in (poly as List? ?? [])) {
          for (final c in (ring as List? ?? [])) {
            if (c is List && c.length >= 2) result.add([c[0] as num, c[1] as num]);
          }
        }
      }
    }
    return result;
  }

  void _checkIfOutsideColcapirhua() {
    if (_currentPosition == null) return;
    if (_colcaBoundsMinLat == null) return;

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    final outside = lat < _colcaBoundsMinLat! ||
        lat > _colcaBoundsMaxLat! ||
        lng < _colcaBoundsMinLng! ||
        lng > _colcaBoundsMaxLng!;

    if (!mounted) return;
    setState(() {
      final wasOutside = _isOutsideColcapirhua;
      _isOutsideColcapirhua = outside;
      if (!outside) _outsideBannerDismissed = false;
      if (outside && !wasOutside) _outsideBannerDismissed = false;
    });
  }

  ({List<Polyline> polylines, List<int?> ids}) _polylinesFromGeoJsonWithIds(Map<String, dynamic> geo) {
    final features = (geo['features'] as List? ?? []);
    final polylines = <Polyline>[];
    final ids = <int?>[];

    for (final f in features) {
      if (f is! Map) continue;

      final props = (f['properties'] is Map) ? (f['properties'] as Map) : <dynamic, dynamic>{};
      final idtrufi = int.tryParse((props['idtrufi'] ?? "").toString());

      final geom = f['geometry'];
      if (geom is! Map) continue;

      if (geom['type'] != 'LineString') continue;
      final coords = geom['coordinates'];
      if (coords is! List) continue;

      final points = <LatLng>[];
      for (final c in coords) {
        if (c is! List || c.length < 2) continue;
        final lng = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        points.add(LatLng(lat, lng));
      }

      if (points.length >= 2) {
        polylines.add(
          Polyline(
            points: points,
            strokeWidth: 3.8,
            color: kAqua,
            borderColor: const Color(0xFF032530),
            borderStrokeWidth: 1.8,
          ),
        );
        ids.add(idtrufi);
      }
    }

    return (polylines: polylines, ids: ids);
  }

  Future<void> _cargarTodasLasRutas() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingRutas = true);

      final geo = await _apiService.getGeoJsonTodasRutas();

      if (geo == null || geo['features'] == null) {
        print("⚠️ GeoJSON vacío o sin features");
        _todasRutas = [];
        _polylineIdIndex = [];
        if (!mounted) return;
        setState(() {
          _rutasVisibles = [];
          _inicioFinMarkers = [];
          _routeLabelMarkers = [];
          _isLoadingRutas = false;
        });
        return;
      }

      final parsed = _polylinesFromGeoJsonWithIds(geo);

      _todasRutas = parsed.polylines;
      _polylineIdIndex = parsed.ids;

      _polylineIdMap.clear();
      for (int i = 0; i < parsed.polylines.length; i++) {
        final id = parsed.ids[i];
        if (id != null) _polylineIdMap[parsed.polylines[i]] = id;
      }

      print("✅ Cargadas ${_todasRutas.length} rutas (${_polylineIdMap.length} con id)");

      if (!mounted) return;
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
        _isLoadingRutas = false;
      });
    } catch (e) {
      print("❌ Error cargando rutas: $e");
      _todasRutas = [];
      _polylineIdIndex = [];
      if (!mounted) return;
      setState(() {
        _rutasVisibles = [];
        _inicioFinMarkers = [];
        _routeLabelMarkers = [];
        _isLoadingRutas = false;
      });
    }
  }

  final Map<Polyline, int> _polylineIdMap = {};

  List<int?> _polylineIdIndex = [];

  int? _idOfPolyline(Polyline pl) {
    final id = _polylineIdMap[pl];
    if (id != null) return id;
    if (_selectedTrufiId != null) return _selectedTrufiId;
    return null;
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingGPS = true);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _currentPosition = null;
          _isLoadingGPS = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _isLoadingGPS = false;
        _gpsOffBannerDismissed = false;
      });
      _recalcCircleRadiusPx(_mapController.camera.zoom);
      _checkIfOutsideColcapirhua();
      _aplicarFiltroRutas();
      _aplicarFiltroParadas();

      await _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position newPos) {
        if (!mounted) return;
        setState(() {
          _currentPosition = newPos;
        });
        _recalcCircleRadiusPx(_mapController.camera.zoom);
        _checkIfOutsideColcapirhua();
        if (_routeFilterMode == RouteFilterMode.nearby) {
          _aplicarFiltroRutas();
          _aplicarFiltroParadas();
        }
      }, onError: (e) {
        print("Error en stream de ubicación: $e");
      });

    } catch (e) {
      print("Error getting location: $e");
      if (!mounted) return;
      setState(() {
        _currentPosition = null;
        _isLoadingGPS = false;
      });
    }
  }

  double _metersToPixels(double meters, double latitude, double zoom) {
    final latRad = latitude * Math.pi / 180.0;
    final metersPerPixel = 156543.03392 * Math.cos(latRad) / Math.pow(2, zoom);
    return meters / metersPerPixel;
  }

  void _recalcCircleRadiusPx(double zoom, {bool force = false}) {
    if (_currentPosition == null) return;

    if (!force && _lastZoomForCircle != null && (zoom - _lastZoomForCircle!).abs() < 0.05) return;
    _lastZoomForCircle = zoom;

    final meters = AppSettings.radiusMeters.value;
    final px = _metersToPixels(meters, _currentPosition!.latitude, zoom);
    final safePx = px.clamp(6.0, 900.0);

    if (!mounted) return;
    setState(() => _circleRadiusPx = safePx);
  }

  double _minDistToPolylineMeters(LatLng pos, List<LatLng> pts) {
    double minD = double.infinity;
    for (final p in pts) {
      final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, p.latitude, p.longitude);
      if (d < minD) minD = d;
    }
    return minD;
  }

  Future<void> _aplicarFiltroRutas() async {
    if (!mounted) return;

    if (_todasRutas.isEmpty) {
      setState(() {
        _rutasVisibles = [];
        _inicioFinMarkers = [];
        _routeLabelMarkers = [];
      });
      return;
    }

    setState(() => _isLoadingRutas = true);
    if (!mounted) return;

    // Si hay un trufi seleccionado mostrando su ruta, no sobrescribir
    if (_selectedTrufiId != null) {
      setState(() => _isLoadingRutas = false);
      return;
    }

    if (_routeFilterMode == RouteFilterMode.all) {
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
        _isLoadingRutas = false;
      });
      return;
    }

    if (_currentPosition == null) {
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
        _isLoadingRutas = false;
      });
      return;
    }

    final user = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final radius = AppSettings.radiusMeters.value;

    final cerca = _todasRutas.where((pl) {
      final d = _minDistToPolylineMeters(user, pl.points);
      return d <= radius;
    }).toList();

    if (!mounted) return;
    setState(() {
      _rutasVisibles = cerca;
      _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
      _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
      _isLoadingRutas = false;
    });
  }

  void _aplicarFiltroParadas() {
    if (!mounted) return;

    if (_paradasRadiotaxis.isEmpty) {
      setState(() {
        _paradasMarkers = [];
        _paradasLabelMarkers = [];
      });
      return;
    }

    final todasLasParadas = _paradasRadiotaxis;

    setState(() {
      _paradasMarkers = _buildParadasMarkers(todasLasParadas);
      _paradasLabelMarkers = _buildParadasLabels(todasLasParadas);
    });
  }

  List<Marker> _buildParadasMarkers(List<Map<String, dynamic>> paradas) {
    final markers = <Marker>[];

    for (final p in paradas) {
      final lat = double.tryParse((p["latitud"] ?? p["lat"] ?? p["latitude"] ?? "").toString());
      final lng = double.tryParse((p["longitud"] ?? p["lng"] ?? p["longitude"] ?? p["lon"] ?? "").toString());
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 38,
          height: 38,
          child: GestureDetector(
            onTap: () {
              _mostrarDireccionParada(p);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryDark, kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.local_taxi, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Marker> _buildParadasLabels(List<Map<String, dynamic>> paradas) {
    final markers = <Marker>[];

    for (final p in paradas) {
      final lat = double.tryParse((p["latitud"] ?? p["lat"] ?? p["latitude"] ?? "").toString());
      final lng = double.tryParse((p["longitud"] ?? p["lng"] ?? p["longitude"] ?? p["lon"] ?? "").toString());
      if (lat == null || lng == null) continue;

      final radiotaxiId = int.tryParse(
        (p["sindicato_radiotaxi_id"] ?? p["radiotaxi_id"] ?? p["idradiotaxi"] ?? p["sindicato_id"] ?? "").toString(),
      );
      final name = (radiotaxiId != null) ? (_radiotaxiNameById[radiotaxiId] ?? "Radiotaxi $radiotaxiId") : "Parada";

      if (name.trim().isEmpty) continue;

      final estimatedWidth = 30 + 14 + (name.length * 6.4);
      final w = estimatedWidth.clamp(90.0, 200.0);

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: w,
          height: 34,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: const Offset(0, 22),
            child: _paradaNamePill(name),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _paradaNamePill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryDark, kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.92), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_taxi, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDireccionParada(Map<String, dynamic> parada) async {
    final lat = double.tryParse((parada["latitud"] ?? parada["lat"] ?? parada["latitude"] ?? "").toString());
    final lng = double.tryParse((parada["longitud"] ?? parada["lng"] ?? parada["longitude"] ?? parada["lon"] ?? "").toString());
    final radiotaxiId = int.tryParse(
      (parada["sindicato_radiotaxi_id"] ?? parada["radiotaxi_id"] ?? parada["idradiotaxi"] ?? parada["sindicato_id"] ?? "").toString(),
    );
    final name = (radiotaxiId != null) ? (_radiotaxiNameById[radiotaxiId] ?? "Radiotaxi $radiotaxiId") : "Parada";

    if (lat == null || lng == null || radiotaxiId == null) return;

    // Cargar referencias del radiotaxi
    try {
      print("🔍 Cargando referencias para radiotaxi $radiotaxiId...");
      final referenciasData = await _apiService.getReferenciasDeRadiotaxi(radiotaxiId);
      print("📦 Datos de referencias recibidos: $referenciasData");
      final referencias = referenciasData.map((e) {
        if (e is Map<String, dynamic>) return e;
        return <String, dynamic>{};
      }).toList();
      
      if (!mounted) return;
      
      setState(() {
        _referenciasSelectedRadiotaxi = referencias;
      });
      
      // Mostrar modal con referencias
      _mostrarReferenciasRadiotaxiModal(name, referencias);
    } catch (e) {
      print("Error cargando referencias de radiotaxi: $e");
      // Si falla, mostrar solo la dirección de la parada
      final isDarkMode = AppSettings.darkMode.value;
      final sheetColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
      final textColor = isDarkMode ? Colors.white : Colors.black87;

      final direccion = await _getAddressFromLatLng(LatLng(lat, lng));

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return Container(
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  t("stop_address"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.local_taxi, color: kPrimary, size: 32),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    direccion,
                    style: TextStyle(color: textColor),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    }
  }

  void _mostrarReferenciasRadiotaxiModal(String radiotaxiName, List<Map<String, dynamic>> referencias) {
    final isDarkMode = AppSettings.darkMode.value;
    final sheetColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final cardBg = isDarkMode ? const Color(0xFF1A2744) : const Color(0xFFF4F8FB);

    final items = referencias.where((r) {
      final n = (r['referencia'] ?? r['nombre'] ?? r['name'] ?? '').toString().trim();
      return n.isNotEmpty;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimaryDark, kPrimary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_taxi, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            radiotaxiName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: kPrimary,
                            ),
                          ),
                          Text(
                            t("ubicacion"),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_outlined, size: 48, color: subTextColor.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              t("no_ubicaciones"),
                              style: TextStyle(color: subTextColor, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : items.length == 1
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: kPrimary.withOpacity(0.15), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: kPrimary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.place_rounded, color: kPrimary, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      (items[0]['referencia'] ?? items[0]['nombre'] ?? items[0]['name'] ?? '').toString(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final nombre = (items[index]['referencia'] ?? items[index]['nombre'] ?? items[index]['name'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: kPrimary.withOpacity(0.10), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: kPrimary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.place_rounded, color: kAqua, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          nombre,
                                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<CircleMarker> _buildRadioCircle() {
    if (_currentPosition == null) return [];
    return [
      CircleMarker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: _circleRadiusPx,
        color: const Color.fromARGB(255, 128, 80, 9).withOpacity(0.30),
        borderColor: const Color.fromARGB(255, 138, 87, 10).withOpacity(0.85),
        borderStrokeWidth: 2.5,
      ),
    ];
  }

  double _calculateBearing(LatLng a, LatLng b) {
    final dLon = (b.longitude - a.longitude) * Math.pi / 180;
    final lat1 = a.latitude * Math.pi / 180;
    final lat2 = b.latitude * Math.pi / 180;
    final y = Math.sin(dLon) * Math.cos(lat2);
    final x = Math.cos(lat1) * Math.sin(lat2) -
        Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
    return (Math.atan2(y, x) * 180 / Math.pi + 360) % 360;
  }

  List<Marker> _buildDirectionArrows(List<Polyline> polylines) {
    final markers = <Marker>[];
    const interval = 450.0;
    const maxArrows = 120;

    for (final pl in polylines) {
      if (pl.points.length < 3) continue;
      if (markers.length >= maxArrows) break;

      double accumulated = 0;

      for (int i = 1; i < pl.points.length; i++) {
        if (markers.length >= maxArrows) break;
        final prev = pl.points[i - 1];
        final curr = pl.points[i];
        final dist = Geolocator.distanceBetween(
          prev.latitude, prev.longitude,
          curr.latitude, curr.longitude,
        );

        accumulated += dist;

        if (accumulated >= interval) {
          accumulated = 0;
          final bearing = _calculateBearing(prev, curr);

          markers.add(
            Marker(
              point: curr,
              width: 24,
              height: 24,
              child: Transform.rotate(
                angle: bearing * Math.pi / 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.navigation_rounded, size: 22, color: Colors.white.withOpacity(0.9)),
                    Icon(Icons.navigation_rounded, size: 16, color: kPrimaryDark.withOpacity(0.8)),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  List<Marker> _buildInicioFinMarkers(List<Polyline> polylines, {int maxRutas = 30}) {
    final markers = <Marker>[];
    int count = 0;

    for (final pl in polylines) {
      if (count >= maxRutas) break;
      if (pl.points.length < 2) continue;

      final start = pl.points.first;
      final end = pl.points.last;

      markers.add(
        Marker(
          point: start,
          width: 34,
          height: 34,
          child: _flagMarker(
            tooltip: "Inicio",
            color: Colors.green.shade600,
            icon: Icons.flag_rounded,
          ),
        ),
      );

      markers.add(
        Marker(
          point: end,
          width: 34,
          height: 34,
          child: _flagMarker(
            tooltip: "Fin",
            color: Colors.red.shade600,
            icon: Icons.flag_outlined,
          ),
        ),
      );

      count++;
    }

    return markers;
  }

  List<Marker> _buildTapableRouteMarkers() {
    final markers = <Marker>[];

    for (int i = 0; i < _rutasVisibles.length; i++) {
      final pl = _rutasVisibles[i];
      if (pl.points.isEmpty) continue;

      final id = _idOfPolyline(pl);
      final lineName = (id != null) ? (_trufiNameById[id] ?? "Línea $id") : null;
      if (lineName == null) continue;

      String? sindicatoName;
      for (final s in _sindicatos) {
        final trufis = (s["trufis"] as List? ?? []);
        final found = trufis.any((tr) {
          final tId = int.tryParse((tr["idtrufi"] ?? "").toString());
          return tId == id;
        });
        if (found) {
          sindicatoName = (s["nombre"] ?? "").toString();
          break;
        }
      }

      final step = (pl.points.length > 16) ? (pl.points.length ~/ 8) : 1;
      final tapPoints = <LatLng>{};

      tapPoints.add(pl.points.first);
      tapPoints.add(pl.points[(pl.points.length / 2).floor()]);
      tapPoints.add(pl.points.last);

      for (int j = step; j < pl.points.length - 1; j += step) {
        tapPoints.add(pl.points[j]);
      }

      for (final point in tapPoints) {
        markers.add(
          Marker(
            point: point,
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => _mostrarInfoRuta(lineName, sindicatoName, id!),
              child: Container(color: Colors.transparent),
            ),
          ),
        );
      }
    }

    return markers;
  }

  void _mostrarInfoRuta(String lineName, String? sindicatoName, int idtrufi) {
    final isDarkMode = AppSettings.darkMode.value;
    final bg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimaryDark, kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lineName,
                          style: const TextStyle(
                            color: kPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (sindicatoName != null && sindicatoName.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.groups, color: kAqua, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sindicatoName,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(t("close")),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarRutaDeUnTrufi(idtrufi, nombreLinea: lineName);
                      },
                      icon: const Icon(Icons.route, size: 18),
                      label: Text(t("route_points")),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _flagMarker({
    required String tooltip,
    required Color color,
    required IconData icon,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6), spreadRadius: 2),
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 19)),
      ),
    );
  }

  List<Marker> _buildRouteLabels(List<Polyline> polylines) {
    final markers = <Marker>[];

    for (final pl in polylines) {
      if (pl.points.length < 2) continue;

      final id = _idOfPolyline(pl);
      final name = (id != null) ? (_trufiNameById[id] ?? "Línea $id") : null;
      if (name == null || name.trim().isEmpty) continue;

      final start = pl.points.first;

      final estimatedWidth = 30 + 14 + (name.length * 6.4);
      final w = estimatedWidth.clamp(90.0, 200.0);

      markers.add(
        Marker(
          point: start,
          width: w,
          height: 34,
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: _routeNamePill(name),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _routeNamePill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15A8A2), kAqua],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.92), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: kAqua.withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_bus_filled, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _extraerPuntosRuta(List<LatLng> points) async {
    final resultado = <Map<String, dynamic>>[];

    if (points.isEmpty) return resultado;

    resultado.add({
      'punto': 1,
      'latLng': points.first,
      'direccion': await _getAddressFromLatLng(points.first),
    });

    double distanciaAcumulada = 0;
    int numeroPunto = 2;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      final distSegmento = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      distanciaAcumulada += distSegmento;

      if (distanciaAcumulada >= 100) {
        resultado.add({
          'punto': numeroPunto,
          'latLng': curr,
          'direccion': await _getAddressFromLatLng(curr),
        });

        numeroPunto++;
        distanciaAcumulada = 0;
      }
    }

    if (resultado.last['latLng'] != points.last) {
      resultado.add({
        'punto': numeroPunto,
        'latLng': points.last,
        'direccion': await _getAddressFromLatLng(points.last),
      });
    }

    return resultado;
  }

  List<Map<String, dynamic>> _convertirUbicacionesAMapas(List<dynamic> ubicaciones) {
    final resultado = <Map<String, dynamic>>[];
    
    print("📍 _convertirUbicacionesAMapas recibió: $ubicaciones");
    print("📍 Tipo: ${ubicaciones.runtimeType}, Length: ${ubicaciones.length}");
    
    try {
      int numeroPunto = 1;
      
      for (final ubicacion in ubicaciones) {
        print("📍 Procesando ubicación $numeroPunto: $ubicacion");
        
        if (ubicacion is! Map<String, dynamic>) {
          print("⚠️ Ubicación no es Map: ${ubicacion.runtimeType}");
          continue;
        }
        
        final lat = double.tryParse((ubicacion['latitud'] ?? ubicacion['lat'] ?? ubicacion['latitude'] ?? '').toString());
        final lng = double.tryParse((ubicacion['longitud'] ?? ubicacion['lng'] ?? ubicacion['longitude'] ?? '').toString());
        final direccion = (ubicacion['nombre'] ?? ubicacion['nombre_calle'] ?? ubicacion['direccion'] ?? ubicacion['calle'] ?? '').toString();
        
        print("📍 Lat: $lat, Lng: $lng, Dirección: $direccion");
        
        if (lat == null || lng == null) {
          print("⚠️ Coordenadas nulas para punto $numeroPunto");
          continue;
        }
        
        resultado.add({
          'punto': numeroPunto,
          'latLng': LatLng(lat, lng),
          'direccion': direccion.isNotEmpty ? direccion : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        });
        
        print("✅ Punto $numeroPunto agregado correctamente");
        numeroPunto++;
      }
      print("✅ Total de ubicaciones convertidas: ${resultado.length}");
    } catch (e) {
      print("❌ Error convirtiendo ubicaciones: $e");
    }
    
    return resultado;
  }

  Future<String> _getAddressFromLatLng(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'ColcaTrufis App'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['address'] != null) {
          final address = data['address'];
          final road = address['road'] ??
              address['street'] ??
              address['path'] ??
              address['footway'] ??
              '';

          if (road.isNotEmpty) {
            return road;
          }
        }

        if (data['display_name'] != null) {
          final displayName = data['display_name'].toString();
          final parts = displayName.split(',');
          if (parts.isNotEmpty) {
            return parts[0].trim();
          }
        }
      }
    } catch (e) {
      print('Error en geocodificación inversa: $e');
    }

    return '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
  }

  Future<void> _mostrarRutaDeUnTrufi(int idtrufi, {String? nombreLinea}) async {
    if (!mounted) return;

    try {
      // Lanzar GeoJSON + ubicaciones + referencias en paralelo
      // Así el modal abre con TODOS los datos ya listos
      final results = await Future.wait([
        _apiService.getGeoJsonPorTrufi(idtrufi),
        _apiService.getUbicacionesPorTrufi(idtrufi).catchError((_) => <dynamic>[]),
        _apiService.getReferenciasDestrufi(idtrufi).catchError((_) => <dynamic>[]),
      ]);

      final geo = results[0] as Map<String, dynamic>;
      final ubicacionesRaw = results[1] as List<dynamic>;
      final refRaw = results[2] as List<dynamic>;

      if (geo['features'] == null || (geo['features'] as List).isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("no_route"))));
        return;
      }

      final parsed = _polylinesFromGeoJsonWithIds(geo);
      final ruta = parsed.polylines;

      if (ruta.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("no_route"))));
        return;
      }

      // Procesar ubicaciones
      List<Map<String, dynamic>> rutasVias = [];
      try {
        final vias = ubicacionesRaw.whereType<Map<String, dynamic>>().toList();
        vias.sort((a, b) {
          final ordenA = (a['orden'] as num?)?.toInt() ?? 999;
          final ordenB = (b['orden'] as num?)?.toInt() ?? 999;
          return ordenA.compareTo(ordenB);
        });
        rutasVias = vias;
      } catch (_) {}

      // Procesar referencias
      List<Map<String, dynamic>> referenciasData = [];
      try {
        referenciasData = refRaw
            .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {}

      final nombre = nombreLinea ?? _trufiNameById[idtrufi] ?? "Línea $idtrufi";
      final labelMarkers = _buildRouteLabelsDirect(ruta, idtrufi, nombre);

      if (!mounted) return;
      setState(() {
        _selectedTrufiId = idtrufi;
        _selectedTrufiName = nombre;
        _rutasVisibles = ruta;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 1);
        _routeLabelMarkers = labelMarkers;
        _selectedRoutePermanentLabels = labelMarkers;
        _rutasVias = rutasVias;
        _referenciasSelectedTrufi = referenciasData;
        _isLoadingRutaTrufi = false;
      });

      if (ruta.first.points.isNotEmpty) {
        _mapController.move(ruta.first.points.first, 14.8);
      }

      // Abrir el modal — ya tiene todos los datos
      _mostrarVentanaRecorrido();

      // Horario en segundo plano (solo se muestra en la tarjeta, no en el modal)
      _agregarAlHistorial(HistorialItem(
        id: idtrufi,
        nombre: nombre,
        tipo: 'trufi',
        fechaUso: DateTime.now(),
      ));
      _registrarSeleccionTrufi(idtrufi);
      _apiService.getTrufiHorario(idtrufi).then((horarioData) {
        if (!mounted) return;
        setState(() {
          _selectedTrufiHorario = (horarioData['hora_entrada'] != null || horarioData['hora_salida'] != null)
              ? horarioData
              : null;
        });
      }).catchError((_) {});

    } catch (e) {
      print("Error mostrando ruta de trufi $idtrufi: $e");
      if (!mounted) return;
      setState(() => _isLoadingRutaTrufi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar la ruta de este trufi")),
      );
    }
  }

  List<Marker> _buildRouteLabelsDirect(List<Polyline> polylines, int idtrufi, String nombre) {
    final markers = <Marker>[];

    for (final pl in polylines) {
      if (pl.points.length < 2) continue;
      if (nombre.trim().isEmpty) continue;

      final start = pl.points.first;
      final estimatedWidth = 30 + 14 + (nombre.length * 6.4);
      final w = estimatedWidth.clamp(90.0, 200.0);

      markers.add(
        Marker(
          point: start,
          width: w,
          height: 34,
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: _routeNamePill(nombre),
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _registrarSeleccionTrufi(int idtrufi) async {
    try {
      await http.post(
        Uri.parse("$_apiBase/trufis/$idtrufi/seleccion"),
        headers: const {"Accept": "application/json", "Content-Type": "application/json"},
      );
    } catch (e) {
      print("Error registrando selección de trufi $idtrufi: $e");
    }
  }

  void _mostrarVentanaRecorrido() {
    final isDarkMode = AppSettings.darkMode.value;
    final sheetColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        t("route_points"),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (_referenciasSelectedTrufi.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAqua,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _mostrarReferenciasModal(true),
                        icon: const Icon(Icons.location_city, size: 18),
                        label: Text(
                          "${t("references_location")} (${_referenciasSelectedTrufi.length})",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              if (_selectedTrufiName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    _selectedTrufiName!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              const Divider(),
              Expanded(
                child: _rutasVias.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.route_outlined, size: 48, color: subTextColor.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              t("no_data"),
                              style: TextStyle(color: subTextColor, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: _rutasVias.length,
                        itemBuilder: (context, index) {
                          final via = _rutasVias[index];
                          final orden = via['orden'] ?? (index + 1);
                          final nombreVia = (via['nombre_via'] ?? t("no_data")).toString();
                          final isDark = AppSettings.darkMode.value;
                          final cardBg = isDark ? const Color(0xFF1A2744) : const Color(0xFFF4F8FB);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kPrimary.withOpacity(0.10),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: kPrimary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$orden',
                                        style: const TextStyle(
                                          color: kPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.turn_right_rounded, color: kAqua, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      nombreVia,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarReferenciasModal(bool esTrufi) {
    final isDarkMode = AppSettings.darkMode.value;
    final sheetColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final cardBg = isDarkMode ? const Color(0xFF1A2744) : const Color(0xFFF4F8FB);

    final referencias = esTrufi ? _referenciasSelectedTrufi : _referenciasSelectedRadiotaxi;
    final items = referencias.where((r) {
      final n = (r['referencia'] ?? r['nombre'] ?? r['name'] ?? '').toString().trim();
      return n.isNotEmpty;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx2) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetCtx2);
                        _mostrarVentanaRecorrido();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimaryDark, kPrimary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.place_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t("references_location"),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: kPrimary,
                            ),
                          ),
                          Text(
                            "${items.length} ${items.length == 1 ? 'referencia' : 'referencias'}",
                            style: TextStyle(fontSize: 11, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_outlined, size: 48, color: subTextColor.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              t("no_references"),
                              style: TextStyle(color: subTextColor, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final nombre = (items[index]['referencia'] ?? items[index]['nombre'] ?? items[index]['name'] ?? '').toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: kPrimary.withOpacity(0.10),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: kPrimary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: kPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.place_rounded, color: kAqua, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      nombre,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCenterFab() async {
    final mode = AppSettings.centerMode.value;

    if (mode == "ubicacion") {
      if (_currentPosition != null) {
        // Already know position — just move camera instantly
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        );
      } else {
        // No GPS yet — request it
        await _getCurrentLocation();
        if (_currentPosition != null) {
          _mapController.move(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            15,
          );
        }
      }
      return;
    }

    _mapController.move(_colcapirhuaCenter, _colcapirhuaZoom);
  }

  /// Asks for CALL_PHONE permission if needed. Returns true if the call can proceed.
  Future<bool> _requestPhonePermission() async {
    var status = await Permission.phone.status;

    if (status.isGranted) return true;

    // Denied but can still ask
    if (status.isDenied) {
      status = await Permission.phone.request();
      if (status.isGranted) return true;
    }

    // Permanently denied — guide user to settings
    if (status.isPermanentlyDenied && mounted) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.phone_locked, color: kPrimary),
            SizedBox(width: 10),
            Text('Permiso de teléfono', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w800)),
          ]),
          content: const Text(
            'Para realizar llamadas necesitas activar el permiso de teléfono. '
            'Ve a Ajustes > Aplicaciones > ColcaTrufis > Permisos y activa "Teléfono".',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Ir a Ajustes'),
            ),
          ],
        ),
      );
      if (openSettings == true) await openAppSettings();
      return false;
    }

    return false;
  }

  /// Launches [uri] with multiple fallback modes for maximum compatibility.
  Future<void> _launchCallUri(Uri uri) async {
    // Try external first (most compatible)
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    // Fallback: platform default (opens dialer on most devices)
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el marcador para ${uri.path}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndCall(String rawPhone, {String? nombre, int? id}) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.trim().isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.local_taxi, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(nombre ?? t("radiotaxi"), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 16))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t("call_confirm")),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.phone, color: kPrimary, size: 18),
              const SizedBox(width: 8),
              Text(phone, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kPrimary)),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t("cancel"))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.call, size: 16),
            label: Text(t("call")),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final canCall = await _requestPhonePermission();
    if (!canCall) return;

    await _launchCallUri(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _confirmAndCallReclamo(String rawPhone, String titulo) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.trim().isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.headset_mic, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(t("reclamos_call"), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 16))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.phone, color: kPrimary, size: 18),
              const SizedBox(width: 8),
              Text(phone, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kPrimary)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t("cancel")),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.call, size: 16),
            label: Text(t("call")),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final canCall = await _requestPhonePermission();
    if (!canCall) return;

    await _launchCallUri(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _abrirWhatsApp(String rawPhone) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.trim().isEmpty) return;

    final waUrl = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } else {
      final waIntent = Uri.parse("whatsapp://send?phone=$phone");
      if (await canLaunchUrl(waIntent)) {
        await launchUrl(waIntent, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se pudo abrir WhatsApp")),
          );
        }
      }
    }
  }

  Future<List<dynamic>> _fetchNormativas() async {
    final res = await http.get(
      Uri.parse("$_apiBase/normativas"),
      headers: const {"Accept": "application/json"},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final body = jsonDecode(res.body);
    if (body is List) return body;
    if (body is Map && body["data"] is List) return (body["data"] as List);
    if (body is Map && body["success"] == true && body["data"] is List) return (body["data"] as List);
    return [];
  }

  Future<void> _fetchReclamos() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingReclamos = true);

      final res = await http.get(
        Uri.parse("$_apiBase/public/settings/reclamos"),
        headers: const {"Accept": "application/json"},
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception("HTTP ${res.statusCode}");
      }

      final body = jsonDecode(res.body);
      List<dynamic> data = [];

      if (body is Map && body["data"] is List) {
        data = body["data"] as List;
      } else if (body is List) {
        data = body;
      }

      if (!mounted) return;
      setState(() {
        _reclamos = data.map((e) => e as Map<String, dynamic>).toList();
        _isLoadingReclamos = false;
      });
    } catch (e) {
      print("Error fetching reclamos: $e");
      if (!mounted) return;
      setState(() => _isLoadingReclamos = false);
    }
  }

  Future<void> _openReclamosDrawer() async {
    if (_reclamos.isEmpty) {
      setState(() => _isLoadingReclamos = true);
      await _fetchReclamos();
    }

    if (!mounted) return;

    final isDark = AppSettings.darkMode.value;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.report_problem_outlined, color: kPrimary, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    t("reclamos"),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(),
              if (_isLoadingReclamos)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: kPrimary)),
                )
              else if (_reclamos.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(t("no_data"), style: TextStyle(color: subText))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reclamos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _reclamos[index];
                    final key = (item["key"] ?? "").toString();
                    final value = item["value"]?.toString() ?? "";
                    final activo = item["activo"] == true;

                    final bool isWhatsApp = key.contains("whatsapp");
                    final String label = isWhatsApp
                        ? t("reclamos_whatsapp")
                        : "${t("reclamos_phone")} ${index + 1}";

                    return ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: activo && value.isNotEmpty
                              ? (isWhatsApp ? Colors.green.withOpacity(0.12) : kPrimary.withOpacity(0.12))
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isWhatsApp ? Icons.chat : Icons.phone,
                          color: activo && value.isNotEmpty
                              ? (isWhatsApp ? Colors.green : kPrimary)
                              : Colors.grey,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        activo && value.isNotEmpty ? value : t("reclamos_inactive"),
                        style: TextStyle(
                          color: activo && value.isNotEmpty ? subText : Colors.grey,
                        ),
                      ),
                      trailing: activo && value.isNotEmpty
                          ? Icon(
                              isWhatsApp ? Icons.chat : Icons.call,
                              color: isWhatsApp ? Colors.green : kPrimary,
                            )
                          : null,
                    onTap: activo && value.isNotEmpty
                      ? () async {
                          await _confirmAndCallReclamo(value, label);
                        }
                      : null,
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openNormativasDrawer() async {
    if (!mounted) return;
    setState(() => _isLoadingNormativas = true);

    try {
      final data = await _fetchNormativas();
      if (!mounted) return;
      setState(() => _isLoadingNormativas = false);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          final isDark = AppSettings.darkMode.value;
          final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black87;
          final subText = isDark ? Colors.white70 : Colors.black54;

          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 46, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 14),
                Text(
                  t("normativas"),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimary),
                ),
                const Divider(),
                Expanded(
                  child: data.isEmpty
                      ? Center(child: Text(t("no_data"), style: TextStyle(color: subText)))
                      : ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];

                            final titulo = (item["titulo"] ?? "Normativa").toString();
                            final descripcion = (item["descripcion"] ?? "").toString();
                            final id = int.tryParse((item["id"] ?? "").toString());

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.picture_as_pdf, color: kPrimary, size: 32),
                                title: Text(
                                  titulo,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
                                ),
                                subtitle: descripcion.isNotEmpty
                                    ? Text(
                                        descripcion,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: subText),
                                      )
                                    : null,
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () async {
                                  if (id == null) return;

                                  final downloadUrl = "$_apiBase/normativas/$id/download";

                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(t("details")),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${t("title")}: $titulo",
                                              style: const TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 10),
                                            if (descripcion.isNotEmpty)
                                              Text("${t("description")}:\n$descripcion"),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(t("close")),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPrimary,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await launchUrl(
                                              Uri.parse(downloadUrl),
                                              mode: LaunchMode.externalApplication,
                                            );
                                          },
                                          icon: const Icon(Icons.open_in_new),
                                          label: Text(t("open_pdf")),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("Error loading normativas: $e");
      if (!mounted) return;
      setState(() => _isLoadingNormativas = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t("no_data"))),
      );
    }
  }

  void _openHistorialDrawer() {
    final isDarkMode = AppSettings.darkMode.value;
    final bg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return DefaultTabController(
            length: 2,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t("history"),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    labelColor: kPrimary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: kPrimary,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.directions_bus),
                        text: t("trufi"),
                      ),
                      Tab(
                        icon: const Icon(Icons.local_taxi),
                        text: t("radiotaxi"),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildHistorialTab(
                          ctx: ctx,
                          setModalState: setModalState,
                          items: _historialTrufis,
                          tipo: 'trufi',
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onItemTap: (item) async {
                            Navigator.pop(ctx);
                            setState(() => isTrufiSelected = true);
                            await _mostrarRutaDeUnTrufi(item.id, nombreLinea: item.nombre);
                          },
                        ),
                        _buildHistorialTab(
                          ctx: ctx,
                          setModalState: setModalState,
                          items: _historialRadiotaxis,
                          tipo: 'radiotaxi',
                          textColor: textColor,
                          subTextColor: subTextColor,
                          onItemTap: (item) async {
                            Navigator.pop(ctx);
                            setState(() => isTrufiSelected = false);
                            if (item.telefono != null && item.telefono!.isNotEmpty) {
                              await _confirmAndCall(item.telefono!, nombre: item.nombre, id: item.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildHistorialTab({
    required BuildContext ctx,
    required StateSetter setModalState,
    required List<HistorialItem> items,
    required String tipo,
    required Color textColor,
    required Color subTextColor,
    required Future<void> Function(HistorialItem) onItemTap,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tipo == 'trufi' ? Icons.directions_bus_outlined : Icons.local_taxi_outlined,
              size: 56,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              t("history_empty"),
              style: TextStyle(color: subTextColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: ctx,
                    builder: (_) => AlertDialog(
                      title: Text(t("history_clear_confirm")),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(t("cancel")),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(t("history_clear"), style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await _limpiarHistorial(tipo);
                    setModalState(() {});
                  }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                label: Text(t("history_clear"), style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tipo == 'trufi' ? Icons.directions_bus : Icons.local_taxi,
                    color: kPrimary,
                    size: 22,
                  ),
                ),
                title: Text(
                  item.nombre,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  "${t("used_at")}: ${_formatFecha(item.fechaUso)}",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                trailing: Icon(
                  tipo == 'trufi' ? Icons.arrow_forward_ios : Icons.phone,
                  color: kPrimary,
                  size: 16,
                ),
                onTap: () => onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.darkMode,
      builder: (context, isDarkMode, _) {
        final theme = isDarkMode
            ? ThemeData.dark().copyWith(
                scaffoldBackgroundColor: const Color(0xFF0B1220),
                dividerColor: Colors.white24,
              )
            : ThemeData.light().copyWith(
                scaffoldBackgroundColor: Colors.white,
                dividerColor: Colors.black12,
              );

        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.language,
          builder: (context, _, __) {
            return Theme(
              data: theme,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                drawer: _buildSidebarDrawer(),
                appBar: AppBar(
                  titleSpacing: 0,
                  toolbarHeight: 70,
                  iconTheme: const IconThemeData(color: Colors.white),
                  elevation: 0,
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryDark,
                          kPrimary.withOpacity(0.82),
                          kPrimary.withOpacity(0.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryDark.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/images/logo_colca1.png', width: 110),
                      Image.asset('assets/images/logo_appp.png', width: 65),
                    ],
                  ),
                ),
                body: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(-17.3939, -66.2386),
                        initialZoom: 13,
                        onPositionChanged: (pos, hasGesture) {
                          final z = pos.zoom;
                          if (z == null) return;
                          _recalcCircleRadiusPx(z);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.colcatrufis.app',
                          keepBuffer: 2,
                        ),

                        PolygonLayer(polygons: colcapirhuaPolygons),
                        if (colcapirhuaLines.isNotEmpty) PolylineLayer(polylines: colcapirhuaLines),

                        if (_routeFilterMode == RouteFilterMode.nearby && _currentPosition != null)
                          CircleLayer(circles: _buildRadioCircle()),

                        if (isTrufiSelected) ...[
                          PolylineLayer(
                            polylines: _rutasVisibles,
                          ),
                          MarkerLayer(markers: _buildDirectionArrows(_rutasVisibles)),
                          if (_routeLabelMarkers.isNotEmpty) MarkerLayer(markers: _routeLabelMarkers),
                          if (_inicioFinMarkers.isNotEmpty) MarkerLayer(markers: _inicioFinMarkers),
                          if (_selectedRoutePermanentLabels.isNotEmpty)
                            MarkerLayer(markers: _selectedRoutePermanentLabels),
                          MarkerLayer(
                            markers: _buildTapableRouteMarkers(),
                          ),
                        ] else ...[
                          if (_paradasMarkers.isNotEmpty) MarkerLayer(markers: _paradasMarkers),
                          if (_paradasLabelMarkers.isNotEmpty) MarkerLayer(markers: _paradasLabelMarkers),
                        ],

                        if (_currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.30),
                                        blurRadius: 18,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person_pin_circle, size: 42, color: Color(0xFF1565C0)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    if (_isLoadingRutaTrufi)
                      Positioned(
                        left: 16,
                        top: 90,
                        child: _loadingChip(t("loading_route"), Icons.route),
                      ),

                    if (_isLoadingGPS)
                      Positioned(
                        bottom: MediaQuery.of(context).size.height * 0.5,
                        right: 16,
                        child: _loadingChip(t("loading_gps"), Icons.gps_fixed),
                      ),

                    if (_isLoadingTranslations)
                      Positioned(
                        bottom: MediaQuery.of(context).size.height * 0.5,
                        right: 16,
                        child: _loadingChip(t("translating"), Icons.translate),
                      ),

                    if (_isLoadingGeoJSON)
                      Positioned(
                        bottom: MediaQuery.of(context).size.height * 0.5,
                        left: 16,
                        child: _loadingChip(t("loading_geojson"), Icons.map_outlined),
                      ),

                    if (_isLoadingRutas && !_isLoadingRutaTrufi)
                      Positioned(
                        bottom: MediaQuery.of(context).size.height * 0.5 - 52,
                        left: 16,
                        child: _loadingChip(t("loading_route"), Icons.route),
                      ),

                    // Loading indicators — organized column on the left
                    if (_isLoadingTrufis || _isLoadingRadiotaxis || _isLoadingSindicatos || _isLoadingParadas)
                      Positioned(
                        left: 16,
                        bottom: 130,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoadingTrufis || _isLoadingRadiotaxis || _isLoadingSindicatos) ...[  
                              _loadingChip(t("loading_data"), Icons.directions_bus_outlined),
                              const SizedBox(height: 6),
                            ],
                            if (_isLoadingParadas)
                              _loadingChip(t("loading_stops"), Icons.local_taxi_outlined),
                          ],
                        ),
                      ),

                    if (_isLoadingNormativas)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.35),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: kPrimary, strokeWidth: 3.5),
                                  const SizedBox(height: 16),
                                  Text(
                                    t("loading_norms"),
                                    style: const TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      left: 16,
                      bottom: 22,
                      child: _routesFilterDropdown(isDarkMode),
                    ),

                    if (_selectedTrufiName != null && _selectedTrufiName!.trim().isNotEmpty && isTrufiSelected)
                      Positioned(
                        left: 16,
                        top: (_isLoadingGeoJSON || _isLoadingRutaTrufi) ? 148 : 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _selectedTrufiCard(isDarkMode),
                            if (_selectedTrufiHorario != null) ...[  
                              const SizedBox(height: 8),
                              _scheduleCard(isDarkMode),
                            ],
                          ],
                        ),
                      ),

                    if (_currentPosition == null && !_gpsOffBannerDismissed)
                      Positioned(
                        bottom: 130,
                        left: 16,
                        right: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF064656),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.28),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.gps_off, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "GPS apagado",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      "Activa tu ubicación para ver rutas cercanas.",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            setState(() => _gpsOffBannerDismissed = true);
                                            await _getCurrentLocation();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.28),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              "Activar ubicación",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => setState(() => _gpsOffBannerDismissed = true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              "Cancelar",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_isOutsideColcapirhua && !_outsideBannerDismissed && _currentPosition != null)
                      Positioned(
                        bottom: 130,
                        left: 16,
                        right: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: kPrimaryDark,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_off, color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t("outside_title"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      t("outside_body"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => setState(() => _outsideBannerDismissed = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          t("outside_dismiss"),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Positioned(
                      right: 15,
                      bottom: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMapButton3D(
                            icon: Icons.directions_bus,
                            isActive: isTrufiSelected,
                            onPressed: () {
                              setState(() {
                                isTrufiSelected = true;
                              });
                              if (_selectedTrufiId == null) {
                                _aplicarFiltroRutas();
                              }
                              _showFullWidthBottomSheet(context, t("trufi"));
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildMapButton3D(
                            icon: Icons.local_taxi,
                            isActive: !isTrufiSelected,
                            onPressed: () {
                              setState(() {
                                isTrufiSelected = false;
                              });
                              _aplicarFiltroParadas();
                              _showFullWidthBottomSheet(context, t("radiotaxi"));
                            },
                          ),
                          const SizedBox(height: 25),
                          GestureDetector(
                            onTap: _handleCenterFab,
                            child: Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                    spreadRadius: 1,
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 22,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.7),
                                            Colors.white.withOpacity(0),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: _isLoadingGPS
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                                          )
                                        : const Icon(Icons.my_location, color: kPrimary, size: 22),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _loadingChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryDark.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: kPrimary.withOpacity(0.08), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: kPrimary, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routesFilterDropdown(bool isDarkMode) {
    final bg = (isDarkMode ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.96);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    final radius = AppSettings.radiusMeters.value.round();
    final currentLabel = _routeFilterMode == RouteFilterMode.nearby
        ? "${t("routes_nearby")} ($radius m)"
        : t("routes_all");

    return GestureDetector(
      onTap: () => _mostrarOpcionesRutas(isDarkMode, textColor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimary.withOpacity(0.10), width: 1),
          boxShadow: [
            BoxShadow(
              color: kPrimaryDark.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryDark, kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoadingRutas
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.route, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t("routes_filter"),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    currentLabel,
                    style: TextStyle(fontSize: 11.5, color: subTextColor, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more_rounded, color: subTextColor, size: 18),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcionesRutas(bool isDarkMode, Color textColor) {
    final sheetBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                t("routes_filter"),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _routeFilterMode == RouteFilterMode.nearby ? kPrimary : kPrimary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.my_location, color: _routeFilterMode == RouteFilterMode.nearby ? Colors.white : kPrimary, size: 20),
                ),
                title: Text(
                  "${t("routes_nearby")} (${AppSettings.radiusMeters.value.round()} m)",
                  style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
                ),
                trailing: _routeFilterMode == RouteFilterMode.nearby
                    ? const Icon(Icons.check_circle, color: kPrimary)
                    : const Icon(Icons.radio_button_unchecked, color: kPrimary),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _routeFilterMode = RouteFilterMode.nearby);
                  if (_currentPosition == null) await _getCurrentLocation();
                  _aplicarFiltroRutas();
                  _aplicarFiltroParadas();
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _routeFilterMode == RouteFilterMode.all ? kPrimary : kPrimary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.map_outlined, color: _routeFilterMode == RouteFilterMode.all ? Colors.white : kPrimary, size: 20),
                ),
                title: Text(
                  t("routes_all"),
                  style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
                ),
                trailing: _routeFilterMode == RouteFilterMode.all
                    ? const Icon(Icons.check_circle, color: kPrimary)
                    : const Icon(Icons.radio_button_unchecked, color: kPrimary),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    _routeFilterMode = RouteFilterMode.all;
                    isTrufiSelected = true;
                  });
                  _aplicarFiltroRutas();
                  _aplicarFiltroParadas();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _selectedTrufiCard(bool isDarkMode) {
    final bg = (isDarkMode ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.95);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kPrimary.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: kPrimaryDark.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A6B82), kPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(color: kPrimaryDark.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedTrufiName ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 4),
          if (_rutasVias.isNotEmpty)
            InkWell(
              onTap: _mostrarVentanaRecorrido,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kAqua.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.list_alt, size: 18, color: kAqua),
              ),
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              setState(() {
                _selectedTrufiId = null;
                _selectedTrufiName = null;
                _selectedTrufiHorario = null;
                _rutasVias = [];
                _selectedRoutePermanentLabels = [];
              });

              _mapController.move(_colcapirhuaCenter, _colcapirhuaZoom);
              _aplicarFiltroRutas();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close, size: 18, color: textColor.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(bool isDarkMode) {
    final bg = (isDarkMode ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.95);
    final subColor = isDarkMode ? Colors.white70 : Colors.black54;
    final entrada = _selectedTrufiHorario?['hora_entrada']?.toString() ?? '';
    final salida = _selectedTrufiHorario?['hora_salida']?.toString() ?? '';
    String fmt(String v) => v.length >= 5 ? v.substring(0, 5) : v;

    final bool tieneHorario = entrada.isNotEmpty || salida.isNotEmpty;
    String horarioStr;
    if (entrada.isNotEmpty && salida.isNotEmpty) {
      horarioStr = '${fmt(entrada)}\u2013${fmt(salida)}';
    } else if (entrada.isNotEmpty) {
      horarioStr = '${t("schedule_from")} ${fmt(entrada)}';
    } else if (salida.isNotEmpty) {
      horarioStr = 'Hasta ${fmt(salida)}';
    } else {
      horarioStr = t('no_schedule');
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.18)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.access_time_rounded, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t('schedule'),
                style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2),
              ),
              const SizedBox(height: 2),
              Text(
                horarioStr,
                style: TextStyle(
                  color: tieneHorario ? kPrimary : subColor,
                  fontWeight: tieneHorario ? FontWeight.w800 : FontWeight.w500,
                  fontSize: tieneHorario ? 15 : 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton3D({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 62,
        width: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF0A6B82), kPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? kPrimaryDark.withOpacity(0.45)
                  : Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
            if (isActive)
              BoxShadow(
                color: kAqua.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 2),
                spreadRadius: 2,
              ),
          ],
          border: Border.all(
            color: isActive
                ? Colors.white.withOpacity(0.22)
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(isActive ? 0.22 : 0.65),
                      Colors.white.withOpacity(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(icon, color: isActive ? Colors.white : kPrimary, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullWidthBottomSheet(BuildContext context, String type) {
    final bool isLookingForTrufi = (type == t("trufi"));

    _openSheetWhenReady(context, type, isLookingForTrufi);
  }

  Future<void> _openSheetWhenReady(
    BuildContext context,
    String type,
    bool isLookingForTrufi,
  ) async {
    if (isLookingForTrufi && _trufis.isEmpty) {
      if (_isLoadingTrufis || _isLoadingDatos) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 5),
              backgroundColor: kPrimary,
              content: Row(
                children: [
                  const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(t("loading_data")),
                ],
              ),
            ),
          );
        }
        int waited = 0;
        while ((_isLoadingTrufis || _isLoadingDatos) && waited < 60) {
          await Future.delayed(const Duration(milliseconds: 100));
          waited++;
        }
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (_trufis.isEmpty && mounted) await _fetchTrufis();
      } else {
        await _fetchTrufis();
      }
    }

    if (!isLookingForTrufi && _radioTaxis.isEmpty) {
      if (_isLoadingRadiotaxis || _isLoadingDatos) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 5),
              backgroundColor: kPrimary,
              content: Row(
                children: [
                  const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(t("loading_data")),
                ],
              ),
            ),
          );
        }
        int waited = 0;
        while ((_isLoadingRadiotaxis || _isLoadingDatos) && waited < 60) {
          await Future.delayed(const Duration(milliseconds: 100));
          waited++;
        }
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (_radioTaxis.isEmpty && mounted) await _fetchRadioTaxis();
      } else {
        await _fetchRadioTaxis();
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final isDarkMode = AppSettings.darkMode.value;
            final sheetColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
            final textColor = isDarkMode ? Colors.white : Colors.black87;
            final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

            final List<Map<String, dynamic>> dataList =
                isLookingForTrufi ? _trufis : _radioTaxis;
            final bool isLoading = isLookingForTrufi ? _isLoadingTrufis : _isLoadingRadiotaxis;

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white24 : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kPrimaryDark, kPrimary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryDark.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isLookingForTrufi ? Icons.directions_bus_filled : Icons.local_taxi,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$type ${t("of_colcapirhua")}",
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${dataList.length} disponibles",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.06)),
                  SizedBox(
                    height: 320,
                    child: isLoading && dataList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
                                const SizedBox(height: 14),
                                Text(t("loading_data"),
                                    style: TextStyle(color: subTextColor, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        : dataList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isLookingForTrufi ? Icons.directions_bus_outlined : Icons.local_taxi_outlined,
                                      size: 48,
                                      color: subTextColor.withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      t("no_data"),
                                      style: TextStyle(color: subTextColor),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                                itemCount: dataList.length,
                                itemBuilder: (context, index) {
                                  final item = dataList[index];

                                  final String titulo = isLookingForTrufi
                                      ? (item["nom_linea"] ?? "Sin nombre")
                                      : (item["nombre_comercial"] ?? "Sin nombre");

                                  final String? subtitulo = isLookingForTrufi
                                      ? null
                                      : "${t("phone")}: ${item["telefono_base"] ?? 'S/N'}";

                                  final cardBg = isDarkMode
                                      ? const Color(0xFF1A2744)
                                      : const Color(0xFFF6F9FC);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () async {
                                          Navigator.pop(sheetCtx);

                                          if (isLookingForTrufi &&
                                              item["idtrufi"] != null) {
                                            final id = int.parse(
                                                item["idtrufi"].toString());
                                            _mostrarRutaDeUnTrufi(id,
                                                nombreLinea: titulo);
                                            return;
                                          }

                                          if (!isLookingForTrufi) {
                                            final phone =
                                                (item["telefono_base"] ?? "")
                                                    .toString();
                                            final id = int.tryParse(
                                                (item["id"] ?? "").toString());
                                            if (id != null) {
                                              await _agregarAlHistorial(
                                                  HistorialItem(
                                                id: id,
                                                nombre: titulo,
                                                tipo: 'radiotaxi',
                                                telefono: phone,
                                                fechaUso: DateTime.now(),
                                              ));
                                            }
                                            await _confirmAndCall(phone,
                                                nombre: titulo, id: id);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: isLookingForTrufi
                                                        ? [kAqua.withOpacity(0.15), kAqua.withOpacity(0.06)]
                                                        : [kPrimary.withOpacity(0.15), kPrimary.withOpacity(0.06)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  isLookingForTrufi
                                                      ? Icons.directions_bus_filled
                                                      : Icons.local_taxi,
                                                  color: isLookingForTrufi ? kAqua : kPrimary,
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      titulo,
                                                      style: TextStyle(
                                                        color: textColor,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (subtitulo != null) ...[
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        subtitulo,
                                                        style: TextStyle(
                                                          color: subTextColor,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                isLookingForTrufi
                                                    ? Icons.arrow_forward_ios_rounded
                                                    : Icons.phone_rounded,
                                                color: isLookingForTrufi ? kAqua : kPrimary,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Drawer _buildSidebarDrawer() {
    final drawerWidth = MediaQuery.of(context).size.width * 0.75;

    return Drawer(
      width: drawerWidth,
      child: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: AppSettings.darkMode,
          builder: (context, isDarkMode, _) {
            final bg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
            final textColor = isDarkMode ? Colors.white : Colors.black87;
            final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;
            final sectionHeaderColor = isDarkMode ? Colors.white38 : Colors.black38;
            final dividerColor = isDarkMode ? Colors.white12 : Colors.black12;

            Widget sectionHeader(String label) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: kAqua,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: sectionHeaderColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                );

            Widget drawerTile({
              required IconData icon,
              required String title,
              String? subtitle,
              Widget? trailing,
              bool loading = false,
              VoidCallback? onTap,
            }) =>
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: loading ? Colors.transparent : kPrimary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: loading
                          ? Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                              ),
                            )
                          : Icon(icon, color: kPrimary, size: 20),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subtitle != null
                        ? Text(
                            subtitle,
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          )
                        : null,
                    trailing: trailing,
                    onTap: onTap,
                    minLeadingWidth: 28,
                  ),
                );

            return Container(
              color: bg,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ClipRect(
                    child: Container(
                      width: double.infinity,
                      height: 148,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF032D38), Color(0xFF064656), Color(0xFF09596E)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF032D38).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Large circle — top-right, half clipped
                          Positioned(
                            right: -45,
                            top: -45,
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                          ),
                          // Medium circle — bottom-right corner
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                          ),
                          // Logo — left, vertically centered, slightly larger
                          Positioned(
                            left: 20,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo_colca1.png',
                                width: 112,
                                height: 112,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  sectionHeader("Transporte"),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.groups, color: kPrimary, size: 20),
                        ),
                        title: Text(
                          t("sindicatos"),
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        children: _sindicatos.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(t("loading_data"), style: TextStyle(color: subTextColor, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ]
                            : _sindicatos.map((s) {
                                final String sindicatoNombre = s["nombre"] ?? "Sin Nombre";
                                final List trufis = (s["trufis"] as List? ?? []);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.white.withOpacity(0.04) : kPrimary.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                                      leading: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: kPrimary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: const Icon(Icons.account_balance, color: kPrimary, size: 16),
                                      ),
                                      title: Text(sindicatoNombre, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                      childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                                      children: trufis.map<Widget>((tr) {
                                        final linea = (tr["nom_linea"] ?? "").toString();
                                        final id = int.tryParse((tr["idtrufi"] ?? "").toString());

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 3),
                                          child: Material(
                                            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(10),
                                              onTap: () {
                                                Navigator.pop(context);
                                                setState(() => isTrufiSelected = true);
                                                if (id != null) _mostrarRutaDeUnTrufi(id, nombreLinea: linea);
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 26,
                                                      height: 26,
                                                      decoration: BoxDecoration(
                                                        color: kAqua.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(7),
                                                      ),
                                                      child: const Icon(Icons.directions_bus, color: kAqua, size: 14),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(child: Text(linea, style: TextStyle(color: textColor, fontSize: 13))),
                                                    Icon(Icons.chevron_right_rounded, color: subTextColor.withOpacity(0.4), size: 18),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.local_taxi, color: kPrimary, size: 20),
                        ),
                        title: Text(
                          t("radiotaxis"),
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        children: _radioTaxis.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(t("loading_data"), style: TextStyle(color: subTextColor, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ]
                            : _radioTaxis.map((rt) {
                                final phone = (rt["telefono_base"] ?? "").toString();
                                final nombre = rt["nombre_comercial"] ?? "Radiotaxi";
                                final id = int.tryParse((rt["id"] ?? "").toString());

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Material(
                                    color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        setState(() => isTrufiSelected = false);
                                        if (id != null) {
                                          await _agregarAlHistorial(HistorialItem(
                                            id: id,
                                            nombre: nombre,
                                            tipo: 'radiotaxi',
                                            telefono: phone,
                                            fechaUso: DateTime.now(),
                                          ));
                                        }
                                        await _confirmAndCall(phone, nombre: nombre, id: id);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: kPrimary.withOpacity(0.10),
                                                borderRadius: BorderRadius.circular(7),
                                              ),
                                              child: const Icon(Icons.local_taxi, color: kPrimary, size: 14),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(nombre, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                                  if (phone.isNotEmpty)
                                                    Text(phone, style: TextStyle(color: subTextColor, fontSize: 11.5)),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.phone_rounded, color: kPrimary.withOpacity(0.5), size: 17),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
                  ),

                  Divider(height: 1, indent: 20, endIndent: 20, color: dividerColor),

                  sectionHeader("Información y Servicios"),

                  drawerTile(
                    icon: Icons.history,
                    title: t("history"),
                    subtitle: "${_historialTrufis.length + _historialRadiotaxis.length} registros",
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${_historialTrufis.length + _historialRadiotaxis.length}",
                        style: const TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openHistorialDrawer();
                    },
                  ),

                  drawerTile(
                    icon: Icons.report_problem_outlined,
                    title: t("reclamos"),
                    loading: _isLoadingReclamos,
                    onTap: () async {
                      Navigator.pop(context);
                      await _openReclamosDrawer();
                    },
                  ),

                  drawerTile(
                    icon: Icons.menu_book,
                    title: t("normativas"),
                    loading: _isLoadingNormativas,
                    onTap: () async {
                      Navigator.pop(context);
                      await _openNormativasDrawer();
                    },
                  ),

                  const SizedBox(height: 6),
                  Divider(height: 1, indent: 20, endIndent: 20, color: dividerColor),

                  sectionHeader("Municipio de Colcapirhua"),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.share, color: kPrimary, size: 20),
                        ),
                        title: Text(
                          t("social_networks"),
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        children: [
                          _socialTile(Icons.music_note, "TikTok", "https://www.tiktok.com/@gamdecolcapirhua?is_from_webapp=1&sender_device=pc", textColor),
                          _socialTile(Icons.play_circle, "YouTube", "https://www.youtube.com/@gamdecolcapirhua", textColor),
                          _socialTile(Icons.facebook, "Facebook", "https://www.facebook.com/municipiodecolcapirhua", textColor),
                          _socialTile(Icons.camera_alt, "Instagram", "https://www.instagram.com/alcaldiadecolcapirhua", textColor),
                          _socialTile(Icons.close, "X (Twitter)", "https://x.com/GAMColcapirhua", textColor),
                        ],
                      ),
                    ),
                  ),

                  drawerTile(
                    icon: Icons.public,
                    title: t("official_page"),
                    onTap: () async {
                      await launchUrl(
                        Uri.parse("https://www.colcapirhua.gob.bo/"),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),

                  const SizedBox(height: 6),
                  Divider(height: 1, indent: 20, endIndent: 20, color: dividerColor),

                  sectionHeader("Configuración"),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.language, color: kPrimary, size: 20),
                      ),
                      title: Text(
                        t("language"),
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      trailing: ValueListenableBuilder<String>(
                        valueListenable: AppSettings.language,
                        builder: (_, lang, __) {
                          return DropdownButton<String>(
                            value: lang,
                            dropdownColor: bg,
                            style: TextStyle(color: textColor, fontSize: 13),
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: "es", child: Text("Español")),
                              DropdownMenuItem(value: "en", child: Text("English")),
                              DropdownMenuItem(value: "qu", child: Text("Quechua")),
                            ],
                            onChanged: (v) {
                              if (v != null) AppSettings.language.value = v;
                            },
                          );
                        },
                      ),
                      minLeadingWidth: 28,
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: SwitchListTile(
                      value: AppSettings.darkMode.value,
                      activeColor: kAqua,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      title: Text(
                        t("darkmode"),
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      onChanged: (v) => AppSettings.darkMode.value = v,
                      secondary: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.dark_mode, color: kPrimary, size: 20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),

                  ValueListenableBuilder<double>(
                    valueListenable: AppSettings.radiusMeters,
                    builder: (context, meters, _) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(Icons.radio_button_checked, color: kPrimary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t("radius_title"),
                                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${meters.round()} m",
                                    style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                activeTrackColor: kPrimary,
                                inactiveTrackColor: kPrimary.withOpacity(0.12),
                                thumbColor: kPrimary,
                                overlayColor: kPrimary.withOpacity(0.10),
                              ),
                              child: Slider(
                                value: meters.clamp(50, 2000),
                                min: 50,
                                max: 2000,
                                divisions: 39,
                                onChanged: (v) => AppSettings.radiusMeters.value = v,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  ValueListenableBuilder<String>(
                    valueListenable: AppSettings.centerMode,
                    builder: (_, mode, __) {
                      return drawerTile(
                        icon: Icons.center_focus_strong,
                        title: t("center_title"),
                        subtitle: mode == "ubicacion" ? t("center_location") : t("center_colcapirhua"),
                        trailing: Icon(Icons.expand_more, color: subTextColor, size: 18),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) {
                              final sheetBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
                              return Container(
                                decoration: BoxDecoration(
                                  color: sheetBg,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 10),
                                    Container(width: 46, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                                    const SizedBox(height: 10),
                                    ListTile(
                                      leading: const Icon(Icons.location_city, color: kPrimary),
                                      title: Text(t("center_colcapirhua")),
                                      onTap: () {
                                        AppSettings.centerMode.value = "colcapirhua";
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.my_location, color: kPrimary),
                                      title: Text(t("center_location")),
                                      onTap: () {
                                        AppSettings.centerMode.value = "ubicacion";
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 6),
                  Divider(height: 1, indent: 20, endIndent: 20, color: dividerColor),

                  sectionHeader("Acerca de"),

                  drawerTile(
                    icon: Icons.info_outline,
                    title: t("about"),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(t("about_title")),
                          content: Text(t("about_body")),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _socialTile(IconData icon, String name, String url, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: kPrimary, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                Icon(Icons.open_in_new, size: 13, color: textColor.withOpacity(0.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
