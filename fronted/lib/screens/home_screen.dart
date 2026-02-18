import 'dart:convert';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

// Colores pedidos
const Color kPrimary = Color(0xFF09596E); // #09596e
const Color kPrimaryDark = Color(0xFF064656);

// ✅ Verde agua para el label (coherente con tu app)
const Color kAqua = Color(0xFF19B7B0);

class AppSettings {
  static final ValueNotifier<String> language = ValueNotifier<String>("es");
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);

  /// ✅ modo de centrado (por defecto Colcapirhua)
  /// valores: 'colcapirhua' | 'ubicacion'
  static final ValueNotifier<String> centerMode = ValueNotifier<String>("colcapirhua");

  /// ✅ Nuevo: radio dinámico (por defecto 250)
  static final ValueNotifier<double> radiusMeters = ValueNotifier<double>(250.0);
}

enum RouteFilterMode { nearby, all }

// ✅ NUEVO: Modelo de historial
class HistorialItem {
  final int id;
  final String nombre;
  final String tipo; // 'trufi' | 'radiotaxi'
  final String? telefono; // solo para radiotaxis
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

  // ✅ GeoJSON Colcapirhua
  final GeoJsonParser _zonaParser = GeoJsonParser();

  // Api
  final ApiService _apiService = ApiService(baseUrl: "http://localhost:8000/api");

  // ✅ Para normativas (mismo host que ApiService)
  static const String _apiBase = "http://localhost:8000/api";

  Position? _currentPosition;

  List<Map<String, dynamic>> _sindicatos = [];
  List<Map<String, dynamic>> _radioTaxis = [];
  List<Map<String, dynamic>> _trufis = [];

  // ✅ NUEVO: paradas de radiotaxis
  List<Map<String, dynamic>> _paradasRadiotaxis = [];

  // ✅ Zona Colcapirhua siempre visible
  List<Polygon> colcapirhuaPolygons = [];
  List<Polyline> colcapirhuaLines = [];

  // ✅ Rutas
  List<Polyline> _todasRutas = [];
  List<Polyline> _rutasVisibles = [];
  List<Marker> _inicioFinMarkers = [];

  // ✅ Nuevo: labels de rutas (nombre de línea en la ruta)
  List<Marker> _routeLabelMarkers = [];

  // ✅ NUEVO: markers de paradas de radiotaxis
  List<Marker> _paradasMarkers = [];
  List<Marker> _paradasLabelMarkers = [];

  // ✅ Para mostrar card del trufi seleccionado
  int? _selectedTrufiId;
  String? _selectedTrufiName;

  // ✅ NUEVO: Lista de puntos de la ruta seleccionada (calles cada ~100m)
  List<Map<String, dynamic>> _rutaPuntos = [];

  // ✅ cache de nombres por idtrufi
  final Map<int, String> _trufiNameById = {};

  // ✅ NUEVO: cache de nombres por idradiotaxi
  final Map<int, String> _radiotaxiNameById = {};

  // ✅ Circle metros -> pixels (web)
  double _circleRadiusPx = 30.0;
  double? _lastZoomForCircle;

  bool _alreadyInit = false;

  // ✅ Por defecto: "cerca"
  RouteFilterMode _routeFilterMode = RouteFilterMode.nearby;

  // ✅ Centro colcapirhua fijo
  static const LatLng _colcapirhuaCenter = LatLng(-17.3860, -66.2340);
  static const double _colcapirhuaZoom = 13;

  // ✅ Listener para radio (para evitar setState after dispose)
  VoidCallback? _radiusListener;

  // ✅ NUEVO: Estados de carga
  bool _isLoadingRutas = false;
  bool _isLoadingParadas = false;
  bool _isLoadingRutaTrufi = false;
  bool _isLoadingGPS = false;
  bool _isLoadingNormativas = false;
  bool _isLoadingDatos = false;
  bool _isLoadingGeoJSON = false;

  // ✅ NUEVO: Historial persistente
  List<HistorialItem> _historialTrufis = [];
  List<HistorialItem> _historialRadiotaxis = [];
  static const String _kHistorialTrufisKey = 'historial_trufis_v1';
  static const String _kHistorialRadiotaxisKey = 'historial_radiotaxis_v1';
  static const int _kMaxHistorial = 20;

  // ✅ NUEVO: Reclamos
  List<Map<String, dynamic>> _reclamos = [];
  bool _isLoadingReclamos = false;

  // ✅ NUEVO: Fuera de Colcapirhua
  bool _isOutsideColcapirhua = false;
  bool _outsideBannerDismissed = false;
  // Bounding box aproximado de Colcapirhua (calculado del GeoJSON)
  double? _colcaBoundsMinLat;
  double? _colcaBoundsMaxLat;
  double? _colcaBoundsMinLng;
  double? _colcaBoundsMaxLng;

