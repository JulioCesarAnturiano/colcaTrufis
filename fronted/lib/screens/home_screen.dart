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
      _aplicarFiltroParadas(); // ✅ NUEVO
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
    await _loadGeoJsonZona();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _fetchSindicatos(),
        _fetchRadioTaxis(),
        _fetchTrufis(),
        _fetchParadasRadiotaxis(), // ✅ NUEVO
      ]);

      await _cargarTodasLasRutas();

      // ✅ obtenemos GPS al inicio (si se puede)
      await _getCurrentLocation();

      // ✅ Por defecto al entrar: centrar Colcapirhua (no mueve el geojson, solo el mapa)
      _mapController.move(_colcapirhuaCenter, _colcapirhuaZoom);

      // ✅ Importante: al entrar debe aplicar "cerca" si hay GPS
      _aplicarFiltroRutas();
      _aplicarFiltroParadas(); // ✅ NUEVO
    });
  }

  // ==========================
  // FETCH BASE
  // ==========================
  Future<void> _fetchSindicatos() async {
    try {
      final sindicatos = await _apiService.getSindicatos();
      if (!mounted) return;
      setState(() => _sindicatos = List<Map<String, dynamic>>.from(sindicatos));
    } catch (e) {
      print("Error fetching sindicatos: $e");
    }
  }

  Future<void> _fetchRadioTaxis() async {
    try {
      final radioTaxis = await _apiService.getRadioTaxis();
      if (!mounted) return;

      // ✅ NUEVO: cache de nombres por id
      _radiotaxiNameById.clear();
      for (final it in radioTaxis) {
        final id = int.tryParse((it["id"] ?? "").toString());
        final name = (it["nombre_comercial"] ?? "").toString();
        if (id != null && name.trim().isNotEmpty) {
          _radiotaxiNameById[id] = name;
        }
      }

      setState(() => _radioTaxis = List<Map<String, dynamic>>.from(radioTaxis));
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

  // ✅ NUEVO: fetch paradas de radiotaxis
  Future<void> _fetchParadasRadiotaxis() async {
    try {
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
      });

      _aplicarFiltroParadas();
    } catch (e) {
      print("Error fetching paradas: $e");
      if (!mounted) return;
      setState(() => _paradasRadiotaxis = []);
    }
  }

  // ==========================
  // ZONA COLCAPIRHUA (SIEMPRE)
  // ==========================
  Future<void> _loadGeoJsonZona() async {
    try {
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
      });
    } catch (e) {
      print("Error loading zona: $e");
      if (!mounted) return;
      setState(() {
        colcapirhuaPolygons = [];
        colcapirhuaLines = [];
      });
    }
  }

  // ==========================
  // PARSEO MANUAL GEOJSON (RUTAS)
  // ==========================
  /// Retorna: (polylines, idsPorPolyline)
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
            color: kAqua.withOpacity(0.95), // ✅ mismo color del label
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
      final geo = await _apiService.getGeoJsonTodasRutas();
      
      // ✅ CORRECCIÓN: verificar que geo tenga features
      if (geo == null || geo['features'] == null) {
        print("⚠️ GeoJSON vacío o sin features");
        _todasRutas = [];
        _polylineIdIndex = [];
        if (!mounted) return;
        setState(() {
          _rutasVisibles = [];
          _inicioFinMarkers = [];
          _routeLabelMarkers = [];
        });
        return;
      }

      final parsed = _polylinesFromGeoJsonWithIds(geo);

      // guardamos ids en "tag" paralelo (por índice) usando un map
      _todasRutas = parsed.polylines;
      _polylineIdIndex = parsed.ids;

      print("✅ Cargadas ${_todasRutas.length} rutas");

      if (!mounted) return;
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
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
      });
    }
  }

  // ✅ Guardamos idtrufi de cada polyline por índice
  List<int?> _polylineIdIndex = [];

  int? _idOfPolyline(Polyline pl) {
    // busca el índice del polyline exacto en _todasRutas o _rutasVisibles
    // (usa identidad por referencia cuando vienen de la lista)
    final idx = _rutasVisibles.indexOf(pl);
    if (idx >= 0 && idx < _polylineIdIndex.length) return _polylineIdIndex[idx];
    return null;
  }

  // ==========================
  // UBICACIÓN
  // ==========================
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _currentPosition = null);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (!mounted) return;
      setState(() => _currentPosition = pos);

      _recalcCircleRadiusPx(_mapController.camera.zoom);
    } catch (e) {
      print("Error getting location: $e");
      if (!mounted) return;
      setState(() => _currentPosition = null);
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

    // Si el usuario elige "todas"
    if (_routeFilterMode == RouteFilterMode.all) {
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
      });
      return;
    }

    // Modo "cerca": si no hay ubicación, mostramos todas (según tu regla anterior)
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
  // ✅ NUEVO: FILTRO (cerca/todas) - PARADAS
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

    // ✅ NUEVA LÓGICA:
    // Radiotaxis SIEMPRE muestran TODAS las paradas
    final todasLasParadas = _paradasRadiotaxis;

    setState(() {
      _paradasMarkers = _buildParadasMarkers(todasLasParadas);
      _paradasLabelMarkers = _buildParadasLabels(todasLasParadas);
    });
  }


  // ==========================
  // ✅ NUEVO: BUILD PARADAS MARKERS
  // ==========================
  List<Marker> _buildParadasMarkers(List<Map<String, dynamic>> paradas) {
    final markers = <Marker>[];

    for (final p in paradas) {
      final lat = double.tryParse((p["latitud"] ?? "").toString());
      final lng = double.tryParse((p["longitud"] ?? "").toString());
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 38,
          height: 38,
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
      );
    }

    return markers;
  }

  // ==========================
  // ✅ NUEVO: BUILD PARADAS LABELS (debajo del marker)
  // ==========================
  List<Marker> _buildParadasLabels(List<Map<String, dynamic>> paradas) {
    final markers = <Marker>[];

    for (final p in paradas) {
      final lat = double.tryParse((p["latitud"] ?? "").toString());
      final lng = double.tryParse((p["longitud"] ?? "").toString());
      if (lat == null || lng == null) continue;

      final radiotaxiId = int.tryParse((p["sindicato_radiotaxi_id"] ?? "").toString());
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
            offset: const Offset(0, 22), // ✅ lo baja debajo del punto
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
  // INICIO/FIN (igual que tu código)
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
  // ✅ Labels de rutas (nombre estilo pill, pequeño, verde agua)
  // ==========================
  List<Marker> _buildRouteLabels(List<Polyline> polylines) {
    final markers = <Marker>[];

    for (final pl in polylines) {
      if (pl.points.length < 2) continue;

      final id = _idOfPolyline(pl);
      final name = (id != null) ? (_trufiNameById[id] ?? "Línea $id") : null;
      if (name == null || name.trim().isEmpty) continue;

      final start = pl.points.first;

      // ✅ ancho adaptativo según texto (con límites)
      final estimatedWidth = 30 + 14 + (name.length * 6.4); // ✅ menos "por letra"
      final w = estimatedWidth.clamp(90.0, 200.0); // ✅ límites más pequeños

      markers.add(
        Marker(
          point: start, // ✅ ahora en el inicio
          width: w,
          height: 34,
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: const Offset(0, -18), // ✅ lo sube sobre el punto de inicio
            child: _routeNamePill(name),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _routeNamePill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), // ✅ menos padding
      decoration: BoxDecoration(
        color: kAqua.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10), // ✅ menos redondo
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_bus_filled, size: 14, color: Colors.white), // ✅ icono más chico
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11.5, // ✅ letra más chica
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================
  // MOSTRAR RUTA 1 TRUFI (mantienes tu lógica)
  // ==========================
  Future<void> _mostrarRutaDeUnTrufi(int idtrufi, {String? nombreLinea}) async {
    try {
      final geo = await _apiService.getGeoJsonPorTrufi(idtrufi);
      
      // ✅ CORRECCIÓN: verificar que geo tenga features
      if (geo == null || geo['features'] == null || (geo['features'] as List).isEmpty) {
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

      if (!mounted) return;
      setState(() {
        _selectedTrufiId = idtrufi;
        _selectedTrufiName = nombreLinea ?? _trufiNameById[idtrufi] ?? "Línea $idtrufi";

        _rutasVisibles = ruta;
        _polylineIdIndex = parsed.ids; // ✅ actualizar índice
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 1);

        // ✅ label del trufi seleccionado: se verá en la ruta también (más chico)
        _routeLabelMarkers = _buildRouteLabels(_rutasVisibles);
      });

      if (ruta.first.points.isNotEmpty) {
        _mapController.move(ruta.first.points.first, 14.8);
      }
    } catch (e) {
      print("Error mostrando ruta de trufi $idtrufi: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar la ruta de este trufi")),
      );
    }
  }

  // ==========================
  // CENTRADO (FAB depende del modo)
  // ==========================
  Future<void> _handleCenterFab() async {
    final mode = AppSettings.centerMode.value;

    if (mode == "ubicacion") {
      await _getCurrentLocation();
      _aplicarFiltroRutas();
      _aplicarFiltroParadas(); // ✅ NUEVO
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
  // ✅ CALL Radiotaxi
  // ==========================
  Future<void> _confirmAndCall(String rawPhone) async {
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
              backgroundColor: kPrimary, // tu verde/azul oscuro
              foregroundColor: const Color.fromARGB(255, 255, 255, 255), // ✅ texto blanco
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
  // ✅ NORMATIVAS MEJORADO
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

  Future<void> _openNormativasDrawer() async {
    try {
      final data = await _fetchNormativas();
      if (!mounted) return;

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
                            
                            // ✅ MEJORADO: mostrar titulo, descripcion y PDF
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
                                          style:ElevatedButton.styleFrom(
                                            backgroundColor: kPrimary, // tu verde/azul oscuro
                                            foregroundColor: const Color.fromARGB(255, 255, 255, 255), // ✅ texto blanco
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t("no_data"))),
      );
    }
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
                  // ✅ Logos intactos
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
                    // ✅ Mapa SIEMPRE visible
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
                        // ✅ TileLayer siempre
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.colcatrufis.app',
                          keepBuffer: 2,
                        ),

                        // ✅ Colcapirhua SIEMPRE
                        PolygonLayer(polygons: colcapirhuaPolygons),
                        if (colcapirhuaLines.isNotEmpty) PolylineLayer(polylines: colcapirhuaLines),

                        // ✅ círculo si hay GPS y modo cerca
                        if (_routeFilterMode == RouteFilterMode.nearby && _currentPosition != null)
                          CircleLayer(circles: _buildRadioCircle()),

                        // ✅ CONDICIONAL: mostrar rutas O paradas según isTrufiSelected
                        if (isTrufiSelected) ...[
                          // TRUFIS: rutas visibles
                          PolylineLayer(polylines: _rutasVisibles),

                          // ✅ labels de ruta (nombre en pill)
                          if (_routeLabelMarkers.isNotEmpty) MarkerLayer(markers: _routeLabelMarkers),

                          // ✅ inicio/fin
                          if (_inicioFinMarkers.isNotEmpty) MarkerLayer(markers: _inicioFinMarkers),
                        ] else ...[
                          // RADIOTAXIS: paradas
                          if (_paradasMarkers.isNotEmpty) MarkerLayer(markers: _paradasMarkers),

                          // ✅ labels de paradas (nombre debajo)
                          if (_paradasLabelMarkers.isNotEmpty) MarkerLayer(markers: _paradasLabelMarkers),
                        ],

                        // ✅ ubicación actual
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

                    // ✅ Selector de rutas (igual que tu idea)
                    Positioned(
                      left: 16,
                      bottom: 22,
                      child: _routesFilterDropdown(isDarkMode),
                    ),

                    // ✅ Card del trufi seleccionado (la mantengo)
                    if (_selectedTrufiName != null && _selectedTrufiName!.trim().isNotEmpty)
                      Positioned(
                        left: 16,
                        top: 90,
                        child: _selectedTrufiCard(isDarkMode),
                      ),

                    // Botones flotantes
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
                              // ✅ al cambiar a trufi, aplicar filtro de rutas
                              _aplicarFiltroRutas();
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
                              // ✅ al cambiar a radiotaxi, aplicar filtro de paradas
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
                            child: const Icon(Icons.my_location, color: kPrimary),
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
          const Icon(Icons.route, color: kPrimary),
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
              _aplicarFiltroParadas(); // ✅ NUEVO
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
  // ==========================
  Widget _selectedTrufiCard(bool isDarkMode) {
    final bg = (isDarkMode ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.92);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
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
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                _selectedTrufiId = null;
                _selectedTrufiName = null;
              });
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
                child: dataList.isEmpty
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

                              // ✅ Radiotaxi: preguntar si quiere llamar
                              if (!isLookingForTrufi) {
                                final phone = (item["telefono_base"] ?? "").toString();
                                await _confirmAndCall(phone);
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
  // Drawer: orden + ajustes afuera + normativas + acerca de
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
                    children: _sindicatos.map((s) {
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
                    children: _radioTaxis.map((rt) {
                      final phone = (rt["telefono_base"] ?? "").toString();

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.phone, color: kPrimary),
                        title: Text(rt["nombre_comercial"] ?? "Radiotaxi", style: TextStyle(color: textColor)),
                        subtitle: Text('${t("base")}: $phone', style: TextStyle(color: subTextColor)),
                        onTap: () async {
                          Navigator.pop(context);
                          setState(() => isTrufiSelected = false);
                          await _confirmAndCall(phone);
                        },
                      );
                    }).toList(),
                  ),

                  const Divider(),

                  // ✅ NORMATIVAS
                  ListTile(
                    leading: const Icon(Icons.menu_book, color: kPrimary),
                    title: Text(t("normativas"), style: TextStyle(color: textColor)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _openNormativasDrawer();
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
                              divisions: 39, // saltos de 50
                              activeColor: kPrimary,
                              onChanged: (v) => AppSettings.radiusMeters.value = v,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ✅ Centrar: ahora es botón y abre opciones
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