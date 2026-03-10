<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class GeocodingService
{
    public function reverse(float $lat, float $lng): ?array
    {
        // Cache Para No Llamar Mil Veces Al Mismo Punto.
        $key = 'revgeo:' . round($lat, 5) . ':' . round($lng, 5);

        return Cache::remember($key, now()->addHours(1), function () use ($lat, $lng) {

            $res = Http::timeout(10)
                ->withHeaders([
                    // Nominatim Pide Un User-Agent Identificable.
                    'User-Agent' => config('app.name', 'ColcaTrufis') . '/1.0',
                    'Accept' => 'application/json',
                ])
                ->get('https://nominatim.openstreetmap.org/reverse', [
                    'format' => 'jsonv2',
                    'lat' => $lat,
                    'lon' => $lng,
                    'zoom' => 18,
                    'addressdetails' => 1,
                ]);

            if (!$res->ok()) return null;

            $data = $res->json();

            $addr = $data['address'] ?? [];

            // Buscar ubicación en orden de prioridad
            // Incluye más opciones para ciudades pequeñas y zonas
            $road =
                $addr['road'] ??
                $addr['street'] ??
                $addr['residential'] ??
                $addr['pedestrian'] ??
                $addr['footway'] ??
                $addr['path'] ??
                $addr['cycleway'] ??
                $addr['highway'] ??
                $addr['neighbourhood'] ??
                $addr['suburb'] ??
                $addr['quarter'] ??
                null;

            if (!$road) return null;

            // Buscar calle transversal (intersección)
            $interseccion = null;
            
            // Intentar extraer una segunda calle de la dirección
            $posiblesIntersecciones = [];
            foreach ($addr as $key => $value) {
                if (in_array($key, ['street', 'residential', 'highway', 'pedestrian', 'footway']) && $value !== $road) {
                    $posiblesIntersecciones[] = $value;
                    break;
                }
            }
            
            if (!empty($posiblesIntersecciones)) {
                $interseccion = $posiblesIntersecciones[0];
            } else if (isset($addr['house_number'])) {
                // Si no hay intersección, usar el número de casa como referencia
                $interseccion = 'N° ' . $addr['house_number'];
            }

            return [
                'nombre_via' => $road,
                'interseccion' => $interseccion,
                'tipo_via' => null,
                'latitud' => (float) ($data['lat'] ?? $lat),
                'longitud' => (float) ($data['lon'] ?? $lng),
                'meta' => $data,
            ];
        });
    }

    public function buildUbicacionesFromCoords(array $coords, int $sampleEvery = 2): array
    {
        $ubicaciones = [];

        $total = count($coords);
        if ($total === 0) return [];

        for ($i = 0; $i < $total; $i++) {
            $isSample = ($i % $sampleEvery === 0) || ($i === $total - 1);
            if (!$isSample) continue;

            // GeoJSON: [lng, lat]
            $lng = (float) $coords[$i][0];
            $lat = (float) $coords[$i][1];

            $info = $this->reverse($lat, $lng);
            if (!$info) continue;

            $nombre = trim((string) $info['nombre_via']);
            if ($nombre === '') continue;

            // Agregar todas las ubicaciones sin filtrado de duplicados
            $ubicaciones[] = $info;

            // Pequeña Pausa Para Evitar Rate Limit En Rutas Largas.
            usleep(50000); // 50ms
        }

        return $ubicaciones;
    }
}