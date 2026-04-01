# Manual Técnico — ColcaTrufis Frontend
### Documentación Técnica de la Aplicación Móvil Flutter

---

**Versión:** 1.0.0  
**SDK:** Flutter ≥3.0.0 <4.0.0  
**Fecha:** Abril 2026  
**Tipo de Proyecto:** Aplicación Móvil Multiplataforma (Android/iOS/Web)

---

## Tabla de Contenido

1. [Visión General de la Arquitectura](#1-visión-general-de-la-arquitectura)
2. [Estructura del Proyecto](#2-estructura-del-proyecto)
3. [Stack Tecnológico y Dependencias](#3-stack-tecnológico-y-dependencias)
4. [Configuración del Entorno](#4-configuración-del-entorno)
5. [Capa de Configuración — `config/`](#5-capa-de-configuración--config)
6. [Capa de Modelos — `models/`](#6-capa-de-modelos--models)
7. [Capa de Servicios — `services/`](#7-capa-de-servicios--services)
8. [Capa de Pantallas — `screens/`](#8-capa-de-pantallas--screens)
9. [Gestión del Estado](#9-gestión-del-estado)
10. [Comunicación con la API REST](#10-comunicación-con-la-api-rest)
11. [Sistema de Internacionalización (i18n)](#11-sistema-de-internacionalización-i18n)
12. [Sistema de Geolocalización](#12-sistema-de-geolocalización)
13. [Renderización del Mapa](#13-renderización-del-mapa)
14. [Sistema de Caché y Persistencia](#14-sistema-de-caché-y-persistencia)
15. [Assets y Recursos](#15-assets-y-recursos)
16. [Compilación y Despliegue](#16-compilación-y-despliegue)
17. [Guía de Mantenimiento](#17-guía-de-mantenimiento)
18. [Diagramas de Arquitectura](#18-diagramas-de-arquitectura)

---

## 1. Visión General de la Arquitectura

ColcaTrufis Frontend es una aplicación Flutter que sigue una arquitectura **monolítica por capas** organizada en:

```
┌─────────────────────────────────────────┐
│            PANTALLAS (screens/)         │  ← UI + Lógica de presentación
├─────────────────────────────────────────┤
│            SERVICIOS (services/)        │  ← Lógica de negocio + API
├─────────────────────────────────────────┤
│            MODELOS (models/)            │  ← Entidades de datos
├─────────────────────────────────────────┤
│         CONFIGURACIÓN (config/)         │  ← Constantes y URLs
├─────────────────────────────────────────┤
│        FLUTTER FRAMEWORK + PLUGINS      │  ← flutter_map, geolocator, http
└─────────────────────────────────────────┘
```

**Patrón de comunicación:**
- El frontend consume una **API REST** (Laravel 11) en `https://moviruta.colcapirhua.gob.bo/api`
- Los datos del mapa se cargan desde **OpenStreetMap** (tiles) y un archivo **GeoJSON local** (límites de Colcapirhua)
- La geocodificación inversa usa **Nominatim (OSM)**
- Las traducciones usan **MyMemory Translation API**

---

## 2. Estructura del Proyecto

```
fronted/
├── lib/
│   ├── main.dart                          # Punto de entrada de la aplicación
│   ├── config/
│   │   └── app_config.dart                # URLs base, timeouts
│   ├── models/
│   │   ├── sindicato.dart                 # Modelo Sindicato
│   │   ├── sindicato_radiotaxi.dart       # Modelo SindicatoRadiotaxi
│   │   ├── trufi.dart                     # Modelo Trufi
│   │   └── trufi_ruta.dart                # Modelo TrufiRuta (coordenadas)
│   ├── screens/
│   │   ├── splash_screen.dart             # Pantalla de inicio animada
│   │   └── home_screen.dart               # Pantalla principal (~6329 líneas)
│   └── services/
│       ├── api_service.dart               # Cliente HTTP para API REST
│       └── translation_service.dart       # Servicio de traducción con caché
├── assets/
│   ├── images/
│   │   ├── logo_appp.png                  # Logo de la app
│   │   ├── logo_colca1.png                # Logo del municipio
│   │   └── pant.png                       # Imagen de referencia
│   └── geojson/
│       └── colcapirhua.geojson            # Límites geográficos del municipio
├── pubspec.yaml                           # Dependencias y configuración
├── .env                                   # Variables de entorno (local)
└── android/ ios/ web/ windows/ linux/ macos/  # Plataformas soportadas
```

---

## 3. Stack Tecnológico y Dependencias

### Dependencias Principales (`pubspec.yaml`)

| Paquete | Versión | Propósito |
|---|---|---|
| `flutter_map` | ^7.0.2 | Renderización de mapas OpenStreetMap |
| `latlong2` | ^0.9.0 | Coordenadas geográficas (LatLng) |
| `geolocator` | ^11.0.1 | Obtener ubicación GPS del usuario |
| `permission_handler` | ^11.3.1 | Gestión de permisos del sistema |
| `http` | ^1.6.0 | Cliente HTTP para consumo de API |
| `url_launcher` | ^6.3.0 | Abrir URLs y realizar llamadas |
| `shared_preferences` | ^2.2.3 | Persistencia local (historial, caché) |
| `flutter_map_geojson` | ^1.0.8 | Procesamiento de archivos GeoJSON |
| `provider` | ^6.1.1 | Gestión del estado (declarado, no usado activamente) |

### Dependencias de Desarrollo

| Paquete | Versión | Propósito |
|---|---|---|
| `flutter_test` | SDK | Testing framework |
| `flutter_lints` | ^3.0.0 | Buenas prácticas de codificación |

---

## 4. Configuración del Entorno

### Prerrequisitos
- Flutter SDK ≥3.0.0 <4.0.0
- Dart SDK (incluido con Flutter)
- Android Studio / VS Code con extensiones Flutter
- Dispositivo Android (físico o emulador) con API 26+

### Instalación

```bash
# 1. Clonar el repositorio
git clone <repo_url>
cd colcaTrufis/fronted

# 2. Instalar dependencias
flutter pub get

# 3. Verificar configuración
flutter doctor

# 4. Ejecutar en modo desarrollo
flutter run

# 5. Compilar APK de release
flutter build apk --release
```

### Variables de Entorno

Archivo `.env` (no se usa en runtime, referencia):
```
API_URL=http://localhost:8000
GOOGLE_MAPS_API_KEY=TU_CLAVE_DE_GOOGLE_MAPS
```

> **Nota:** La URL real del API se configura en `lib/config/app_config.dart`, NO en `.env`.

---

## 5. Capa de Configuración — `config/`

### `app_config.dart`

```dart
class AppConfig {
  static const String baseUrl = "https://moviruta.colcapirhua.gob.bo/api";
  static const int heavyApiTimeoutSeconds = 45;  // Ubicaciones, referencias
  static const int normalApiTimeoutSeconds = 15; // APIs ligeras
}
```

**Para cambiar entre entornos:**
- **Local:** `"http://localhost:8000/api"`
- **Producción:** `"https://moviruta.colcapirhua.gob.bo/api"`

---

## 6. Capa de Modelos — `models/`

### 6.1 `Sindicato`
Representa un sindicato de transporte.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `int` | Identificador único |
| `nombre` | `String` | Nombre del sindicato |
| `descripcion` | `String?` | Descripción opcional |

### 6.2 `SindicatoRadiotaxi`
Representa un sindicato de radiotaxi.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `int` | Identificador único |
| `nombreComercial` | `String` | Nombre comercial del radiotaxi |
| `telefonoBase` | `String` | Teléfono de contacto de la base |

### 6.3 `Trufi`
Representa una línea de trufi.

| Campo | Tipo | JSON Key | Descripción |
|---|---|---|---|
| `idtrufi` | `int` | `idtrufi` | ID único del trufi |
| `nomLinea` | `String` | `nom_linea` | Nombre de la línea |
| `costo` | `double` | `costo` | Costo del pasaje |
| `frecuencia` | `int` | `frecuencia` | Frecuencia en minutos |
| `descripcion` | `String?` | `descripcion` | Descripción opcional |
| `estado` | `bool` | `estado` | Activo (1) / Inactivo (0) |
| `sindicatoId` | `int?` | `sindicato_id` | FK al sindicato |

### 6.4 `TrufiRuta`
Representa un punto geográfico de una ruta de trufi.

| Campo | Tipo | JSON Key | Descripción |
|---|---|---|---|
| `idtrufi` | `int` | `idtrufi` | FK al trufi |
| `sindicatoRadiotaxiId` | `int?` | `sindicato_radiotaxi_id` | Si es punto de radiotaxi |
| `latitud` | `double` | `latitud` | Coordenada latitud |
| `longitud` | `double` | `longitud` | Coordenada longitud |
| `orden` | `int` | `orden` | Orden del punto en la ruta |
| `puntos` | `bool` | `puntos` | Si es punto de la ruta |
| `esParada` | `bool` | `es_parada` | Si es parada oficial |
| `estado` | `bool` | `estado` | Punto activo/inactivo |

**Métodos especiales:**
- `toLatLng()` → Convierte a `LatLng` para uso en mapas
- `isRadiotaxi` → Getter que verifica si el punto es de radiotaxi

---

## 7. Capa de Servicios — `services/`

### 7.1 `ApiService`

Cliente HTTP centralizado para comunicación con el backend Laravel.

**Constructor:** `ApiService({required String baseUrl})`

**Método base:** `_get(String path)` — Realiza peticiones GET con:
- Header `Accept: application/json`
- Timeout de 30 segundos
- Soporte para múltiples formatos de respuesta: `[...]`, `{data: [...]}`, `{success: true, data: [...]}`

#### Endpoints implementados:

| Método | Endpoint API | Descripción |
|---|---|---|
| `getSindicatos()` | `GET /sindicatos` | Lista sindicatos |
| `getRadioTaxis()` | `GET /sindicato-radiotaxis` | Lista radiotaxis |
| `getTrufis()` | `GET /trufis` | Lista trufis |
| `getTrufiRutas(id)` | `GET /trufis/{id}/rutas` | Puntos de ruta del trufi |
| `getGeoJsonPorTrufi(id)` | `GET /trufis/{id}/rutas/geojson` | GeoJSON de ruta individual |
| `getGeoJsonTodasRutas()` | `GET /trufis/rutas/geojson` | GeoJSON de todas las rutas |
| `getReferencias()` | `GET /referencias` | Todas las referencias |
| `getReferenciasDestrufi(id)` | `GET /trufis/{id}/referencias` | Referencias de un trufi |
| `getReferenciasDeRadiotaxi(id)` | `GET /radiotaxis/{id}/referencias` | Referencias de un radiotaxi |
| `getUbicacionesPorTrufi(id)` | `GET /trufis/{id}/ubicaciones` | Ubicaciones/vías del trufi |
| `getUbicacionesTodas()` | `GET /ubicaciones` | Todas las ubicaciones |
| `getTrufiHorario(id)` | `GET /trufis/{id}/horario` | Horario del trufi |

**Endpoints adicionales (llamados directamente con `http.get` en `home_screen.dart`):**

| Endpoint | Descripción |
|---|---|
| `GET /sindicatos` | Sindicatos con trufis anidados |
| `GET /radiotaxis` | Radiotaxis con detalle |
| `GET /trufis` | Trufis con detalle |
| `GET /radiotaxis/paradas` | Paradas georreferenciadas de radiotaxis |
| `GET /normativas` | Normativas vigentes |
| `GET /reclamos` | Números de reclamos |
| `POST /trufis/{id}/seleccion` | Registrar selección de trufi (analytics) |

### 7.2 `TranslationService`

Servicio de traducción con caché persistente usando MyMemory API.

**Características:**
- Caché en memoria (`Map<String, String>`) por idioma (en, qu)
- Persistencia en `SharedPreferences` con claves versionadas
- Peticiones paralelas en chunks de 8
- Throttling de 250ms entre chunks
- API: `https://api.mymemory.translated.net/get?q=...&langpair=es|{lang}`

> **Nota:** En la implementación actual, las traducciones están **hardcodeadas** en `_tDict` dentro de `home_screen.dart`, por lo que `TranslationService` está disponible pero no se utiliza activamente para la UI principal.

---

## 8. Capa de Pantallas — `screens/`

### 8.1 `SplashScreen`

**Archivo:** `splash_screen.dart` (188 líneas)  
**Tipo:** `StatefulWidget` con `SingleTickerProviderStateMixin`

**Animaciones:**
- **Fade in:** Opacidad 0→1 en el primer 60% de la animación
- **Scale:** Secuencia 0.82→1.04→1.0 (efecto zoom-in profesional)
- **Duración total:** 1400ms de animación + 2800ms antes de navegar

**Elementos visuales:**
- Fondo con `RadialGradient` (tonos teal `#0B4F62` → `#021A22`)
- Patrón de puntos sutil (`_GridPainter`, Custom Painter)
- Glow circular detrás del logo
- Logo: `assets/images/logo_appp.png`
- Versión: "v 1.0.0" con opacidad baja

**Navegación:** `Navigator.pushReplacementNamed(context, '/home')` después de 2.8s

### 8.2 `HomeScreen`

**Archivo:** `home_screen.dart` (~6329 líneas)  
**Tipo:** `StatefulWidget`

Este es el componente principal y más complejo de la aplicación. Contiene toda la lógica de UI, estado, y comunicación con el backend.

#### Variables de Estado Principales

| Variable | Tipo | Propósito |
|---|---|---|
| `isTrufiSelected` | `bool` | Modo actual (trufi vs radiotaxi) |
| `_currentPosition` | `Position?` | Posición GPS actual |
| `_sindicatos` | `List<Map>` | Datos de sindicatos |
| `_radioTaxis` | `List<Map>` | Datos de radiotaxis |
| `_trufis` | `List<Map>` | Datos de trufis |
| `_todasRutas` | `List<Polyline>` | Todas las rutas como polilíneas |
| `_rutasVisibles` | `List<Polyline>` | Rutas filtradas visibles |
| `_selectedTrufiId` | `int?` | Trufi seleccionado |
| `_selectedRadiotaxiId` | `int?` | Radiotaxi seleccionado |
| `_routeFilterMode` | `RouteFilterMode` | nearby / all |

#### Constantes de Diseño

```dart
const Color kPrimary     = Color(0xFF09596E);  // Teal principal
const Color kPrimaryDark = Color(0xFF064656);  // Teal oscuro
const Color kAqua        = Color(0xFF19B7B0);  // Aqua/acento
```

#### Ciclo de Vida

```
initState() → _initAll()
  ├── _cargarHistorial()        // Cargar historial desde SharedPreferences
  ├── _loadGeoJsonZona()        // Cargar GeoJSON de Colcapirhua
  └── PostFrame:
      ├── Future.wait([          // Cargar datos en paralelo
      │   _fetchSindicatos(),
      │   _fetchRadioTaxis(),
      │   _fetchTrufis(),
      │   _fetchParadasRadiotaxis()
      │ ])
      ├── _cargarTodasLasRutas() // Cargar GeoJSON de todas las rutas
      ├── _getCurrentLocation()  // Obtener GPS
      ├── _mapController.move()  // Centrar en Colcapirhua
      ├── _aplicarFiltroRutas()  // Filtrar rutas por radio
      └── _aplicarFiltroParadas() // Filtrar paradas por radio
```

#### Funciones Principales

| Función | Descripción |
|---|---|
| `_mostrarRutaDeUnTrufi(id)` | Carga y muestra ruta de un trufi (GeoJSON + ubicaciones + referencias en paralelo) |
| `_mostrarInfoRadiotaxi(id)` | Carga y muestra info de un radiotaxi |
| `_mostrarVentanaRecorrido()` | Modal con lista de calles/vías de la ruta |
| `_mostrarVentanaRadiotaxi()` | Modal con ubicación y teléfono del radiotaxi |
| `_aplicarFiltroRutas()` | Filtra rutas por proximidad o muestra todas |
| `_aplicarFiltroParadas()` | Filtra paradas de radiotaxis |
| `_buildSidebarDrawer()` | Construye el menú lateral completo |
| `_showFullWidthBottomSheet()` | Panel inferior con lista de trufis/radiotaxis |
| `_getCurrentLocation()` | Obtiene posición GPS con manejo de permisos |
| `_confirmAndCall(phone)` | Diálogo de confirmación + lanzamiente de llamada |

---

## 9. Gestión del Estado

La aplicación usa **gestión de estado local** con dos mecanismos:

### 9.1 `ValueNotifier` (Configuración Global)

```dart
class AppSettings {
  static final ValueNotifier<String> language = ValueNotifier("es");
  static final ValueNotifier<bool> darkMode = ValueNotifier(false);
  static final ValueNotifier<String> centerMode = ValueNotifier("colcapirhua");
  static final ValueNotifier<double> radiusMeters = ValueNotifier(250.0);
}
```

Se consumen via `ValueListenableBuilder` en el `build()`.

### 9.2 `setState()` (Estado Local del Widget)

Todo el estado de datos (trufis, rutas, marcadores, loading flags) se maneja con `setState()` directo en `_HomeScreenState`.

### 9.3 Listeners

- `_radiusListener` — Recalcula el radio visual y reafiltra rutas/paradas al cambiar `AppSettings.radiusMeters`
- `_langChangeListener` — Reconstruye la UI al cambiar el idioma

---

## 10. Comunicación con la API REST

### Flujo de petición típico

```
1. setState(() => _isLoading = true)
2. http.get(Uri.parse("${AppConfig.baseUrl}/endpoint"))
3. Parsing del body:
   - Si body es List → usar directamente
   - Si body es Map con "data" → extraer data
   - Si body tiene "data.{endpoint}" → extraer sublista
4. Convertir a List<Map<String, dynamic>>
5. setState(() { _data = result; _isLoading = false; })
```

### Manejo de errores

- Try/catch en todas las peticiones
- Fallback a lista vacía en caso de error
- Logs con emojis para depuración: `print("❌ Error: $e")`
- Re-throw en endpoints críticos (ubicaciones) para manejo en el caller

### Headers estándar

```dart
headers: {
  'Accept': 'application/json',
  'User-Agent': 'ColcaTrufisApp/1.0',  // Solo en endpoints pesados
}
```

---

## 11. Sistema de Internacionalización (i18n)

### Implementación

Las traducciones están **embebidas** en `_tDict` — un `Map<String, Map<String, String>>` estático con 3 idiomas: `es`, `en`, `qu`.

```dart
String t(String key) {
  final lang = AppSettings.language.value;
  return _tDict[lang]?[key] ?? _tDict['es']?[key] ?? key;
}
```

### Idiomas soportados

| Código | Idioma | Claves traducidas |
|---|---|---|
| `es` | Español | ~50 claves (base) |
| `en` | English | ~50 claves |
| `qu` | Quechua | ~50 claves |

### Agregar una nueva clave

1. Agregar en `_tDict['es']`: `"nueva_clave": "Texto español"`
2. Agregar en `_tDict['en']`: `"nueva_clave": "English text"`
3. Agregar en `_tDict['qu']`: `"nueva_clave": "Quechua text"`
4. Usar: `t("nueva_clave")`

---

## 12. Sistema de Geolocalización

### Permisos requeridos

**Android (`AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
```

### Flujo de obtención de ubicación

```
_getCurrentLocation()
├── Verificar si servicio de ubicación está habilitado
├── Verificar/solicitar permiso de ubicación
├── Geolocator.getCurrentPosition(accuracy: high)
├── Detectar si está fuera de los límites de Colcapirhua
├── Iniciar stream de posición para actualizaciones
└── Actualizar _currentPosition + recalcular filtros
```

### Detección "fuera de Colcapirhua"

Se calculan los bounds del polígono GeoJSON y se verifica si la posición del usuario está dentro de `[minLat, maxLat] × [minLng, maxLng]`.

---

## 13. Renderización del Mapa

### Provider de tiles
- **OpenStreetMap:** `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- User Agent: `com.colcatrufis.app`

### Capas del mapa (en orden de renderizado)

1. `TileLayer` — Mapa base OSM
2. `PolygonLayer` — Polígono de Colcapirhua (GeoJSON local)
3. `PolylineLayer` — Límites de Colcapirhua (contorno)
4. `CircleLayer` — Radio de búsqueda (si GPS activo + modo nearby)
5. `PolylineLayer` — Rutas de trufis visibles
6. `MarkerLayer` — Flechas de dirección en rutas
7. `MarkerLayer` — Labels de nombres de rutas
8. `MarkerLayer` — Marcadores inicio/fin de ruta
9. `MarkerLayer` — Puntos tappables en rutas
10. `MarkerLayer` — Paradas de radiotaxis (modo radiotaxi)
11. `MarkerLayer` — Ubicación del usuario (pin azul)
12. `MarkerLayer` — Marcador temporal (al tocar un punto)

### Parseo de GeoJSON

El archivo `colcapirhua.geojson` contiene `LineString` features que se:
1. Leen con `rootBundle.loadString()`
2. Parsean con `jsonDecode()`
3. Convierten a `List<LatLng>` juntando segmentos
4. Renderizan como `Polygon` (área) y `Polyline` (contorno)

---

## 14. Sistema de Caché y Persistencia

### SharedPreferences

| Clave | Tipo | Contenido |
|---|---|---|
| `historial_trufis_v1` | `StringList` | JSON serializado de `HistorialItem[]` |
| `historial_radiotaxis_v1` | `StringList` | JSON serializado de `HistorialItem[]` |
| `colcatrufi_transl_en_v2` | `String` | Cache de traducciones inglés (JSON) |
| `colcatrufi_transl_qu_v2` | `String` | Cache de traducciones quechua (JSON) |

### Límites del Historial
- Máximo **20 registros** por tipo (trufi/radiotaxi)
- FIFO: los más antiguos se eliminan al exceder el límite
- Los duplicados se mueven al inicio (actualización de timestamp)

---

## 15. Assets y Recursos

### Imágenes

| Archivo | Uso | Tamaño |
|---|---|---|
| `logo_appp.png` | Logo de la app (splash + appbar) | ~1.9 MB |
| `logo_colca1.png` | Logo del municipio (appbar + drawer) | ~2.2 MB |
| `pant.png` | Imagen de referencia | ~2.6 MB |

### GeoJSON

| Archivo | Uso | Tamaño |
|---|---|---|
| `colcapirhua.geojson` | Límites geográficos del municipio | ~32 KB |

### Registro en `pubspec.yaml`

```yaml
flutter:
  assets:
    - assets/images/
    - assets/geojson/colcapirhua.geojson
```

---

## 16. Compilación y Despliegue

### APK de Debug
```bash
flutter build apk --debug
# Salida: build/app/outputs/flutter-apk/app-debug.apk
```

### APK de Release
```bash
flutter build apk --release
# Salida: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (Play Store)
```bash
flutter build appbundle --release
# Salida: build/app/outputs/bundle/release/app-release.aab
```

### Cambiar API para producción
Editar `lib/config/app_config.dart`:
```dart
static const String baseUrl = "https://moviruta.colcapirhua.gob.bo/api";
```

---

## 17. Guía de Mantenimiento

### Agregar un nuevo endpoint API

1. Agregar método en `services/api_service.dart`:
   ```dart
   Future<List<dynamic>> getNuevoEndpoint() async {
     final data = await _get('/nuevo-endpoint');
     return (data as List).cast<dynamic>();
   }
   ```
2. Llamar desde `home_screen.dart` en el momento apropiado.

### Agregar una nueva pantalla

1. Crear archivo en `lib/screens/nueva_screen.dart`
2. Registrar ruta en `main.dart`:
   ```dart
   routes: {
     '/home': (context) => HomeScreen(),
     '/nueva': (context) => NuevaScreen(),
   }
   ```

### Agregar un nuevo idioma

1. Agregar entrada en `_tDict` de `home_screen.dart`:
   ```dart
   'pt': {
     "menu": "Menu",
     // ... todas las claves
   }
   ```
2. Agregar opción en el `DropdownButton` del drawer.

### Modificar el radio de búsqueda predeterminado

En `home_screen.dart`, clase `AppSettings`:
```dart
static final ValueNotifier<double> radiusMeters = ValueNotifier<double>(250.0);
// Cambiar 250.0 al valor deseado
```

---

## 18. Diagramas de Arquitectura

### Flujo de Datos

```
┌──────────┐     HTTP/JSON      ┌──────────────┐
│  Flutter  │ ←────────────────→ │  Laravel API  │
│  Frontend │                    │   Backend     │
└──────────┘                    └──────────────┘
     ↕                                ↕
┌──────────┐                    ┌──────────────┐
│   OSM    │ ← Tiles/Geocoding  │    MySQL      │
│  Servers │                    │   Database    │
└──────────┘                    └──────────────┘
```

### Flujo de Selección de Trufi

```
Usuario toca Trufi → _showFullWidthBottomSheet()
  → Selecciona línea → _mostrarRutaDeUnTrufi(id)
    ├── Future.wait([
    │   getGeoJsonPorTrufi(id),      // Ruta geográfica
    │   getUbicacionesPorTrufi(id),  // Calles/vías
    │   getReferenciasDestrufi(id)   // Referencias
    │ ])
    ├── Parsear GeoJSON → Polylines
    ├── Construir marcadores (inicio, fin, labels, flechas)
    ├── setState() con todos los datos
    ├── Mover mapa al inicio de ruta
    ├── _mostrarVentanaRecorrido()    // Modal con calles
    ├── _agregarAlHistorial()         // Persistir
    └── _registrarSeleccionTrufi()   // POST analytics
```

### Flujo de Selección de Radiotaxi

```
Usuario toca Radiotaxi → _showFullWidthBottomSheet()
  → Selecciona radiotaxi → _mostrarInfoRadiotaxi(id)
    ├── Buscar datos en _paradasRadiotaxis
    ├── Buscar teléfono en _radioTaxis
    ├── getReferenciasDeRadiotaxi(id)
    ├── setState() con datos
    ├── Mover mapa a ubicación
    ├── _mostrarVentanaRadiotaxi()  // Modal con ubicación + llamar
    └── _agregarAlHistorial()
```

---

*Manual Técnico — ColcaTrufis Frontend v1.0.0*  
*Última actualización: Abril 2026*
