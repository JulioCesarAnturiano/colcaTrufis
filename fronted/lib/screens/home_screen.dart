import 'dart:convert';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';

// Colores pedidos
const Color kPrimary = Color(0xFF09596E); // #09596e
const Color kPrimaryDark = Color(0xFF064656);

class AppSettings {
  static final ValueNotifier<String> language = ValueNotifier<String>("es");
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> centerOnStart = ValueNotifier<bool>(false);
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isTrufiSelected = true;
  final MapController _mapController = MapController();

  // ✅ Para Colcapirhua: usamos GeoJsonParser (sirve bien para polígono/linea)
  final GeoJsonParser _zonaParser = GeoJsonParser();

  // Api
  final ApiService _apiService = ApiService(baseUrl: "http://localhost:8000/api");

  Position? _currentPosition;

  List<Map<String, dynamic>> _sindicatos = [];
  List<Map<String, dynamic>> _radioTaxis = [];
  List<Map<String, dynamic>> _trufis = [];

  // ✅ Zona Colcapirhua SIEMPRE visible
  List<Polygon> colcapirhuaPolygons = [];
  List<Polyline> colcapirhuaLines = []; // <-- por si tu geojson es LineString

  // ✅ Rutas (manual)
  List<Polyline> _todasRutas = [];
  List<Polyline> _rutasVisibles = [];
  List<Marker> _inicioFinMarkers = [];

  // ✅ Radio real
  static const double _radioCercaniaMetros = 250.0;

  // ✅ Círculo 50m: en web normalmente CircleMarker.radius es en PX.
  // Lo convertimos de metros -> pixeles según zoom/latitud
  double _circleRadiusPx = 30.0;
  double? _lastZoomForCircle;

  bool _alreadyInit = false;

  // ==========================
  // Traducciones
  // ==========================
  String t(String key) {
    final lang = AppSettings.language.value;
    final dict = <String, Map<String, String>>{
      "menu": {"es": "Menú", "en": "Menu", "qu": "Menu"},
      "sindicatos": {"es": "Sindicatos", "en": "Unions", "qu": "Sindicato-kuna"},
      "radiotaxis": {"es": "Radiotaxis", "en": "Radio taxis", "qu": "RadioTaxi-kuna"},
      "settings": {"es": "Configuración", "en": "Settings", "qu": "Ajuste-kuna"},
      "language": {"es": "Idioma", "en": "Language", "qu": "Simi"},
      "darkmode": {"es": "Modo oscuro", "en": "Dark mode", "qu": "Yanay mode"},
      "center_on_start": {"es": "Centrar al abrir", "en": "Center on start", "qu": "Qallariypi ch'uyanchay"},
      "base": {"es": "Base", "en": "Base", "qu": "Base"},
      "selected": {"es": "Seleccionaste", "en": "You selected", "qu": "Akllarirqanki"},
      "id": {"es": "ID", "en": "ID", "qu": "ID"},
      "of_colcapirhua": {"es": "de Colcapirhua", "en": "in Colcapirhua", "qu": "Colcapirhua-pi"},
      "trufi": {"es": "Trufi", "en": "Trufi", "qu": "Trufi"},
      "radiotaxi": {"es": "Radiotaxi", "en": "Radio taxi", "qu": "RadioTaxi"},
      "nearby_routes": {"es": "Rutas cercanas (250m)", "en": "Nearby routes (250m)", "qu": "250m ñan-kuna"},
      "all_routes": {"es": "Todas las rutas", "en": "All routes", "qu": "Llapan ñan-kuna"},
      "location_off": {"es": "Ubicación apagada: mostrando todas", "en": "Location off: showing all", "qu": "GPS mana llamk'anchu"},
      "location_on": {"es": "Mostrando rutas dentro de 250m", "en": "Showing routes within 250m", "qu": "250m ukhupi"},
      "no_route": {"es": "No se encontró ruta", "en": "Route not found", "qu": "Ñan mana tarikunchu"},
      "no_data": {"es": "Sin datos", "en": "No data", "qu": "Mana datos"},
    };
    return dict[key]?[lang] ?? dict[key]?["es"] ?? key;
  }

