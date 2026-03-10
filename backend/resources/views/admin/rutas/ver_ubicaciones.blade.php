@extends('admin.layout')

@section('title', 'Ver Ubicaciones - Ruta')

@section('content')

<div class="ct-header mb-4 d-flex justify-content-between align-items-center">
    <div>
        <h2 class="ct-title">Ubicaciones De La Ruta</h2>
        <div class="ct-subtitle">
            {{ $trufi->nom_linea }} - ID: {{ $idtrufi }}
        </div>
    </div>
    <a href="{{ route('admin.rutas.index') }}" class="btn ct-btn ct-btn-back">
        Volver
    </a>
</div>

<div class="row g-4">
    <div class="col-lg-8">
        <!-- Mapa -->
        <div class="card ct-stat-card" style="height: 600px;">
            <div class="card-body p-0">
                <div id="mapContainer" style="height: 100%; border-radius: 0.5rem;"></div>
            </div>
        </div>
    </div>

    <div class="col-lg-4">
        <!-- Listado de Ubicaciones -->
        <div class="card ct-stat-card">
            <div class="card-header bg-light">
                <h5 class="mb-0">Calles Por Donde Pasa ({{ count($ubicaciones) }})</h5>
            </div>
            <div class="card-body p-0" style="max-height: 600px; overflow-y: auto;">
                @if(count($ubicaciones) > 0)
                    <div class="list-group list-group-flush">
                        @foreach($ubicaciones as $index => $u)
                            <div class="list-group-item">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <span class="badge bg-primary rounded-pill me-2">{{ $u->orden }}</span>
                                        <strong>{{ $u->nombre_via }}</strong>
                                        @if($u->interseccion)
                                            <br>
                                            <small class="text-muted">📍 {{ $u->interseccion }}</small>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                @else
                    <div class="p-3 text-center text-muted">
                        <small>No hay ubicaciones registradas</small>
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>

<!-- Leaflet CSS -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css" />
<!-- Leaflet JS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>

<script>
document.addEventListener('DOMContentLoaded', function() {
    // Datos de la ruta
    const puntosGeoJSON = @json($puntos ?? []);
    
    // Inicializar mapa con centro en el primer punto
    const mapContainer = document.getElementById('mapContainer');
    let map;
    
    if (puntosGeoJSON && puntosGeoJSON.length > 0) {
        const centerLat = puntosGeoJSON[0][1];
        const centerLng = puntosGeoJSON[0][0];
        
        map = L.map(mapContainer).setView([centerLat, centerLng], 13);
        
        // OpenStreetMap tiles
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 19,
        }).addTo(map);
        
        // Dibujar la ruta
        const latLngs = puntosGeoJSON.map(coord => [coord[1], coord[0]]);
        const polyline = L.polyline(latLngs, {
            color: '#0066cc',
            weight: 4,
            opacity: 0.8,
            lineCap: 'round',
            lineJoin: 'round'
        }).addTo(map);
        
        // Marcadores de inicio y fin
        if (puntosGeoJSON.length > 0) {
            // Inicio
            L.circleMarker([puntosGeoJSON[0][1], puntosGeoJSON[0][0]], {
                radius: 8,
                fillColor: '#28a745',
                color: '#fff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            }).bindPopup('<strong>Inicio</strong>').addTo(map);
            
            // Fin
            const last = puntosGeoJSON[puntosGeoJSON.length - 1];
            L.circleMarker([last[1], last[0]], {
                radius: 8,
                fillColor: '#dc3545',
                color: '#fff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            }).bindPopup('<strong>Fin</strong>').addTo(map);
        }
        
        // Muestrear puntos cada 5 para no sobrecargar el mapa
        const ubicacionesMeta = @json($ubicaciones->pluck('meta') ?? []);
        if (ubicacionesMeta && ubicacionesMeta.length > 0) {
            ubicacionesMeta.forEach((meta, index) => {
                if (meta && meta.lat && meta.lon) {
                    const icon = L.icon({
                        iconUrl: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJjMCA0IDMuNjUgNy4zNyA4Ljc2IDcuOTZWMjJoMi40OHY02MDAwSDEyLjc2di00LjA0QzE2LjM1IDE3LjM3IDIwIDEzIDIwIDEyYzAtNS41Mi00LjQ4LTEwLTEwLTEweiIgZmlsbD0iIzAwNjZjYyIvPjwvc3ZnPg==',
                        iconSize: [24, 24],
                        iconAnchor: [12, 24],
                        popupAnchor: [0, -24]
                    });
                    
                    L.marker([meta.lat, meta.lon], { icon: icon })
                        .bindPopup(`<strong>${index + 1}</strong>`)
                        .addTo(map);
                }
            });
        }
        
        // Ajustar zoom a la ruta
        map.fitBounds(polyline.getBounds());
    } else {
        mapContainer.innerHTML = '<div class="d-flex align-items-center justify-content-center h-100"><p class="text-muted">No hay datos de ruta para mostrar</p></div>';
    }
});
</script>

@endsection
