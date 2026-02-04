import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import '../services/api_service.dart';  // Importamos el ApiService

// Colores pedidos
const Color kPrimary = Color(0xFF09596E);      // #09596e
const Color kPrimaryDark = Color(0xFF064656);  // un poco más oscuro (degradado)

// ✅ Settings globales (para TODA la app)
// Otras pantallas podrán importar este archivo y usar AppSettings.language/darkMode
class AppSettings {
  static final ValueNotifier<String> language = ValueNotifier<String>("es"); // es|en|qu
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
  Position? _currentPosition;
  final GeoJsonParser geoJsonParser = GeoJsonParser();

  // Conexión con el ApiService
  final ApiService _apiService = ApiService(baseUrl: 'http://localhost:8000/api');
  List<Map<String, dynamic>> _sindicatos = [];
  List<Map<String, dynamic>> _radioTaxis = [];
  List<Map<String, dynamic>> _trufis = [];
  List<Map<String, dynamic>> _trufiRutas = [];

  // Polígonos
  List<Polygon> colcapirhuaPolygons = [];

  // ✅ Traducciones (corregidas) para TODA la pantalla
  String t(String key) {
    final lang = AppSettings.language.value;

    final Map<String, Map<String, String>> dict = {
      // Drawer/Settings
      "menu": {"es": "Menú", "en": "Menu", "qu": "Menu"},
      "sindicatos": {"es": "Sindicatos", "en": "Unions", "qu": "Sindicato-kuna"},
      "radiotaxis": {"es": "Radiotaxis", "en": "Radio taxis", "qu": "RadioTaxi-kuna"},
      "settings": {"es": "Configuración", "en": "Settings", "qu": "Ajuste-kuna"},
      "language": {"es": "Idioma", "en": "Language", "qu": "Simi"},
      "darkmode": {"es": "Modo oscuro", "en": "Dark mode", "qu": "Yanay mode"},
      "center_on_start": {"es": "Centrar al abrir", "en": "Center on start", "qu": "Qallariypi ch'uyanchay"},
      "about": {"es": "Acerca de", "en": "About", "qu": "Imamanta"},
      "base": {"es": "Base", "en": "Base", "qu": "Base"},
      "selected": {"es": "Seleccionaste", "en": "You selected", "qu": "Akllarirqanki"},
      "id": {"es": "ID", "en": "ID", "qu": "ID"},

      // Home/Bottomsheet
      "of_colcapirhua": {"es": "de Colcapirhua", "en": "in Colcapirhua", "qu": "Colcapirhua-pi"},
      "available_each": {"es": "Disponible cada 10 min", "en": "Available every 10 min", "qu": "Sapa 10 min kachkan"},
      "trufi": {"es": "Trufi", "en": "Trufi", "qu": "Trufi"},
      "radiotaxi": {"es": "Radiotaxi", "en": "Radio taxi", "qu": "RadioTaxi"},
    };

    return dict[key]?[lang] ?? dict[key]?["es"] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadGeoJson();
    _fetchSindicatos(); // Obtener los sindicatos desde el backend
    _fetchRadioTaxis(); // Obtener los radiotaxis desde el backend
    _fetchTrufis(); // Obtener los trufis desde el backend
    _fetchTrufiRutas(); // Obtener las rutas de los trufis desde el backend

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppSettings.centerOnStart.value) {
        _mapController.move(LatLng(-17.3860, -66.2340), 13);
      }
    });
  }

  // Fetch sindicatos desde el API
  Future<void> _fetchSindicatos() async {
    try {
      final sindicatos = await _apiService.getSindicatos();
      setState(() {
        _sindicatos = List<Map<String, dynamic>>.from(sindicatos);
      });
    } catch (e) {
      print("Error obteniendo sindicatos: $e");
    }
  }

  // Fetch radiotaxis desde el API
  Future<void> _fetchRadioTaxis() async {
    try {
      final radioTaxis = await _apiService.getRadioTaxis();
      setState(() {
        _radioTaxis = List<Map<String, dynamic>>.from(radioTaxis);
      });
    } catch (e) {
      print("Error obteniendo radiotaxis: $e");
    }
  }

  // Fetch trufis desde el API
  Future<void> _fetchTrufis() async {
    try {
      final trufis = await _apiService.getTrufis();
      setState(() {
        _trufis = List<Map<String, dynamic>>.from(trufis);
      });
    } catch (e) {
      print("Error obteniendo trufis: $e");
    }
  }

  // Fetch trufi rutas desde el API
  Future<void> _fetchTrufiRutas() async {
    try {
      final trufiRutas = await _apiService.getTrufiRutas(1); // Ejemplo con idtrufi = 1
      setState(() {
        _trufiRutas = List<Map<String, dynamic>>.from(trufiRutas);
      });
    } catch (e) {
      print("Error obteniendo rutas de trufis: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      print("Error ubicación: $e");
    }
  }

  Future<void> _loadGeoJson() async {
    try {
      final String response = await rootBundle.loadString('assets/geojson/colcapirhua.geojson');
      geoJsonParser.parseGeoJsonAsString(response);

      setState(() {
        colcapirhuaPolygons = geoJsonParser.polygons.map((p) {
          return Polygon(
            points: p.points,
            color: kPrimary.withOpacity(0.3),
            borderColor: kPrimary,
            borderStrokeWidth: 6.0,
            isFilled: true,
          );
        }).toList();
      });
    } catch (e) {
      print("Error GeoJSON: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchSindicatos();  // Llama a la función para obtener los sindicatos cuando la pantalla esté activa
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
                          kPrimaryDark.withOpacity(1),
                          kPrimary.withOpacity(0.78),
                        ],
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
                        initialCenter: LatLng(-17.3939, -66.2386),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.colcatrufis.app',
                        ),
                        PolygonLayer(polygons: geoJsonParser.polygons),
                        PolylineLayer(polylines: geoJsonParser.polylines),
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

                    // BOTONES LATERALES DERECHOS
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
                            icon: Icons.directions_car,
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
                            onPressed: () {
                              _mapController.move(LatLng(-17.3860, -66.2340), 13);
                            },
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

  // ✅ Botón 3D (mismo color, mejor look)
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
              ? LinearGradient(
                  colors: [
                    kPrimaryDark,
                    kPrimary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.98),
                    Colors.grey.shade200.withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
            // brillo sutil arriba (efecto relieve)
            BoxShadow(
              color: Colors.white.withOpacity(isActive ? 0.10 : 0.35),
              blurRadius: 8,
              offset: const Offset(-2, -2),
            ),
          ],
          border: Border.all(
            color: isActive ? Colors.white.withOpacity(0.12) : Colors.black12,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive ? Colors.white : kPrimary,
            size: 35,
          ),
        ),
      ),
    );
  }

  void _showFullWidthBottomSheet(BuildContext context, String type) {
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
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "$type ${t("of_colcapirhua")}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary),
              ),
              const Divider(),
              SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: _trufis.length, // Ahora el número de elementos es dinámico basado en los trufis obtenidos
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimary.withOpacity(0.12),
                      child: Icon(
                        type == t("trufi") ? Icons.bus_alert : Icons.local_taxi,
                        color: kPrimary,
                      ),
                    ),
                    title: Text(_trufis[index]["nom_linea"], style: TextStyle(color: textColor)),
                    subtitle: Text("${t("id")}: ${_trufis[index]["idtrufi"]}", style: TextStyle(color: subTextColor)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${t("selected")} ${_trufis[index]["nom_linea"]}')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Drawer _buildSidebarDrawer() {
    final drawerWidth = MediaQuery.of(context).size.width * 0.7;

    return Drawer(
      width: drawerWidth,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ✅ header con degradado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryDark.withOpacity(0.98),
                    kPrimary.withOpacity(0.92),
                  ],
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Sindicatos
            ExpansionTile(
              leading: const Icon(Icons.groups, color: kPrimary),
              title: Text(t("sindicatos")),
              children: _sindicatos.map((s) {
                final String sindicatoNombre = s["nombre"];
                final List trufis = (s["trufis"] as List);

                return ExpansionTile(
                  leading: const Icon(Icons.account_balance, color: kPrimary),
                  title: Text(sindicatoNombre),
                  children: trufis.map<Widget>((tr) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.directions_bus, color: kPrimary),
                      title: Text("${tr["nom_linea"]}"),
                      subtitle: Text("${t("id")}: ${tr["idtrufi"]}"),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${t("selected")} ${tr["nom_linea"]}')),
                        );
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            ),

            // Radiotaxis
            ExpansionTile(
              leading: const Icon(Icons.local_taxi, color: kPrimary),
              title: Text(t("radiotaxis")),
              children: _radioTaxis.map((rt) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.phone, color: kPrimary),
                  title: Text(rt["nombre_comercial"]),
                  subtitle: Text('${t("base")}: ${rt["telefono_base"]}'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Radiotaxi: ${rt["nombre_comercial"]}")),
                    );
                  },
                );
              }).toList(),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                t("settings"),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppSettings.darkMode.value ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
