@extends('admin.layout')

@section('title', 'Crear RadioTaxi')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Crear RadioTaxi</h2>
        <div class="ct-subtitle">
            Registro De Nuevo RadioTaxi En El Sistema ColcaTrufis
        </div>
    </div>

    {{-- Formulario --}}
    <div class="card ct-stat-card">
        <div class="card-body">

            <form action="{{ route('admin.radiotaxis.guardar') }}" method="POST">
                @csrf

                <div class="row">

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Nombre Comercial</label>
                        <input
                            type="text"
                            name="nombre_comercial"
                            class="form-control"
                            required
                            value="{{ old('nombre_comercial') }}"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Teléfono Base</label>
                        <input
                            type="text"
                            name="telefono_base"
                            class="form-control"
                            required
                            value="{{ old('telefono_base') }}"
                        >
                    </div>

                    <div class="col-md-12 mb-3">
                        <label class="form-label fw-semibold">Dirección</label>
                        <input
                            type="text"
                            name="direccion"
                            class="form-control"
                            placeholder="Ej: Av. Principal #123, entre calles..."
                            value="{{ old('direccion') }}"
                        >
                        <small class="text-muted">Dirección de la ubicación del radiotaxi</small>
                    </div>

                </div>

                <div class="alert alert-info">
                    Selecciona La Parada En El Mapa. Solo Se Permitirá Un Punto.
                </div>

                <div id="map" class="ct-map"></div>

                {{-- Coordenadas de la parada --}}
                <input type="hidden" name="latitud" id="latitud" value="{{ old('latitud') }}">
                <input type="hidden" name="longitud" id="longitud" value="{{ old('longitud') }}">

                {{-- Acciones --}}
                <div class="d-flex gap-2 mt-3">
                    <button type="submit" class="btn ct-btn ct-btn-save">
                        Guardar
                    </button>

                    <a href="{{ route('admin.radiotaxis.index') }}" class="btn ct-btn ct-btn-back">
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
        // Centro aproximado (ajustable)
        const map = L.map('map').setView([-17.389, -66.247], 14);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap'
        }).addTo(map);

        let marker = null;

        function setPoint(lat, lng) {
            // Coloca o mueve el marcador
            if (marker) {
                marker.setLatLng([lat, lng]);
            } else {
                marker = L.marker([lat, lng], { draggable: true }).addTo(map);

                // Si lo arrastran, actualiza inputs
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

        // Click en el mapa = elegir la parada (1 solo punto)
        map.on('click', function (e) {
            setPoint(e.latlng.lat, e.latlng.lng);
        });

        // Si venimos con old() (cuando hay error de validación), reponer marcador
        const oldLat = document.getElementById('latitud').value;
        const oldLng = document.getElementById('longitud').value;
        if (oldLat && oldLng) {
            setPoint(parseFloat(oldLat), parseFloat(oldLng));
            map.setView([parseFloat(oldLat), parseFloat(oldLng)], 16);
        }

        // Validación antes de enviar
        document.querySelector('form').addEventListener('submit', function (e) {
            if (!document.getElementById('latitud').value || !document.getElementById('longitud').value) {
                e.preventDefault();
                alert('Debes seleccionar un punto en el mapa antes de guardar.');
            }
        });
    </script>
@endpush
