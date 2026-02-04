@extends('admin.layout')

@section('title', 'Crear Ruta')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Crear Ruta</h2>
        <div class="ct-subtitle">
            Dibuja La Ruta En El Mapa Y Guárdala Asociada A Un Trufi En ColcaTrufis
        </div>
    </div>

    {{-- Formulario --}}
    <div class="card ct-stat-card">
        <div class="card-body">

            <form action="{{ route('admin.rutas.guardar') }}" method="POST">
                @csrf

                <div class="row">
                    <div class="col-12 col-md-6 mb-3">
                        <label class="form-label fw-semibold">Trufi</label>
                        <select name="idtrufi" class="form-select" required>
                            <option value="">Seleccione Un Trufi</option>
                            @foreach($trufis as $t)
                                <option value="{{ $t->idtrufi }}">
                                    {{ $t->nom_linea }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <div class="alert alert-info">
                    Dibuja La Ruta En El Mapa. Usa La Herramienta De Línea Y Agrega Puntos. Luego Guarda.
                </div>

                <div id="map" class="ct-map"></div>

                {{-- Aquí se guardará el GeoJSON de la línea --}}
                <input type="hidden" name="geojson" id="geojson" required>

                {{-- Acciones --}}
                <div class="d-flex gap-2 mt-3">
                    <button type="submit" class="btn ct-btn ct-btn-save">
                        Guardar
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
        // 1) Centro aproximado de Colcapirhua (ajustable)
        const map = L.map('map').setView([-17.389, -66.247], 14);

        // 2) Mapa base (OpenStreetMap)
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap'
        }).addTo(map);

        // 3) Capa donde se guardan los dibujos
        const drawnItems = new L.FeatureGroup();
        map.addLayer(drawnItems);

        // 4) Controles de dibujo: permitimos SOLO Polyline (ruta)
        const drawControl = new L.Control.Draw({
            edit: {
                featureGroup: drawnItems
            },
            draw: {
                polygon: false,
                rectangle: false,
                circle: false,
                circlemarker: false,
                marker: false,
                polyline: {
                    shapeOptions: { }
                }
            }
        });
        map.addControl(drawControl);

        function updateGeojsonInput() {
            const data = drawnItems.toGeoJSON();

            // Debe existir 1 sola línea (1 Feature)
            if (!data.features || data.features.length === 0) {
                document.getElementById('geojson').value = '';
                return;
            }

            // Guardamos el GeoJSON completo
            document.getElementById('geojson').value = JSON.stringify(data);
        }

        map.on(L.Draw.Event.CREATED, function (event) {
            drawnItems.clearLayers(); // solo 1 ruta a la vez
            drawnItems.addLayer(event.layer);
            updateGeojsonInput();
        });

        map.on(L.Draw.Event.EDITED, function () {
            updateGeojsonInput();
        });

        map.on(L.Draw.Event.DELETED, function () {
            updateGeojsonInput();
        });

        // Validación antes de enviar
        document.querySelector('form').addEventListener('submit', function (e) {
            if (!document.getElementById('geojson').value) {
                e.preventDefault();
                alert('Debes dibujar una ruta (línea) en el mapa antes de guardar.');
            }
        });
    </script>
@endpush
