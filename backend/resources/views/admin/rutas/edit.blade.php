@extends('admin.layout')

@section('title', 'Editar Ruta')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Editar Ruta</h2>
        <div class="ct-subtitle">
            Reemplazo De Ruta Existente. Puedes Editar La Ruta Precargada O Dibujar Una Nueva.
        </div>
    </div>

    <div class="alert alert-warning">
        Esta Acción Reemplazará La Ruta Anterior Al Guardar. Asegúrate De Dejar Solo Una Ruta.
    </div>

    <div class="card ct-stat-card">
        <div class="card-body">

            <form action="{{ route('admin.rutas.actualizar', ['idtrufi' => $idtrufi]) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Trufi</label>
                        <select name="idtrufi" class="form-select" disabled>
                            @foreach($trufis as $t)
                                <option value="{{ $t->idtrufi }}" @selected((int)$t->idtrufi === (int)$idtrufi)>
                                    {{ $t->idtrufi }} - {{ $t->nom_linea }}
                                </option>
                            @endforeach
                        </select>
                        <div class="form-text">
                            No Se Puede Cambiar El Trufi Al Editar. Si Quieres Otro, Crea Una Ruta Nueva.
                        </div>
                    </div>
                </div>

                {{-- Aquí se guardará el GeoJSON de la línea --}}
                <input type="hidden" name="geojson" id="geojson" required>

                <div class="alert alert-info">
                    Edita La Ruta Precargada O Dibuja Una Nueva En El Mapa. Usa La Herramienta De Línea.
                </div>

                <div id="map" class="ct-map"></div>

                <div class="d-flex gap-2 mt-3">
                    <button type="submit" class="btn ct-btn ct-btn-view">
                        Reemplazar Ruta
                    </button>

                    <a href="{{ route('admin.rutas.index') }}" class="btn ct-btn ct-btn-back">
                        Volver
                    </a>
                </div>
            </form>

        </div>
    </div>

@endsection

@push('styles')
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
    <link rel="stylesheet" href="https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.css">
@endpush

@push('scripts')
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.js"></script>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const mapEl = document.getElementById('map');
            if (!mapEl) return;

            // Centro aproximado de Colcapirhua
            const map = L.map('map').setView([-17.391, -66.237], 14);

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap'
            }).addTo(map);

            const drawnItems = new L.FeatureGroup();
            map.addLayer(drawnItems);

            const drawControl = new L.Control.Draw({
                edit: {
                    featureGroup: drawnItems,
                    remove: true
                },
                draw: {
                    polygon: false,
                    rectangle: false,
                    circle: false,
                    circlemarker: false,
                    marker: false,
                    polyline: true
                }
            });
            map.addControl(drawControl);

            function updateGeojson() {
                const geojson = drawnItems.toGeoJSON();
                document.getElementById('geojson').value =
                    geojson.features && geojson.features.length ? JSON.stringify(geojson) : '';
            }

            // ✅ Precargar desde tu API pública (GeoJSON por idtrufi)
  async function precargarRuta() {
    const idtrufi = @json($idtrufi);
    const baseUrl = @json(url('/'));

    // ✅ Endpoint real que te funciona
    const url = `${baseUrl}/api/trufis/${idtrufi}/rutas/geojson`;

    try {
        const res = await fetch(url, { headers: { 'Accept': 'application/json' } });

        if (!res.ok) {
            alert(`No Se Pudo Precargar La Ruta.\nEndpoint: ${url}\nHTTP: ${res.status}`);
            return;
        }

        const geojson = await res.json();

        if (!geojson || geojson.type !== 'FeatureCollection') {
            alert('La Respuesta No Es Un GeoJSON FeatureCollection Válido.');
            return;
        }

        if (!geojson.features || geojson.features.length === 0) {
            alert('No Hay Ruta Registrada Para Este Trufi (GeoJSON Vacío).');
            return;
        }

        drawnItems.clearLayers();

        const layer = L.geoJSON(geojson, {
            onEachFeature: (feature, lyr) => drawnItems.addLayer(lyr)
        });

        if (drawnItems.getLayers().length > 0) {
            map.fitBounds(layer.getBounds());
            updateGeojson();
        }
    } catch (e) {
        alert('Error Al Intentar Precargar La Ruta.');
        console.error(e);
    }
}


            // Solo 1 ruta a la vez
            map.on(L.Draw.Event.CREATED, function (e) {
                drawnItems.clearLayers();
                drawnItems.addLayer(e.layer);
                updateGeojson();
            });

            map.on(L.Draw.Event.EDITED, function () {
                updateGeojson();
            });

            map.on(L.Draw.Event.DELETED, function () {
                updateGeojson();
            });

            // Validación antes de enviar
            document.querySelector('form').addEventListener('submit', function (ev) {
                if (!document.getElementById('geojson').value) {
                    ev.preventDefault();
                    alert('Debes dibujar una ruta antes de guardar.');
                }
            });

            // Cargar al iniciar
            precargarRuta();
        });
    </script>
@endpush