  // ==========================
  // Traducciones
  // ==========================
  String t(String key) {
    final lang = AppSettings.language.value;
    final dict = <String, Map<String, String>>{
      "menu": {"es": "Menú", "en": "Menu", "qu": "Menu"},
      "sindicatos": {"es": "Sindicatos", "en": "Unions", "qu": "Sindicato-kuna"},
      "radiotaxis": {"es": "Radiotaxis", "en": "Radio taxis", "qu": "RadioTaxi-kuna"},
      "language": {"es": "Idioma", "en": "Language", "qu": "Simi"},
      "darkmode": {"es": "Modo oscuro", "en": "Dark mode", "qu": "Yanay mode"},
      "center_title": {"es": "Centrar", "en": "Center", "qu": "Ch'uyanchay"},
      "center_colcapirhua": {"es": "Centrar Colcapirhua", "en": "Center Colcapirhua", "qu": "Colcapirhua ch'uyanchay"},
      "center_location": {"es": "Centrar ubicación", "en": "Center location", "qu": "Maypichus ch'uyanchay"},
      "radius_title": {"es": "Distancia de rutas", "en": "Routes distance", "qu": "Ñan ch'usaq"},
      "radius_sub": {"es": "Radio (metros)", "en": "Radius (meters)", "qu": "Radio (metro-kuna)"},
      "base": {"es": "Base", "en": "Base", "qu": "Base"},
      "selected": {"es": "Seleccionaste", "en": "You selected", "qu": "Akllarirqanki"},
      "id": {"es": "ID", "en": "ID", "qu": "ID"},
      "of_colcapirhua": {"es": "de Colcapirhua", "en": "in Colcapirhua", "qu": "Colcapirhua-pi"},
      "trufi": {"es": "Trufi", "en": "Trufi", "qu": "Trufi"},
      "radiotaxi": {"es": "Radiotaxi", "en": "Radio taxi", "qu": "RadioTaxi"},
      "routes_filter": {"es": "Rutas", "en": "Routes", "qu": "Ñan-kuna"},
      "routes_nearby": {"es": "Cerca", "en": "Nearby", "qu": "Aswan qaylla"},
      "routes_all": {"es": "Todas", "en": "All", "qu": "Llapan"},
      "gps_off": {"es": "GPS apagado: mostrando todas", "en": "GPS off: showing all", "qu": "GPS mana llamk'anchu: llapan"},
      "no_route": {"es": "No se encontró ruta", "en": "Route not found", "qu": "Ñan mana tarikunchu"},
      "no_data": {"es": "Sin datos", "en": "No data", "qu": "Mana datos"},
      "call_confirm": {"es": "¿Deseas llamar a este radiotaxi?", "en": "Do you want to call this radio taxi?", "qu": "Kay radiotaxi-ta waqayta munankichu?"},
      "cancel": {"es": "Cancelar", "en": "Cancel", "qu": "Mana"},
      "call": {"es": "Llamar", "en": "Call", "qu": "Waqay"},
      "normativas": {"es": "Normativas", "en": "Regulations", "qu": "Kamachiykuna"},
      "open_pdf": {"es": "Abrir PDF", "en": "Open PDF", "qu": "PDF kichay"},
      "close": {"es": "Cerrar", "en": "Close", "qu": "Wichay"},
      "details": {"es": "Detalle", "en": "Details", "qu": "Willay"},
      "category": {"es": "Categoría", "en": "Category", "qu": "K'iti"},
      "title": {"es": "Título", "en": "Title", "qu": "Sutin"},
      "description": {"es": "Descripción", "en": "Description", "qu": "Willay"},
      "about": {"es": "Acerca de nosotros", "en": "About us", "qu": "Imamanta"},
      "about_title": {"es": "ColcaTrufis", "en": "ColcaTrufis", "qu": "ColcaTrufis"},
      "about_body": {
        "es":
            "ColcaTrufis te ayuda a visualizar rutas de trufis y radiotaxis en Colcapirhua. Puedes ver rutas cercanas a tu ubicación (según el radio configurado) o todas las rutas disponibles, y seleccionar una línea para ver su recorrido con inicio y fin.",
        "en":
            "ColcaTrufis helps you visualize trufi and radio taxi routes in Colcapirhua. You can view nearby routes (based on the configured radius) or all routes, and select a line to see its path with start and end.",
        "qu":
            "ColcaTrufis Colcapirhua-pi trufi, radiotaxi ñan-kunata rikuchin. Radio akllasqa kaqman hina qaylla ñan-kunata utaq llapan ñan-kunata rikuyta atinki; huk linea akllaspayki qallariy, tukuyta rikunki.",
      },
      "stops": {"es": "Paradas", "en": "Stops", "qu": "Sayay"},
      "social_networks": {"es": "Redes Sociales", "en": "Social Networks", "qu": "Redes Sociales"},
      "official_page": {"es": "Página Oficial", "en": "Official Page", "qu": "Página Oficial"},
      "route_points": {"es": "Recorrido de la ruta", "en": "Route path", "qu": "Ñan puriynin"},
      "stop_address": {"es": "Dirección de parada", "en": "Stop address", "qu": "Sayay direccion"},
      "point": {"es": "Punto", "en": "Point", "qu": "Punto"},
      // ✅ NUEVO: traducciones historial
      "history": {"es": "Historial", "en": "History", "qu": "Qhipa kaq"},
      "history_trufis": {"es": "Trufis recientes", "en": "Recent trufis", "qu": "Qhipa trufi-kuna"},
      "history_radiotaxis": {"es": "Radiotaxis recientes", "en": "Recent radio taxis", "qu": "Qhipa radiotaxi-kuna"},
      "history_empty": {"es": "Sin historial", "en": "No history", "qu": "Mana qhipa"},
      "history_clear": {"es": "Limpiar historial", "en": "Clear history", "qu": "Huqariy"},
      "history_clear_confirm": {"es": "¿Limpiar historial?", "en": "Clear history?", "qu": "Huqariyta munankichu?"},
      "used_at": {"es": "Usado", "en": "Used", "qu": "Llamk'asqa"},
      // ✅ NUEVO: traducciones de carga
      "loading_route": {"es": "Cargando ruta...", "en": "Loading route...", "qu": "Ñan carganki..."},
      "loading_data": {"es": "Cargando datos...", "en": "Loading data...", "qu": "Datos carganki..."},
      "loading_gps": {"es": "Obteniendo ubicación...", "en": "Getting location...", "qu": "Chiqan yachayta..."},
      "loading_stops": {"es": "Cargando paradas...", "en": "Loading stops...", "qu": "Sayay carganki..."},
      "loading_norms": {"es": "Cargando normativas...", "en": "Loading regulations...", "qu": "Kamachiykuna carganki..."},
      "loading_geojson": {"es": "Cargando mapa...", "en": "Loading map...", "qu": "Mapa carganki..."},
      // ✅ NUEVO: reclamos
      "reclamos": {"es": "Números de Reclamos", "en": "Complaint Numbers", "qu": "Reclamo números"},
      "reclamos_call": {"es": "Llamar a Reclamos", "en": "Call Complaints", "qu": "Reclamo waqay"},
      "reclamos_phone": {"es": "Teléfono de reclamos", "en": "Complaint phone", "qu": "Reclamo telefono"},
      "reclamos_whatsapp": {"es": "WhatsApp de reclamos", "en": "Complaints WhatsApp", "qu": "Reclamo WhatsApp"},
      "reclamos_inactive": {"es": "No disponible", "en": "Not available", "qu": "Mana"},
      // ✅ NUEVO: fuera de colcapirhua
      "outside_title": {"es": "Estás fuera de Colcapirhua", "en": "You're outside Colcapirhua", "qu": "Colcapirhua-manta llojsisqa kanki"},
      "outside_body": {"es": "Esta app muestra trufis y radiotaxis de Colcapirhua. Puedes seguir usándola normalmente.", "en": "This app shows trufis and radio taxis from Colcapirhua. You can still use it normally.", "qu": "Kay app Colcapirhua-pi trufi, radiotaxi-kunata rikuchin. Allinllatam llamk'aqtinki."},
      "outside_dismiss": {"es": "Entendido", "en": "Got it", "qu": "Yachani"},
    };
    return dict[key]?[lang] ?? dict[key]?["es"] ?? key;
  }

