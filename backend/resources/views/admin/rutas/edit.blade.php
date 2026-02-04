@extends('admin.layout')

@section('title', 'Editar Ruta')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Editar Ruta</h2>
        <div class="ct-subtitle">
            Reemplazo De Ruta Existente. Dibuja Una Nueva Ruta Desde Cero Y Guarda.
        </div>
    </div>

    <div class="alert alert-warning">
        Esta Acción Reemplazará La Ruta Anterior. Dibuja Una Nueva Ruta Desde Cero Y Guarda.
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

                <input type="hidden" name="geojson" id="geojson">

                <div class="alert alert-info">
                    Dibuja La Ruta En El Mapa. Usa La Herramienta De Línea Y Agrega Puntos. Luego Guarda.
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
            document.getElementById('geojson').value = geojson.features?.length ? JSON.stringify(geojson) : '';
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

        // Validación simple antes de enviar
        document.querySelector('form').addEventListener('submit', function (ev) {
            if (!document.getElementById('geojson').value) {
                ev.preventDefault();
                alert('Debes dibujar una ruta antes de guardar.');
            }
        });
    </script>
@endpush
