@extends('admin.layout')

@section('title', 'Editar RadioTaxi')

@section('content')

<div class="ct-header mb-4">
    <h2 class="ct-title">Editar RadioTaxi</h2>
    <div class="ct-subtitle">
        Modificación De Datos Y Parada
    </div>
</div>

<div class="card ct-stat-card">
    <div class="card-body">

        <form action="{{ route('admin.radiotaxis.actualizar', $radiotaxi->id) }}"
              method="POST">
            @csrf
            @method('PUT')

            <div class="row">

                <div class="col-md-6 mb-3">
                    <label class="form-label fw-semibold">Nombre Comercial</label>
                    <input type="text"
                           name="nombre_comercial"
                           class="form-control"
                           required
                           value="{{ old('nombre_comercial', $radiotaxi->nombre_comercial) }}">
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label fw-semibold">Teléfono Base</label>
                    <input type="text"
                           name="telefono_base"
                           class="form-control"
                           required
                           value="{{ old('telefono_base', $radiotaxi->telefono_base) }}">
                </div>

                <div class="col-md-12 mb-3">
                    <label class="form-label fw-semibold">Dirección</label>
                    <input type="text"
                           name="direccion"
                           class="form-control"
                           placeholder="Ej: Av. Principal #123, entre calles..."
                           value="{{ old('direccion', optional($radiotaxi->parada)->direccion) }}">
                    <small class="text-muted">Dirección de la ubicación del radiotaxi</small>
                </div>

            </div>

            <div class="alert alert-info">
                Puedes mover la parada en el mapa.
            </div>

            <div id="map" class="ct-map"></div>

            <input type="hidden" name="latitud" id="latitud"
                   value="{{ old('latitud', optional($radiotaxi->parada)->latitud) }}">

            <input type="hidden" name="longitud" id="longitud"
                   value="{{ old('longitud', optional($radiotaxi->parada)->longitud) }}">

            <div class="d-flex gap-2 mt-3">
                <button type="submit" class="btn ct-btn ct-btn-save">
                    Actualizar
                </button>

                <a href="{{ route('admin.radiotaxis.index') }}"
                   class="btn ct-btn ct-btn-back">
                    Volver
                </a>
            </div>

        </form>

    </div>
</div>

@endsection

@push('styles')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
@endpush

@push('scripts')
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

<script>
    const map = L.map('map').setView([-17.389, -66.247], 14);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap'
    }).addTo(map);

    let marker = null;

    function setPoint(lat, lng) {
        if (marker) {
            marker.setLatLng([lat, lng]);
        } else {
            marker = L.marker([lat, lng], { draggable: true }).addTo(map);

            marker.on('dragend', () => {
                const p = marker.getLatLng();
                updateInputs(p.lat, p.lng);
            });
        }
        updateInputs(lat, lng);
    }

    function updateInputs(lat, lng) {
        document.getElementById('latitud').value = lat.toFixed(7);
        document.getElementById('longitud').value = lng.toFixed(7);
    }

    map.on('click', function (e) {
        setPoint(e.latlng.lat, e.latlng.lng);
    });

    const lat = document.getElementById('latitud').value;
    const lng = document.getElementById('longitud').value;

    if (lat && lng) {
        setPoint(parseFloat(lat), parseFloat(lng));
        map.setView([parseFloat(lat), parseFloat(lng)], 16);
    }

    document.querySelector('form').addEventListener('submit', function (e) {
        if (!document.getElementById('latitud').value) {
            e.preventDefault();
            alert('Debes seleccionar un punto en el mapa.');
        }
    });
</script>
@endpush