  // ==========================
  // INIT / DISPOSE
  // ==========================
  @override
  void initState() {
    super.initState();
    if (_alreadyInit) return;
    _alreadyInit = true;

    // ✅ Listener del radio (para recalcular círculo y filtro)
    _radiusListener = () {
      if (!mounted) return;
      if (_currentPosition != null) {
        _recalcCircleRadiusPx(_mapController.camera.zoom);
      }
      _aplicarFiltroRutas();
      _aplicarFiltroParadas();
    };
    AppSettings.radiusMeters.addListener(_radiusListener!);

    _initAll();
  }

  @override
  void dispose() {
    if (_radiusListener != null) {
      AppSettings.radiusMeters.removeListener(_radiusListener!);
    }
    super.dispose();
  }

  Future<void> _initAll() async {
    // ✅ Cargar historial persistente al iniciar
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

      // ✅ obtenemos GPS al inicio (si se puede)
      await _getCurrentLocation();

      // ✅ Por defecto al entrar: centrar Colcapirhua
      _mapController.move(_colcapirhuaCenter, _colcapirhuaZoom);

      // ✅ Importante: al entrar debe aplicar "cerca" si hay GPS
      _aplicarFiltroRutas();
      _aplicarFiltroParadas();
    });
  }

  // ==========================
  // ✅ HISTORIAL PERSISTENTE
  // ==========================
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
        // Eliminar duplicado si existe
        _historialTrufis.removeWhere((h) => h.id == item.id);
        // Agregar al inicio (más reciente primero)
        _historialTrufis.insert(0, item);
        // Limitar tamaño
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
  // FETCH BASE
  // ==========================
  Future<void> _fetchSindicatos() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingDatos = true);
      final sindicatos = await _apiService.getSindicatos();
      if (!mounted) return;
      setState(() {
        _sindicatos = List<Map<String, dynamic>>.from(sindicatos);
        _isLoadingDatos = false;
      });
    } catch (e) {
      print("Error fetching sindicatos: $e");
      if (!mounted) return;
      setState(() => _isLoadingDatos = false);
    }
  }

  Future<void> _fetchRadioTaxis() async {
    try {
      final radioTaxis = await _apiService.getRadioTaxis();
      if (!mounted) return;

      // ✅ cache de nombres por id
      _radiotaxiNameById.clear();
      for (final it in radioTaxis) {
        final id = int.tryParse((it["id"] ?? "").toString());
        final name = (it["nombre_comercial"] ?? "").toString();
        if (id != null && name.trim().isNotEmpty) {
          _radiotaxiNameById[id] = name;
        }
      }

      setState(() => _radioTaxis = List<Map<String, dynamic>>.from(radioTaxis));

      // ✅ FIX: reconstruir markers de paradas con nombres correctos
      // (porque _fetchParadasRadiotaxis puede haber corrido primero con cache vacío)
      if (_paradasRadiotaxis.isNotEmpty) {
        _aplicarFiltroParadas();
      }
    } catch (e) {
      print("Error fetching radiotaxis: $e");
    }
  }

  Future<void> _fetchTrufis() async {
    try {
      final trufis = await _apiService.getTrufis();
      if (!mounted) return;

      // ✅ arma cache idtrufi -> nom_linea
      _trufiNameById.clear();
      for (final it in trufis) {
        final id = int.tryParse((it["idtrufi"] ?? "").toString());
        final name = (it["nom_linea"] ?? "").toString();
        if (id != null && name.trim().isNotEmpty) {
          _trufiNameById[id] = name;
        }
      }

      setState(() => _trufis = List<Map<String, dynamic>>.from(trufis));

      // ✅ si ya hay rutas visibles, reconstruye labels con nombres reales
      _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
      if (mounted) setState(() {});
    } catch (e) {
      print("Error fetching trufis: $e");
    }
  }

  // ✅ fetch paradas de radiotaxis
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

  // ==========================
  // ZONA COLCAPIRHUA (SIEMPRE)
  // ==========================
  Future<void> _loadGeoJsonZona() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingGeoJSON = true);

      final String response = await rootBundle.loadString('assets/geojson/colcapirhua.geojson');

      _zonaParser.polygons.clear();
      _zonaParser.polylines.clear();
      _zonaParser.markers.clear();

      _zonaParser.parseGeoJsonAsString(response);

      if (!mounted) return;
      setState(() {
        colcapirhuaPolygons = _zonaParser.polygons.map((p) {
          return Polygon(
            points: p.points,
            color: kPrimary.withOpacity(0.15),
            borderColor: kPrimary.withOpacity(0.85),
            borderStrokeWidth: 3.0,
            isFilled: true,
          );
        }).toList();

        colcapirhuaLines = _zonaParser.polylines.map((l) {
          return Polyline(
            points: l.points,
            strokeWidth: 3.5,
            color: kPrimary.withOpacity(0.95),
          );
        }).toList();

        _isLoadingGeoJSON = false;
      });

      // ✅ NUEVO: calcular bounding box del GeoJSON para detección fuera de Colca
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

  // ✅ NUEVO: calcula bounding box de Colcapirhua desde GeoJSON
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

      // Agregar un buffer de ~0.01 grados (~1km) alrededor del polígono
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

  // ✅ NUEVO: chequear si la posición está fuera de Colcapirhua
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
      _isOutsideColcapirhua = outside;
      if (!outside) _outsideBannerDismissed = false;
    });
  }

  // ==========================
  // PARSEO MANUAL GEOJSON (RUTAS)
  // ==========================
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
            strokeWidth: 3,
            color: kAqua.withOpacity(0.95),
            borderColor: kPrimaryDark.withOpacity(0.55),
            borderStrokeWidth: 1,
          ),
        );
        ids.add(idtrufi);
      }
    }

    return (polylines: polylines, ids: ids);
  }

  // ==========================
  // CARGAR TODAS LAS RUTAS
  // ==========================
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

      print("✅ Cargadas ${_todasRutas.length} rutas");

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

  // ✅ Guardamos idtrufi de cada polyline por índice
  List<int?> _polylineIdIndex = [];

  int? _idOfPolyline(Polyline pl) {
    final idx = _rutasVisibles.indexOf(pl);
    if (idx >= 0 && idx < _polylineIdIndex.length) return _polylineIdIndex[idx];
    return null;
  }

  // ==========================
  // UBICACIÓN
  // ==========================
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

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _isLoadingGPS = false;
      });

      _recalcCircleRadiusPx(_mapController.camera.zoom);
      // ✅ NUEVO: chequear si está fuera de Colcapirhua
      _checkIfOutsideColcapirhua();
    } catch (e) {
      print("Error getting location: $e");
      if (!mounted) return;
      setState(() {
        _currentPosition = null;
        _isLoadingGPS = false;
      });
    }
  }

  // ==========================
  // Metros -> pixeles (web)
  // ==========================
  double _metersToPixels(double meters, double latitude, double zoom) {
    final latRad = latitude * Math.pi / 180.0;
    final metersPerPixel = 156543.03392 * Math.cos(latRad) / Math.pow(2, zoom);
    return meters / metersPerPixel;
  }

  void _recalcCircleRadiusPx(double zoom) {
    if (_currentPosition == null) return;

    if (_lastZoomForCircle != null && (zoom - _lastZoomForCircle!).abs() < 0.05) return;
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

  // ==========================
  // FILTRO (cerca/todas) - RUTAS
  // ==========================
  void _aplicarFiltroRutas() {
    if (!mounted) return;

    if (_todasRutas.isEmpty) {
      setState(() {
        _rutasVisibles = [];
        _inicioFinMarkers = [];
        _routeLabelMarkers = [];
      });
      return;
    }

    if (_routeFilterMode == RouteFilterMode.all) {
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
      });
      return;
    }

    if (_currentPosition == null) {
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
      });
      return;
    }

    final user = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final radius = AppSettings.radiusMeters.value;

    final cerca = _todasRutas.where((pl) {
      final d = _minDistToPolylineMeters(user, pl.points);
      return d <= radius;
    }).toList();

    setState(() {
      _rutasVisibles = cerca;
      _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
      _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
    });
  }

  // ==========================
  // FILTRO (cerca/todas) - PARADAS
  // ==========================
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

  // ==========================
  // BUILD PARADAS MARKERS
  // ==========================
  List<Marker> _buildParadasMarkers(List<Map<String, dynamic>> paradas) {
    final markers = <Marker>[];

    for (final p in paradas) {
      // ✅ FIX: soportar múltiples nombres de campo para lat/lng
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
                color: kPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.95), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
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

  // ==========================
  // BUILD PARADAS LABELS (debajo del marker)
  // ==========================
  List<Marker> _buildParadasLabels(List<Map<String, dynamic>> paradas) {
    final markers = <Marker>[];

    for (final p in paradas) {
      // ✅ FIX: soportar múltiples nombres de campo para lat/lng
      final lat = double.tryParse((p["latitud"] ?? p["lat"] ?? p["latitude"] ?? "").toString());
      final lng = double.tryParse((p["longitud"] ?? p["lng"] ?? p["longitude"] ?? p["lon"] ?? "").toString());
      if (lat == null || lng == null) continue;

      // ✅ FIX: soportar múltiples nombres de campo para el id del radiotaxi
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.6),
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

  // ==========================
  // Mostrar dirección de parada
  // ✅ REVERTIDO al enfoque original: await dirección primero, luego mostrar sheet
  // ==========================
  void _mostrarDireccionParada(Map<String, dynamic> parada) async {
    final lat = double.tryParse((parada["latitud"] ?? parada["lat"] ?? parada["latitude"] ?? "").toString());
    final lng = double.tryParse((parada["longitud"] ?? parada["lng"] ?? parada["longitude"] ?? parada["lon"] ?? "").toString());
    final radiotaxiId = int.tryParse(
      (parada["sindicato_radiotaxi_id"] ?? parada["radiotaxi_id"] ?? parada["idradiotaxi"] ?? parada["sindicato_id"] ?? "").toString(),
    );
    final name = (radiotaxiId != null) ? (_radiotaxiNameById[radiotaxiId] ?? "Radiotaxi $radiotaxiId") : "Parada";

    if (lat == null || lng == null) return;

    final isDarkMode = AppSettings.darkMode.value;
    final sheetColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    // ✅ Obtener dirección ANTES de mostrar el sheet (igual que el código original)
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

  // ==========================
  // CÍRCULO (visual) - solo en modo "cerca"
  // ==========================
  List<CircleMarker> _buildRadioCircle() {
    if (_currentPosition == null) return [];
    return [
      CircleMarker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: _circleRadiusPx,
        color: kPrimary.withOpacity(0.12),
        borderColor: kPrimary.withOpacity(0.55),
        borderStrokeWidth: 2,
      ),
    ];
  }

  // ==========================
  // INICIO/FIN
  // ==========================
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

  // ==========================
  // ✅ FIX 4: Markers tapables a lo largo de cada ruta visible
  // Al tocar: muestra nombre de línea + sindicato al que pertenece
  // ==========================
  List<Marker> _buildTapableRouteMarkers() {
    final markers = <Marker>[];

    for (int i = 0; i < _rutasVisibles.length; i++) {
      final pl = _rutasVisibles[i];
      if (pl.points.isEmpty) continue;

      // Usamos el punto medio de la ruta como punto de tap
      final midIdx = (pl.points.length / 2).floor();
      final midPoint = pl.points[midIdx];

      // Obtenemos el id del trufi para esta polyline
      final id = (i < _polylineIdIndex.length) ? _polylineIdIndex[i] : null;
      final lineName = (id != null) ? (_trufiNameById[id] ?? "Línea $id") : null;
      if (lineName == null) continue;

      // Encontrar el sindicato al que pertenece esta línea
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

      markers.add(
        Marker(
          point: midPoint,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _mostrarInfoRuta(lineName, sindicatoName, id!),
            child: Container(
              // Área de tap transparente (invisible) encima de la ruta
              color: Colors.transparent,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // ✅ FIX 4: Popup que aparece al tocar una ruta en el mapa
  void _mostrarInfoRuta(String lineName, String? sindicatoName, int idtrufi) {
    final isDarkMode = AppSettings.darkMode.value;
    final bg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
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
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.95), width: 3),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 19)),
      ),
    );
  }

  // ==========================
  // Labels de rutas
  // ==========================
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: kAqua.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.6),
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

  // ==========================
  // Extraer puntos de la ruta cada ~100m
  // ==========================
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

  // ==========================
  // Geocodificación inversa (Nominatim)
  // ==========================
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

  // ==========================
  // MOSTRAR RUTA 1 TRUFI
  // ✅ MEJORADO: Loader, historial, nombre siempre visible
  // ==========================
  Future<void> _mostrarRutaDeUnTrufi(int idtrufi, {String? nombreLinea}) async {
    // ✅ Mostrar overlay de carga inmediatamente
    if (!mounted) return;
    setState(() => _isLoadingRutaTrufi = true);

    try {
      final geo = await _apiService.getGeoJsonPorTrufi(idtrufi);

      if (geo == null || geo['features'] == null || (geo['features'] as List).isEmpty) {
        if (!mounted) return;
        setState(() => _isLoadingRutaTrufi = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("no_route"))));
        return;
      }

      final parsed = _polylinesFromGeoJsonWithIds(geo);
      final ruta = parsed.polylines;

      if (ruta.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoadingRutaTrufi = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("no_route"))));
        return;
      }

      // ✅ Extraer puntos de la ruta cada ~100m
      final puntosRuta = await _extraerPuntosRuta(ruta.first.points);

      if (!mounted) return;

      final nombre = nombreLinea ?? _trufiNameById[idtrufi] ?? "Línea $idtrufi";

      setState(() {
        _selectedTrufiId = idtrufi;
        _selectedTrufiName = nombre;

        _rutasVisibles = ruta;
        _polylineIdIndex = parsed.ids;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 1);
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);

        _rutaPuntos = puntosRuta;
        _isLoadingRutaTrufi = false;
      });

      // ✅ Guardar en historial
      await _agregarAlHistorial(HistorialItem(
        id: idtrufi,
        nombre: nombre,
        tipo: 'trufi',
        fechaUso: DateTime.now(),
      ));

      // ✅ NUEVO: registrar selección en el backend (reporte +1)
      _registrarSeleccionTrufi(idtrufi);

      if (ruta.first.points.isNotEmpty) {
        _mapController.move(ruta.first.points.first, 14.8);
      }

      // ✅ Mostrar ventana deslizante con puntos de ruta
      _mostrarVentanaRecorrido();
    } catch (e) {
      print("Error mostrando ruta de trufi $idtrufi: $e");
      if (!mounted) return;
      setState(() => _isLoadingRutaTrufi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar la ruta de este trufi")),
      );
    }
  }

  // ==========================
  // ✅ NUEVO: Registrar selección de trufi en backend (reporte +1)
  // ==========================
  Future<void> _registrarSeleccionTrufi(int idtrufi) async {
    try {
      await http.post(
        Uri.parse("$_apiBase/trufis/$idtrufi/seleccion"),
        headers: const {"Accept": "application/json", "Content-Type": "application/json"},
      );
    } catch (e) {
      // Silencioso: el reporte es no-crítico, no afectar al usuario si falla
      print("Error registrando selección de trufi $idtrufi: $e");
    }
  }

  // ==========================
  // Ventana deslizante con recorrido de la ruta
  // ✅ FIX: al cerrar el sheet, el nombre del trufi NO desaparece
  // ==========================
  void _mostrarVentanaRecorrido() {
    final isDarkMode = AppSettings.darkMode.value;
    final sheetColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ✅ FIX CLAVE: al cerrar el sheet NO limpiamos _selectedTrufiName
      // El nombre se mantiene en el card superior hasta que el usuario presione X
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
              Text(
                t("route_points"),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kPrimary,
                ),
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
                child: _rutaPuntos.isEmpty
                    ? Center(
                        child: Text(
                          t("no_data"),
                          style: TextStyle(color: subTextColor),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _rutaPuntos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final punto = _rutaPuntos[index];
                          final numero = punto['punto'] ?? (index + 1);
                          final direccion = punto['direccion'] ?? t("no_data");
                          final latLng = punto['latLng'] as LatLng?;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: kPrimary.withOpacity(0.15),
                              child: Text(
                                '$numero',
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '$direccion',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.location_on,
                              color: kAqua,
                            ),
                            onTap: () {
                              if (latLng != null) {
                                Navigator.pop(context);
                                _mapController.move(latLng, 17);
                              }
                            },
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

  // ==========================
  // CENTRADO
  // ==========================
  Future<void> _handleCenterFab() async {
    final mode = AppSettings.centerMode.value;

    if (mode == "ubicacion") {
      await _getCurrentLocation();
      _aplicarFiltroRutas();
      _aplicarFiltroParadas();
      if (_currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        );
      }
      return;
    }

    _mapController.move(_colcapirhuaCenter, _colcapirhuaZoom);
  }

  // ==========================
  // CALL Radiotaxi
  // ✅ El historial se guarda al SELECCIONAR desde el botón flotante, no aquí
  // ==========================
  Future<void> _confirmAndCall(String rawPhone, {String? nombre, int? id}) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.trim().isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t("radiotaxi")),
        content: Text(t("call_confirm")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t("cancel"))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t("call")),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final uri = Uri.parse("tel:$phone");
    await launchUrl(uri);
  }

  // ==========================
  // NORMATIVAS
  // ==========================
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

  // ==========================
  // ✅ NUEVO: Reclamos
  // ==========================
  Future<void> _fetchReclamos() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingReclamos = true);

      final res = await http.get(
        Uri.parse("$_apiBase/public/settings/reclamos"),
        headers: const {"Accept": "application/json"},
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception("HTTP \${res.statusCode}");
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
      print("Error fetching reclamos: \$e");
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
                    final String label = isWhatsApp ? t("reclamos_whatsapp") : "${t("reclamos_phone")} \${index + 1}";

                    return ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: activo && value.isNotEmpty
                              ? kPrimary.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isWhatsApp ? Icons.chat : Icons.phone,
                          color: activo && value.isNotEmpty ? kPrimary : Colors.grey,
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
                          ? Icon(Icons.call, color: kPrimary)
                          : null,
                      onTap: activo && value.isNotEmpty
                          ? () async {
                              final phone = value.replaceAll(RegExp(r'[^0-9+]'), '');
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(t("reclamos_call")),
                                  content: Text(value),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(t("cancel")),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context, true),
                                      icon: const Icon(Icons.call),
                                      label: Text(t("call")),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await launchUrl(Uri.parse("tel:\$phone"));
                              }
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
                                            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
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

  // ==========================
  // ✅ NUEVO: Drawer de Historial
  // ==========================
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
                        // ✅ Tab Trufis
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
                        // ✅ Tab Radiotaxis
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
        // ✅ Botón limpiar historial
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

  // ==========================
  // UI
  // ==========================
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
                        colors: [kPrimaryDark.withOpacity(1), kPrimary.withOpacity(0.78)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                          // ✅ FIX 4: PolylineLayer con tap para mostrar nombre + sindicato
                          PolylineLayer(
                            polylines: _rutasVisibles,
                          ),
                          if (_routeLabelMarkers.isNotEmpty) MarkerLayer(markers: _routeLabelMarkers),
                          if (_inicioFinMarkers.isNotEmpty) MarkerLayer(markers: _inicioFinMarkers),
                          // ✅ FIX 4: Markers invisibles tapables encima de cada ruta para detectar taps
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
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.person_pin_circle, size: 40, color: Colors.blue),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // ✅ NUEVO: Overlay de carga global (rutas del trufi)
                    if (_isLoadingRutaTrufi)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.45),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: kPrimary, strokeWidth: 3.5),
                                  const SizedBox(height: 16),
                                  Text(
                                    t("loading_route"),
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

                    // ✅ NUEVO: Overlay GPS
                    if (_isLoadingGPS)
                      Positioned(
                        top: 90,
                        right: 16,
                        child: _loadingChip(t("loading_gps"), Icons.gps_fixed),
                      ),

                    // ✅ NUEVO: Overlay cargando mapa/GeoJSON
                    if (_isLoadingGeoJSON)
                      Positioned(
                        top: 90,
                        left: 16,
                        child: _loadingChip(t("loading_geojson"), Icons.map_outlined),
                      ),

                    // ✅ NUEVO: Overlay cargando rutas
                    if (_isLoadingRutas && !_isLoadingRutaTrufi)
                      Positioned(
                        top: _isLoadingGeoJSON ? 140 : 90,
                        left: 16,
                        child: _loadingChip(t("loading_route"), Icons.route),
                      ),

                    // ✅ NUEVO: Overlay cargando normativas
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

                    // ✅ FIX 3: El card del trufi SIEMPRE visible cuando hay un trufi seleccionado
                    // Se muestra independientemente del tab activo (trufi/radiotaxi)
                    // Se posiciona debajo de los chips de carga cuando estén visibles
                    if (_selectedTrufiName != null && _selectedTrufiName!.trim().isNotEmpty)
                      Positioned(
                        left: 16,
                        top: (_isLoadingGeoJSON || (_isLoadingRutas && !_isLoadingRutaTrufi)) ? 148 : 90,
                        child: _selectedTrufiCard(isDarkMode),
                      ),

                    // ✅ NUEVO: Banner "fuera de Colcapirhua"
                    if (_isOutsideColcapirhua && !_outsideBannerDismissed && _currentPosition != null)
                      Positioned(
                        bottom: 130,
                        left: 16,
                        right: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
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
                              // ✅ FIX: Si hay un trufi seleccionado activo, NO resetear las rutas
                              // El nombre y la ruta del trufi deben mantenerse visibles
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
                          FloatingActionButton(
                            mini: true,
                            heroTag: "btnCenter",
                            backgroundColor: Colors.white,
                            onPressed: _handleCenterFab,
                            child: _isLoadingGPS
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                                  )
                                : const Icon(Icons.my_location, color: kPrimary),
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

  // ✅ NUEVO: Chip de carga pequeño
  Widget _loadingChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================
  // UI: Dropdown de rutas
  // ==========================
  Widget _routesFilterDropdown(bool isDarkMode) {
    final bg = (isDarkMode ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.92);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    final radius = AppSettings.radiusMeters.value.round();
    final currentLabel = _routeFilterMode == RouteFilterMode.nearby ? "${t("routes_nearby")} ($radius m)" : t("routes_all");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Spinner pequeño si está cargando rutas
          _isLoadingRutas
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                )
              : const Icon(Icons.route, color: kPrimary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t("routes_filter"), style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 2),
              Text(
                _routeFilterMode == RouteFilterMode.nearby && _currentPosition == null ? t("gps_off") : currentLabel,
                style: TextStyle(fontSize: 12, color: subTextColor),
              ),
            ],
          ),
          const SizedBox(width: 10),
          PopupMenuButton<RouteFilterMode>(
            tooltip: "",
            icon: Icon(Icons.expand_more, color: textColor),
            onSelected: (mode) async {
              setState(() => _routeFilterMode = mode);

              if (_routeFilterMode == RouteFilterMode.nearby) {
                if (_currentPosition == null) {
                  await _getCurrentLocation();
                }
              }
              _aplicarFiltroRutas();
              _aplicarFiltroParadas();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: RouteFilterMode.nearby,
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: textColor),
                    const SizedBox(width: 10),
                    Text("${t("routes_nearby")} (${AppSettings.radiusMeters.value.round()} m)"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: RouteFilterMode.all,
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, color: textColor),
                    const SizedBox(width: 10),
                    Text(t("routes_all")),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================
  // UI: Card del trufi seleccionado
  // ✅ FIX: al cerrar X, centra en Colcapirhua y restaura todas las rutas
  // ✅ FIX: el card PERSISTE en pantalla aunque el bottomsheet se cierre
  // ✅ NUEVO: botón para reabrir el recorrido
  // ==========================
  Widget _selectedTrufiCard(bool isDarkMode) {
    final bg = (isDarkMode ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.92);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryDark.withOpacity(0.95), kPrimary.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.directions_bus_filled, color: Colors.white),
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
          // ✅ NUEVO: botón para reabrir ventana de recorrido
          if (_rutaPuntos.isNotEmpty)
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
                _rutaPuntos = [];
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

  // ==========================
  // Botón 3D
  // ==========================
  Widget _buildMapButton3D({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isActive
              ? LinearGradient(colors: [kPrimaryDark, kPrimary], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : LinearGradient(
                  colors: [Colors.white.withOpacity(0.98), Colors.grey.shade200.withOpacity(0.95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: isActive ? Colors.white.withOpacity(0.12) : Colors.black12, width: 1),
        ),
        child: Center(
          child: Icon(icon, color: isActive ? Colors.white : kPrimary, size: 35),
        ),
      ),
    );
  }

  // ==========================
  // BottomSheet dinámico (Trufi vs Radiotaxi)
  // ✅ MEJORADO: loader en lista, historial en radiotaxi call
  // ==========================
  void _showFullWidthBottomSheet(BuildContext context, String type) {
    final bool isLookingForTrufi = (type == t("trufi"));
    final List<Map<String, dynamic>> dataList = isLookingForTrufi ? _trufis : _radioTaxis;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = AppSettings.darkMode.value;
        final sheetColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              Text(
                "$type ${t("of_colcapirhua")}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary),
              ),
              const Divider(),
              SizedBox(
                height: 300,
                child: _isLoadingDatos && dataList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: kPrimary),
                            const SizedBox(height: 12),
                            Text(t("loading_data"), style: TextStyle(color: subTextColor)),
                          ],
                        ),
                      )
                    : dataList.isEmpty
                        ? Center(child: Text(t("no_data"), style: TextStyle(color: subTextColor)))
                        : ListView.separated(
                            itemCount: dataList.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = dataList[index];

                              final String titulo = isLookingForTrufi
                                  ? (item["nom_linea"] ?? "Sin nombre")
                                  : (item["nombre_comercial"] ?? "Sin nombre");

                              final String subtitulo = isLookingForTrufi
                                  ? "${t("id")}: ${item["idtrufi"]}"
                                  : "${t("base")}: ${item["telefono_base"] ?? 'S/N'}";

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: kPrimary.withOpacity(0.12),
                                  child: Icon(
                                    isLookingForTrufi ? Icons.bus_alert : Icons.local_taxi,
                                    color: kPrimary,
                                  ),
                                ),
                                title: Text(titulo, style: TextStyle(color: textColor)),
                                subtitle: Text(subtitulo, style: TextStyle(color: subTextColor)),
                                onTap: () async {
                                  Navigator.pop(context);

                                  if (isLookingForTrufi && item["idtrufi"] != null) {
                                    final id = int.parse(item["idtrufi"].toString());
                                    _mostrarRutaDeUnTrufi(id, nombreLinea: titulo);
                                    return;
                                  }

                                  if (!isLookingForTrufi) {
                                    final phone = (item["telefono_base"] ?? "").toString();
                                    final id = int.tryParse((item["id"] ?? "").toString());
                                    // ✅ FIX: guardar en historial al seleccionar desde el botón flotante
                                    // Se guarda al momento de la selección, independientemente de si llama o no
                                    if (id != null) {
                                      await _agregarAlHistorial(HistorialItem(
                                        id: id,
                                        nombre: titulo,
                                        tipo: 'radiotaxi',
                                        telefono: phone,
                                        fechaUso: DateTime.now(),
                                      ));
                                    }
                                    await _confirmAndCall(phone, nombre: titulo, id: id);
                                  }
                                },
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

  // ==========================
  // Drawer
  // ==========================
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

            return Container(
              color: bg,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryDark.withOpacity(0.98), kPrimary.withOpacity(0.92)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/images/logo_colca1.png', width: 110),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "ColcaTrufis",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 1) SINDICATOS
                  ExpansionTile(
                    leading: const Icon(Icons.groups, color: kPrimary),
                    title: Text(t("sindicatos"), style: TextStyle(color: textColor)),
                    children: _sindicatos.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(t("loading_data"), style: TextStyle(color: subTextColor)),
                                ],
                              ),
                            ),
                          ]
                        : _sindicatos.map((s) {
                            final String sindicatoNombre = s["nombre"] ?? "Sin Nombre";
                            final List trufis = (s["trufis"] as List? ?? []);

                            return ExpansionTile(
                              leading: const Icon(Icons.account_balance, color: kPrimary),
                              title: Text(sindicatoNombre, style: TextStyle(color: textColor)),
                              children: trufis.map<Widget>((tr) {
                                final linea = (tr["nom_linea"] ?? "").toString();
                                final id = int.tryParse((tr["idtrufi"] ?? "").toString());

                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.directions_bus, color: kPrimary),
                                  title: Text(linea, style: TextStyle(color: textColor)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() => isTrufiSelected = true);
                                    if (id != null) _mostrarRutaDeUnTrufi(id, nombreLinea: linea);
                                  },
                                );
                              }).toList(),
                            );
                          }).toList(),
                  ),

                  // 2) RADIOTAXIS
                  ExpansionTile(
                    leading: const Icon(Icons.local_taxi, color: kPrimary),
                    title: Text(t("radiotaxis"), style: TextStyle(color: textColor)),
                    children: _radioTaxis.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(t("loading_data"), style: TextStyle(color: subTextColor)),
                                ],
                              ),
                            ),
                          ]
                        : _radioTaxis.map((rt) {
                            final phone = (rt["telefono_base"] ?? "").toString();
                            final nombre = rt["nombre_comercial"] ?? "Radiotaxi";
                            final id = int.tryParse((rt["id"] ?? "").toString());

                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.phone, color: kPrimary),
                              title: Text(nombre, style: TextStyle(color: textColor)),
                              subtitle: Text('${t("base")}: $phone', style: TextStyle(color: subTextColor)),
                              onTap: () async {
                                Navigator.pop(context);
                                setState(() => isTrufiSelected = false);
                                // ✅ FIX: guardar en historial al seleccionar desde el sidebar
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
                            );
                          }).toList(),
                  ),

                  const Divider(),

                  // ✅ NUEVO: HISTORIAL
                  ListTile(
                    leading: const Icon(Icons.history, color: kPrimary),
                    title: Text(t("history"), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      "${_historialTrufis.length + _historialRadiotaxis.length} registros",
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${_historialTrufis.length + _historialRadiotaxis.length}",
                        style: const TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openHistorialDrawer();
                    },
                  ),

                  const Divider(),

                  // ✅ NUEVO: RECLAMOS
                  ListTile(
                    leading: _isLoadingReclamos
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                          )
                        : const Icon(Icons.report_problem_outlined, color: kPrimary),
                    title: Text(t("reclamos"), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _openReclamosDrawer();
                    },
                  ),

                  // ✅ NORMATIVAS
                  ListTile(
                    leading: _isLoadingNormativas
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                          )
                        : const Icon(Icons.menu_book, color: kPrimary),
                    title: Text(t("normativas"), style: TextStyle(color: textColor)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _openNormativasDrawer();
                    },
                  ),

                  const Divider(),

                  // ✅ REDES SOCIALES
                  ExpansionTile(
                    leading: const Icon(Icons.share, color: kPrimary),
                    title: Text(t("social_networks"), style: TextStyle(color: textColor)),
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.music_note, color: kPrimary),
                        title: const Text("TikTok"),
                        onTap: () async {
                          await launchUrl(
                            Uri.parse("https://www.tiktok.com/@gamdecolcapirhua?is_from_webapp=1&sender_device=pc"),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.play_circle, color: kPrimary),
                        title: const Text("YouTube"),
                        onTap: () async {
                          await launchUrl(
                            Uri.parse("https://www.youtube.com/@gamdecolcapirhua"),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.facebook, color: kPrimary),
                        title: const Text("Facebook"),
                        onTap: () async {
                          await launchUrl(
                            Uri.parse("https://www.facebook.com/municipiodecolcapirhua"),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.camera_alt, color: kPrimary),
                        title: const Text("Instagram"),
                        onTap: () async {
                          await launchUrl(
                            Uri.parse("https://www.instagram.com/alcaldiadecolcapirhua"),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.close, color: kPrimary),
                        title: const Text("X"),
                        onTap: () async {
                          await launchUrl(
                            Uri.parse("https://x.com/GAMColcapirhua"),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                  ),

                  // ✅ PÁGINA OFICIAL
                  ListTile(
                    leading: const Icon(Icons.public, color: kPrimary),
                    title: Text(t("official_page"), style: TextStyle(color: textColor)),
                    onTap: () async {
                      await launchUrl(
                        Uri.parse("https://www.colcapirhua.gob.bo/"),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),

                  const Divider(),

                  // Idioma
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.language, color: kPrimary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t("language"), style: TextStyle(color: textColor))),
                        ValueListenableBuilder<String>(
                          valueListenable: AppSettings.language,
                          builder: (_, lang, __) {
                            return DropdownButton<String>(
                              value: lang,
                              dropdownColor: bg,
                              style: TextStyle(color: textColor),
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
                      ],
                    ),
                  ),

                  // Darkmode
                  SwitchListTile(
                    value: AppSettings.darkMode.value,
                    activeColor: kPrimary,
                    title: Text(t("darkmode"), style: TextStyle(color: textColor)),
                    onChanged: (v) => AppSettings.darkMode.value = v,
                    secondary: const Icon(Icons.dark_mode, color: kPrimary),
                  ),

                  // ✅ Radio configurable
                  ValueListenableBuilder<double>(
                    valueListenable: AppSettings.radiusMeters,
                    builder: (context, meters, _) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t("radius_title"), style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text("${t("radius_sub")}: ${meters.round()} m", style: TextStyle(color: subTextColor)),
                            Slider(
                              value: meters.clamp(50, 2000),
                              min: 50,
                              max: 2000,
                              divisions: 39,
                              activeColor: kPrimary,
                              onChanged: (v) => AppSettings.radiusMeters.value = v,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ✅ Centrar
                  ListTile(
                    leading: const Icon(Icons.center_focus_strong, color: kPrimary),
                    title: Text(t("center_title"), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
                    subtitle: ValueListenableBuilder<String>(
                      valueListenable: AppSettings.centerMode,
                      builder: (_, mode, __) {
                        return Text(
                          mode == "ubicacion" ? t("center_location") : t("center_colcapirhua"),
                          style: TextStyle(color: subTextColor),
                        );
                      },
                    ),
                    trailing: Icon(Icons.expand_more, color: textColor),
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
                  ),

                  // ✅ Acerca de
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: kPrimary),
                    title: Text(t("about"), style: TextStyle(color: textColor)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            title: Text(t("about_title")),
                            content: Text(t("about_body")),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}