  // ==========================
  // INIT
  // ==========================
  @override
  void initState() {
    super.initState();
    if (_alreadyInit) return;
    _alreadyInit = true;
    _initAll();
  }

  Future<void> _initAll() async {
    await _loadGeoJsonZona();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _fetchSindicatos(),
        _fetchRadioTaxis(),
        _fetchTrufis(),
      ]);

      await _cargarTodasLasRutas();
      await _getCurrentLocation(); // puede quedar null

      _aplicarFiltroRutas();

      if (AppSettings.centerOnStart.value) {
        _mapController.move(const LatLng(-17.3860, -66.2340), 13);
      }
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
    } catch (_) {}
  }

  Future<void> _fetchRadioTaxis() async {
    try {
      final radioTaxis = await _apiService.getRadioTaxis();
      if (!mounted) return;
      setState(() => _radioTaxis = List<Map<String, dynamic>>.from(radioTaxis));
    } catch (_) {}
  }

  Future<void> _fetchTrufis() async {
    try {
      final trufis = await _apiService.getTrufis();
      if (!mounted) return;
      setState(() => _trufis = List<Map<String, dynamic>>.from(trufis));
    } catch (_) {}
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
        // Si tu geojson trae Polygon/MultiPolygon
        colcapirhuaPolygons = _zonaParser.polygons.map((p) {
          return Polygon(
            points: p.points,
            color: kPrimary.withOpacity(0.15),
            borderColor: kPrimary.withOpacity(0.85),
            borderStrokeWidth: 3.0,
            isFilled: true,
          );
        }).toList();

        // ✅ Si tu geojson trae LineString (bordes)
        colcapirhuaLines = _zonaParser.polylines.map((l) {
          return Polyline(
            points: l.points,
            strokeWidth: 3.5,
            color: kPrimary.withOpacity(0.95),
          );
        }).toList();
      });
    } catch (e) {
      // print("Error GeoJSON Zona: $e");
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
  List<Polyline> _polylinesFromGeoJson(Map<String, dynamic> geo) {
    final features = (geo['features'] as List? ?? []);
    final polylines = <Polyline>[];

    for (final f in features) {
      if (f is! Map) continue;
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
            strokeWidth: 5,
            color: Colors.blueAccent,
            borderColor: Colors.blueGrey.shade900,
            borderStrokeWidth: 2,
          ),
        );
      }
    }

    return polylines;
  }

  // ==========================
  // CARGAR TODAS LAS RUTAS
  // ==========================
  Future<void> _cargarTodasLasRutas() async {
    try {
      final geo = await _apiService.getGeoJsonTodasRutas();
      _todasRutas = _polylinesFromGeoJson(geo);

      if (!mounted) return;
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
      });
    } catch (_) {
      _todasRutas = [];
      if (!mounted) return;
      setState(() {
        _rutasVisibles = [];
        _inicioFinMarkers = [];
      });
    }
  }

  // ==========================
  // UBICACIÓN (WEB: requiere permisos)
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

      // ✅ recalcula círculo 50m en px según zoom actual (flutter_map 7: camera.zoom existe)
      _recalcCircleRadiusPx(_mapController.camera.zoom);
    } catch (_) {
      if (!mounted) return;
      setState(() => _currentPosition = null);
    }
  }

  // ==========================
  // 50m REALES -> pixeles según zoom/lat (para Web)
  // ==========================
  double _metersToPixels(double meters, double latitude, double zoom) {
    // WebMercator: metros por pixel
    final latRad = latitude * Math.pi / 180.0;
    final metersPerPixel = 156543.03392 * Math.cos(latRad) / Math.pow(2, zoom);
    return meters / metersPerPixel;
  }

  void _recalcCircleRadiusPx(double zoom) {
    if (_currentPosition == null) return;

    // anti-spam
    if (_lastZoomForCircle != null && (zoom - _lastZoomForCircle!).abs() < 0.05) return;
    _lastZoomForCircle = zoom;

    final px = _metersToPixels(_radioCercaniaMetros, _currentPosition!.latitude, zoom);
    final safePx = px.clamp(6.0, 600.0);

    if (!mounted) return;
    setState(() => _circleRadiusPx = safePx);
  }

  // Distancia mínima aproximada por puntos (suficiente para 50m)
  double _minDistToPolylineMeters(LatLng pos, List<LatLng> pts) {
    double minD = double.infinity;
    for (final p in pts) {
      final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, p.latitude, p.longitude);
      if (d < minD) minD = d;
    }
    return minD;
  }

  // ==========================
  // FILTRO 50m
  // ==========================
  void _aplicarFiltroRutas() {
    if (_todasRutas.isEmpty) {
      setState(() {
        _rutasVisibles = [];
        _inicioFinMarkers = [];
      });
      return;
    }

    // sin ubicación => todas
    if (_currentPosition == null) {
      setState(() {
        _rutasVisibles = _todasRutas;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
      });
      return;
    }

    final user = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    final cerca = _todasRutas.where((pl) {
      final d = _minDistToPolylineMeters(user, pl.points);
      return d <= _radioCercaniaMetros;
    }).toList();

    setState(() {
      _rutasVisibles = cerca.isNotEmpty ? cerca : _todasRutas;
      _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 30);
    });
  }

  // ==========================
  // CÍRCULO 50m (visual)
  // ==========================
  List<CircleMarker> _buildRadioCircle() {
    if (_currentPosition == null) return [];
    return [
      CircleMarker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: _circleRadiusPx, // ✅ 50m reales convertido a px
        color: kPrimary.withOpacity(0.12),
        borderColor: kPrimary.withOpacity(0.55),
        borderStrokeWidth: 2,
      ),
    ];
  }

  // ==========================
  // INICIO/FIN PROFESIONAL
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
          width: 44,
          height: 44,
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
          width: 44,
          height: 44,
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
        child: Center(child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
  }

  // ==========================
  // MOSTRAR RUTA 1 TRUFI
  // ==========================
  Future<void> _mostrarRutaDeUnTrufi(int idtrufi) async {
    try {
      final geo = await _apiService.getGeoJsonPorTrufi(idtrufi);
      final ruta = _polylinesFromGeoJson(geo);

      if (ruta.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("no_route"))));
        return;
      }

      setState(() {
        _rutasVisibles = ruta;
        _inicioFinMarkers = _buildInicioFinMarkers(_rutasVisibles, maxRutas: 1);
      });

      if (ruta.first.points.isNotEmpty) {
        _mapController.move(ruta.first.points.first, 14.8);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar la ruta de este trufi")),
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

                        // ✅ Para que el círculo 50m cambie con zoom (web)
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

                        // ✅ Colcapirhua SIEMPRE:
                        // 1) Polygon si existe
                        PolygonLayer(polygons: colcapirhuaPolygons),

                        // 2) y también líneas si existe LineString
                        if (colcapirhuaLines.isNotEmpty)
                          PolylineLayer(polylines: colcapirhuaLines),

                        // ✅ círculo 50m
                        if (_currentPosition != null) CircleLayer(circles: _buildRadioCircle()),

                        // ✅ rutas visibles
                        PolylineLayer(polylines: _rutasVisibles),

                        // ✅ inicio/fin
                        if (_inicioFinMarkers.isNotEmpty) MarkerLayer(markers: _inicioFinMarkers),

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
                              setState(() => isTrufiSelected = true);
                              _showFullWidthBottomSheet(context, t("trufi"));
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildMapButton3D(
                            icon: Icons.local_taxi,
                            isActive: !isTrufiSelected,
                            onPressed: () {
                              setState(() => isTrufiSelected = false);
                              _showFullWidthBottomSheet(context, t("radiotaxi"));
                            },
                          ),
                          const SizedBox(height: 25),
                          FloatingActionButton(
                            mini: true,
                            heroTag: "btnLocation",
                            backgroundColor: Colors.white,
                            onPressed: () async {
                              await _getCurrentLocation();
                              _aplicarFiltroRutas();

                              if (_currentPosition != null) {
                                _mapController.move(
                                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  15,
                                );
                              }
                            },
                            child: const Icon(Icons.my_location, color: kPrimary),
                          ),
                        ],
                      ),
                    ),

                    // Chip estado
                    Positioned(
                      left: 16,
                      bottom: 22,
                      child: _routesModeChip(isDarkMode),
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

  Widget _routesModeChip(bool isDarkMode) {
    final text = _currentPosition == null ? t("all_routes") : t("nearby_routes");
    final subtitle = _currentPosition == null ? t("location_off") : t("location_on");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isDarkMode ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_currentPosition == null ? Icons.map_outlined : Icons.my_location, color: kPrimary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)),
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

  // BottomSheet
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
                                isLookingForTrufi ? Icons.directions_bus_filled : Icons.local_taxi,
                                color: kPrimary,
                              ),
                            ),
                            title: Text(titulo, style: TextStyle(color: textColor)),
                            subtitle: Text(subtitulo, style: TextStyle(color: subTextColor)),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${t("selected")} $titulo')),
                              );

                              if (isLookingForTrufi && item["idtrufi"] != null) {
                                _mostrarRutaDeUnTrufi(int.parse(item["idtrufi"].toString()));
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

  // Drawer con settings (no cambié tu lógica, solo la mantengo como estaba)
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

                  // mismos botones que flotantes
                  ListTile(
                    leading: const Icon(Icons.directions_bus, color: kPrimary),
                    title: Text(t("trufi"), style: TextStyle(color: textColor)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => isTrufiSelected = true);
                      _showFullWidthBottomSheet(context, t("trufi"));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_taxi, color: kPrimary),
                    title: Text(t("radiotaxi"), style: TextStyle(color: textColor)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => isTrufiSelected = false);
                      _showFullWidthBottomSheet(context, t("radiotaxi"));
                    },
                  ),

                  const Divider(),

                  ExpansionTile(
                    leading: const Icon(Icons.settings, color: kPrimary),
                    title: Text(t("settings"), style: TextStyle(color: textColor)),
                    children: [
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
                      SwitchListTile(
                        value: AppSettings.darkMode.value,
                        activeColor: kPrimary,
                        title: Text(t("darkmode"), style: TextStyle(color: textColor)),
                        subtitle: Text(AppSettings.darkMode.value ? "ON" : "OFF", style: TextStyle(color: subTextColor)),
                        onChanged: (v) => AppSettings.darkMode.value = v,
                        secondary: const Icon(Icons.dark_mode, color: kPrimary),
                      ),
                      SwitchListTile(
                        value: AppSettings.centerOnStart.value,
                        activeColor: kPrimary,
                        title: Text(t("center_on_start"), style: TextStyle(color: textColor)),
                        subtitle: Text("Colcapirhua", style: TextStyle(color: subTextColor)),
                        onChanged: (v) => AppSettings.centerOnStart.value = v,
                        secondary: const Icon(Icons.center_focus_strong, color: kPrimary),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),

                  const Divider(),

                  // sindicatos
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
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.directions_bus, color: kPrimary),
                            title: Text("${tr["nom_linea"]}", style: TextStyle(color: textColor)),
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => isTrufiSelected = true);
                              _mostrarRutaDeUnTrufi(int.parse(tr["idtrufi"].toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${t("selected")} ${tr["nom_linea"]}')),
                              );
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),

                  // radiotaxis
                  ExpansionTile(
                    leading: const Icon(Icons.local_taxi, color: kPrimary),
                    title: Text(t("radiotaxis"), style: TextStyle(color: textColor)),
                    children: _radioTaxis.map((rt) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.phone, color: kPrimary),
                        title: Text(rt["nombre_comercial"] ?? "Radiotaxi", style: TextStyle(color: textColor)),
                        subtitle: Text(
                          '${t("base")}: ${rt["telefono_base"] ?? ""}',
                          style: TextStyle(color: subTextColor),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Radiotaxi: ${rt["nombre_comercial"]}")),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
