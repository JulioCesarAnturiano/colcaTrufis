@extends('admin.layout')

@section('title', 'Editar Ruta')

@section('content')
    <h2 class="mb-3">Editar Ruta</h2>

    <div class="alert alert-warning">
        Esta acción reemplazará la ruta anterior. Dibuja una nueva ruta desde cero y guarda.
    </div>

    <form action="{{ route('admin.rutas.actualizar', ['idtrufi' => $idtrufi]) }}" method="POST">
        @csrf
        @method('PUT')

        <div class="row">
            <div class="col-md-6 mb-3">
                <label class="form-label">Trufi</label>
                <select name="idtrufi" class="form-select" disabled>
                    @foreach($trufis as $t)
                        <option value="{{ $t->idtrufi }}" @selected((int)$t->idtrufi === (int)$idtrufi)>
                            {{ $t->idtrufi }} - {{ $t->nom_linea }}
                        </option>
                    @endforeach
                </select>
                <div class="form-text">
                    No se puede cambiar el trufi al editar. Si quieres otro, crea una ruta nueva.
                </div>
            </div>
        </div>

        <input type="hidden" name="geojson" id="geojson">

        <div class="alert alert-info">
            Dibuja la ruta en el mapa. Usa la herramienta de línea y agrega puntos. Luego guarda.
        </div>

        <div id="map" style="height: 500px; width: 100%; border: 1px solid #ddd;"></div>

        <div class="d-flex gap-2 mt-3">
            <button class="btn btn-primary">Reemplazar Ruta</button>
            <a href="{{ route('admin.rutas.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>

    {{-- Leaflet + Draw --}}
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
    <link rel="stylesheet" href="https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.css">

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

        // Solo 1 ruta a la vez (si dibuja otra, se reemplaza en el mapa)
        map.on(L.Draw.Event.CREATED, function (e) {
            drawnItems.clearLayers();
            drawnItems.addLayer(e.layer);

            const geojson = drawnItems.toGeoJSON();
            document.getElementById('geojson').value = JSON.stringify(geojson);
        });

        // Si edita la línea, actualizar geojson
        map.on(L.Draw.Event.EDITED, function () {
            const geojson = drawnItems.toGeoJSON();
            document.getElementById('geojson').value = JSON.stringify(geojson);
        });

        // Si borra, vaciar geojson
        map.on(L.Draw.Event.DELETED, function () {
            document.getElementById('geojson').value = '';
        });

        // Validación simple antes de enviar
        document.querySelector('form').addEventListener('submit', function (ev) {
            if (!document.getElementById('geojson').value) {
                ev.preventDefault();
                alert('Debes dibujar una ruta antes de guardar.');
            }
        });
    </script>
@endsection
