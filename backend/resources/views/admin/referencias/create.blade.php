@extends('admin.layout')

@section('title', 'Crear Referencias')

@section('content')
<div class="container-fluid">
    <div class="d-flex align-items-center justify-content-between mb-3">
        <h4 class="mb-0">Crear Referencia</h4>
        <a href="{{ route('admin.referencias') }}" class="btn btn-secondary">Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger">
            <strong>Revisa los campos:</strong>
            <ul class="mb-0">
                @foreach ($errors->all() as $e)
                    <li>{{ $e }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="card">
        <div class="card-body">
            <form action="{{ route('admin.referencias.guardar') }}" method="POST" id="refForm">
                @csrf

                <div class="mb-3">
                    <label class="form-label">Referencia</label>
                    <input type="text"
                           name="referencia"
                           class="form-control"
                           value="{{ old('referencia') }}"
                           required>
                </div>

                <div class="mb-3">
                    <label class="form-label">Asignar A</label>

                    <div class="d-flex gap-3 mb-2">
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="tipo" id="tipoTaxi" value="taxi"
                                   {{ old('tipo', 'taxi') === 'taxi' ? 'checked' : '' }}>
                            <label class="form-check-label" for="tipoTaxi">RadioTaxi</label>
                        </div>

                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="tipo" id="tipoTrufi" value="trufi"
                                   {{ old('tipo') === 'trufi' ? 'checked' : '' }}>
                            <label class="form-check-label" for="tipoTrufi">Trufi</label>
                        </div>
                    </div>

                    <div class="mb-2" id="taxiSelectWrap">
                        <label class="form-label">Selecciona Un RadioTaxi</label>
                        <select class="form-select" id="taxiSelect" name="taxi_id">
                            <option value="">-- Selecciona --</option>
                            @foreach($taxis as $t)
                                <option value="{{ $t->id }}" @selected(old('taxi_id') == $t->id)>
                                    {{ $t->nombre_comercial ?? ('RadioTaxi #' . $t->id) }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="mb-2 d-none" id="trufiSelectWrap">
                        <label class="form-label">Selecciona Un Trufi</label>
                        <select class="form-select" id="trufiSelect" name="trufi_id">
                            <option value="">-- Selecciona --</option>
                            @foreach($trufis as $tr)
                                <option value="{{ $tr->idtrufi }}" @selected(old('trufi_id') == $tr->idtrufi)>
                                    {{ $tr->nom_linea ?? ('Trufi #' . $tr->idtrufi) }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    {{-- Campos Polimórficos Reales --}}
                    <input type="hidden" name="referenciable_type" id="referenciableType" value="">
                    <input type="hidden" name="referenciable_id" id="referenciableId" value="">
                    <small class="text-muted">Debes seleccionar un RadioTaxi o un Trufi para guardar.</small>
                </div>

                <!-- Mapa para Seleccionar Ubicación -->
                <div class="mb-3">
                    <label class="form-label">📍 Ubicación (Haz click en el mapa para marcar)</label>
                    <div id="mapContainerRef" style="height: 400px; border: 1px solid #ddd; border-radius: 0.5rem; margin-bottom: 10px;"></div>
                    <div class="row">
                        <div class="col-md-6">
                            <label>Latitud</label>
                            <input type="number" step="0.00000001" name="latitud" id="latitudInput" class="form-control" placeholder="Latitud">
                        </div>
                        <div class="col-md-6">
                            <label>Longitud</label>
                            <input type="number" step="0.00000001" name="longitud" id="longitudInput" class="form-control" placeholder="Longitud">
                        </div>
                    </div>
                </div>

                <button class="btn btn-primary" type="submit">Guardar</button>
            </form>
        </div>
    </div>
</div>

<!-- Leaflet CSS -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css" />
<!-- Leaflet JS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>

<script>
(function () {
    // IMPORTANTE: Enviar El FQCN Con Backslashes Correctos
    const taxiClass  = "App\\\\Models\\\\Sindicatoradiotaxi";
    const trufiClass = "App\\\\Models\\\\Trufi";

    const tipoTaxi  = document.getElementById('tipoTaxi');
    const tipoTrufi = document.getElementById('tipoTrufi');

    const taxiWrap  = document.getElementById('taxiSelectWrap');
    const trufiWrap = document.getElementById('trufiSelectWrap');

    const taxiSelect  = document.getElementById('taxiSelect');
    const trufiSelect = document.getElementById('trufiSelect');

    const refType = document.getElementById('referenciableType');
    const refId   = document.getElementById('referenciableId');

    function sync() {
        if (tipoTaxi.checked) {
            taxiWrap.classList.remove('d-none');
            trufiWrap.classList.add('d-none');

            refType.value = taxiClass;
            refId.value   = taxiSelect.value || '';

            // Limpia El Otro Select
            trufiSelect.value = '';
        } else {
            trufiWrap.classList.remove('d-none');
            taxiWrap.classList.add('d-none');

            refType.value = trufiClass;
            refId.value   = trufiSelect.value || '';

            taxiSelect.value = '';
        }
    }

    tipoTaxi.addEventListener('change', sync);
    tipoTrufi.addEventListener('change', sync);
    taxiSelect.addEventListener('change', sync);
    trufiSelect.addEventListener('change', sync);

    document.getElementById('refForm').addEventListener('submit', function (e) {
        sync();
        if (!refType.value || !refId.value) {
            e.preventDefault();
            alert('Debes Seleccionar Un RadioTaxi O Un Trufi Antes De Guardar.');
        }
    });

    sync();
})();

// Inicializar Mapa
document.addEventListener('DOMContentLoaded', function() {
    const defaultLat = -17.3895; // Cochabamba
    const defaultLng = -66.1577;
    const mapContainer = document.getElementById('mapContainerRef');
    
    if (!mapContainer) return;
    
    const map = L.map(mapContainer).setView([defaultLat, defaultLng], 13);
    
    // OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19,
    }).addTo(map);
    
    let marker = null;
    
    // Click en mapa para marcar ubicación
    map.on('click', function(e) {
        const lat = e.latlng.lat;
        const lng = e.latlng.lng;
        
        // Actualizar inputs
        document.getElementById('latitudInput').value = lat.toFixed(8);
        document.getElementById('longitudInput').value = lng.toFixed(8);
        
        // Actualizar o crear marcador
        if (marker) {
            marker.setLatLng([lat, lng]);
        } else {
            marker = L.marker([lat, lng]).addTo(map);
        }
        
        marker.bindPopup(`<b>Ubicación seleccionada</b><br>Lat: ${lat.toFixed(8)}<br>Lng: ${lng.toFixed(8)}`).openPopup();
    });
    
    // Cargar marcador si hay valores previos
    const latInput = document.getElementById('latitudInput');
    const lngInput = document.getElementById('longitudInput');
    
    if (latInput.value && lngInput.value) {
        const lat = parseFloat(latInput.value);
        const lng = parseFloat(lngInput.value);
        marker = L.marker([lat, lng]).addTo(map);
        map.setView([lat, lng], 15);
    }
    
    // Actualizar mapa cuando cambien los inputs
    latInput.addEventListener('change', function() {
        const lat = parseFloat(this.value);
        const lng = parseFloat(lngInput.value);
        if (lat && lng) {
            if (marker) {
                marker.setLatLng([lat, lng]);
            } else {
                marker = L.marker([lat, lng]).addTo(map);
            }
            map.setView([lat, lng], 15);
        }
    });
    
    lngInput.addEventListener('change', function() {
        const lat = parseFloat(latInput.value);
        const lng = parseFloat(this.value);
        if (lat && lng) {
            if (marker) {
                marker.setLatLng([lat, lng]);
            } else {
                marker = L.marker([lat, lng]).addTo(map);
            }
            map.setView([lat, lng], 15);
        }
    });
});
</script>
@endsection