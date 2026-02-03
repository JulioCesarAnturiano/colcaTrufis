@extends('admin.layout')

@section('title', 'Crear Ruta')

@section('content')
    <h2 class="mb-3">Crear Ruta</h2>

    <form action="{{ route('admin.rutas.guardar') }}" method="POST">
        @csrf

        <div class="mb-3">
            <label class="form-label">Trufi</label>
            <select name="idtrufi" class="form-select" required>
                <option value="">Seleccione un trufi</option>
                @foreach($trufis as $t)
                    <option value="{{ $t->idtrufi }}">{{ $t->nom_linea }}</option>
                @endforeach
            </select>
        </div>

        <div class="alert alert-info">
            Dibuja la ruta en el mapa. Usa la herramienta de línea y agrega puntos. Luego guarda.
        </div>

        <div id="map" style="height: 520px; border-radius: 8px;"></div>

        {{-- Aquí se guardará el GeoJSON de la línea --}}
        <input type="hidden" name="geojson" id="geojson" required>

        <div class="d-flex gap-2 mt-3">
            <button class="btn btn-success">Guardar</button>
            <a href="{{ route('admin.rutas.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>
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
